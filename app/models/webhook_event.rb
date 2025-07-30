class WebhookEvent < ApplicationRecord
  # Associations
  belongs_to :store

  # Validations
  validates :event_type, presence: true
  validates :payload, presence: true

  # Scopes
  scope :recent, -> { order(created_at: :desc) }
  scope :by_type, ->(type) { where(event_type: type) }
  scope :unprocessed, -> { where(processed: false) }
  scope :processed, -> { where(processed: true) }

  # Callbacks
  after_create :process_webhook

  # Instance methods
  def process_webhook
    return if processed?

    # Process based on event type
    case event_type
    when 'order.created', 'order.updated'
      process_order_event
    when 'refund.created'
      process_refund_event
    when 'payment_intent.payment_failed'
      process_payment_failure_event
    when 'fulfillment.created'
      process_fulfillment_event
    end

    mark_processed!
  end

  def mark_processed!
    update!(processed: true, processed_at: Time.current)
  end

  def check_alert_rules
    store.alert_rules.enabled.each do |rule|
      next unless rule.check_conditions(store.webhook_events)

      create_alert_from_rule(rule)
    end
  end

  private

  def process_order_event
    # Extract order data and store in metadata
    order_data = {
      order_id: payload['id'],
      customer_email: payload.dig('customer', 'email'),
      total_price: payload['total_price'],
      currency: payload['currency'],
      created_at: payload['created_at']
    }

    update!(metadata: metadata.merge(order_data))
  end

  def process_refund_event
    # Extract refund data
    refund_data = {
      refund_id: payload['id'],
      order_id: payload['order_id'],
      amount: payload['amount'],
      reason: payload['reason']
    }

    update!(metadata: metadata.merge(refund_data))
  end

  def process_payment_failure_event
    # Extract payment failure data
    failure_data = {
      payment_intent_id: payload['id'],
      amount: payload['amount'],
      failure_reason: payload.dig('last_payment_error', 'message'),
      customer_email: payload.dig('customer', 'email')
    }

    update!(metadata: metadata.merge(failure_data))
  end

  def process_fulfillment_event
    # Extract fulfillment data
    fulfillment_data = {
      fulfillment_id: payload['id'],
      order_id: payload['order_id'],
      status: payload['status'],
      tracking_number: payload['tracking_number']
    }

    update!(metadata: metadata.merge(fulfillment_data))
  end

  def create_alert_from_rule(rule)
    alert_attributes = case rule.rule_type
                       when 'refund_spike'
                         {
                           title: 'Refund Spike Detected',
                           description: "Refund rate has exceeded #{rule.conditions['threshold'] * 100}% in the last 24 hours",
                           severity: :high,
                           metadata: {
                             refund_count: store.webhook_events.where(event_type: 'refund.created').where('created_at > ?',
                                                                                                          24.hours.ago).count,
                             total_orders: store.webhook_events.where(event_type: 'order.created').where('created_at > ?',
                                                                                                         24.hours.ago).count,
                             refund_rate: calculate_refund_rate
                           }
                         }
                       when 'payment_failure_streak'
                         {
                           title: 'Payment Failure Streak',
                           description: 'Multiple consecutive payment failures detected',
                           severity: :critical,
                           metadata: {
                             failure_count: store.webhook_events.where(event_type: 'payment_intent.payment_failed').where(
                               'created_at > ?', 1.hour.ago
                             ).count,
                             customer_email: payload.dig('customer', 'email')
                           }
                         }
                       when 'unfulfilled_72h'
                         {
                           title: 'Unfulfilled Order > 72h',
                           description: 'Order has been unfulfilled for over 72 hours',
                           severity: :medium,
                           metadata: {
                             order_id: payload['id'],
                             order_value: payload['total_price'],
                             days_unfulfilled: ((Time.current - Time.zone.parse(payload['created_at'])) / 1.day).round
                           }
                         }
                       end

    store.alerts.create!(
      rule_type: rule.rule_type,
      **alert_attributes
    )

    rule.update!(last_triggered_at: Time.current)
  end

  def calculate_refund_rate
    refunds = store.webhook_events.where(event_type: 'refund.created').where('created_at > ?', 24.hours.ago).count
    orders = store.webhook_events.where(event_type: 'order.created').where('created_at > ?', 24.hours.ago).count

    return 0 if orders.zero?

    (refunds.to_f / orders) * 100
  end
end
