class AlertRule < ApplicationRecord
  # Associations
  belongs_to :store
  has_many :alerts, dependent: :destroy

  # Validations
  validates :rule_type, presence: true
  validates :name, presence: true
  validates :enabled, inclusion: { in: [true, false] }

  # Enums
  enum :rule_type, {
    refund_spike: 'refund_spike',
    payment_failure_streak: 'payment_failure_streak',
    unfulfilled_72h: 'unfulfilled_72h'
  }

  # Scopes
  scope :enabled, -> { where(enabled: true) }
  scope :by_type, ->(type) { where(rule_type: type) }

  # Callbacks
  before_create :set_defaults

  # Class methods for creating default rules
  def self.create_default_rules(store)
    rules = [
      {
        rule_type: :refund_spike,
        name: 'Refund Spike Alert',
        description: 'Triggers when refund rate exceeds 5% in 24 hours',
        conditions: {
          threshold: 0.05,
          time_window: 24.hours,
          minimum_refunds: 3
        }
      },
      {
        rule_type: :payment_failure_streak,
        name: 'Payment Failure Streak',
        description: 'Triggers when 3+ consecutive payment failures occur',
        conditions: {
          consecutive_failures: 3,
          time_window: 1.hour
        }
      },
      {
        rule_type: :unfulfilled_72h,
        name: 'Unfulfilled Orders > 72h',
        description: 'Triggers when orders remain unfulfilled for over 72 hours',
        conditions: {
          hours_threshold: 72,
          minimum_value: 50.0
        }
      }
    ]

    rules.each do |rule_attrs|
      create!(rule_attrs.merge(store: store, enabled: true))
    end
  end

  # Instance methods
  def check_conditions(webhook_events)
    case rule_type
    when 'refund_spike'
      check_refund_spike(webhook_events)
    when 'payment_failure_streak'
      check_payment_failure_streak(webhook_events)
    when 'unfulfilled_72h'
      check_unfulfilled_orders(webhook_events)
    end
  end

  def should_disable?
    action_rate < 50.0 && last_triggered_at.present? && last_triggered_at < 7.days.ago
  end

  def disable_if_needed
    return unless should_disable?

    update!(enabled: false)
  end

  private

  def set_defaults
    self.enabled = true if enabled.nil?
    self.action_rate = 0 if action_rate.nil?
  end

  def check_refund_spike(webhook_events)
    recent_refunds = webhook_events
                     .where(event_type: 'refund.created')
                     .where('created_at > ?', conditions['time_window'].ago)

    return false if recent_refunds.count < conditions['minimum_refunds']

    total_orders = webhook_events
                   .where(event_type: 'order.created')
                   .where('created_at > ?', conditions['time_window'].ago)
                   .count

    return false if total_orders.zero?

    refund_rate = recent_refunds.count.to_f / total_orders
    refund_rate > conditions['threshold']
  end

  def check_payment_failure_streak(webhook_events)
    recent_failures = webhook_events
                      .where(event_type: 'payment_intent.payment_failed')
                      .where('created_at > ?', conditions['time_window'].ago)
                      .order(:created_at)

    return false if recent_failures.count < conditions['consecutive_failures']

    # Check for consecutive failures
    consecutive_count = 0
    recent_failures.each_cons(2) do |failure1, failure2|
      if (failure2.created_at - failure1.created_at) <= 5.minutes
        consecutive_count += 1
      else
        consecutive_count = 0
      end
    end

    consecutive_count >= conditions['consecutive_failures']
  end

  def check_unfulfilled_orders(webhook_events)
    old_orders = webhook_events
                 .where(event_type: 'order.created')
                 .where(created_at: ...conditions['hours_threshold'].ago)

    # Check if any of these orders haven't been fulfilled
    old_orders.any? do |order_event|
      order_id = order_event.payload['id']
      fulfillment_events = webhook_events
                           .where(event_type: 'fulfillment.created')
                           .where("payload->>'order_id' = ?", order_id.to_s)

      fulfillment_events.empty? &&
        order_event.payload['total_price'].to_f >= conditions['minimum_value']
    end
  end
end
