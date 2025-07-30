class Alert < ApplicationRecord
  # Associations
  belongs_to :store
  belongs_to :resolved_by, class_name: 'User', optional: true
  has_many :alert_actions, dependent: :destroy

  # Validations
  validates :rule_type, presence: true
  validates :status, presence: true
  validates :severity, presence: true
  validates :title, presence: true

  # Enums
  enum :status, { active: 'active', resolved: 'resolved', dismissed: 'dismissed' }
  enum :severity, { low: 'low', medium: 'medium', high: 'high', critical: 'critical' }
  enum :rule_type, {
    refund_spike: 'refund_spike',
    payment_failure_streak: 'payment_failure_streak',
    unfulfilled_72h: 'unfulfilled_72h'
  }

  # Scopes
  scope :active, -> { where(status: :active) }
  scope :resolved, -> { where(status: :resolved) }
  scope :by_severity, ->(severity) { where(severity: severity) }
  scope :recent, -> { order(created_at: :desc) }

  # Callbacks
  before_create :set_defaults
  after_create :send_slack_notification

  # Instance methods
  def resolve!(user = nil)
    update!(
      status: :resolved,
      resolved_at: Time.current,
      resolved_by: user
    )
  end

  def dismiss!(user = nil)
    update!(
      status: :dismissed,
      resolved_at: Time.current,
      resolved_by: user
    )
  end

  def action_buttons
    case rule_type
    when 'refund_spike'
      [
        { text: 'Refresh Order', action: 'refresh_order', style: 'primary' },
        { text: 'Send Email', action: 'send_email', style: 'secondary' },
        { text: 'Mark Resolved', action: 'mark_resolved', style: 'danger' }
      ]
    when 'payment_failure_streak'
      [
        { text: 'Retry Payment', action: 'retry_payment', style: 'primary' },
        { text: 'Contact Customer', action: 'contact_customer', style: 'secondary' },
        { text: 'Mark Resolved', action: 'mark_resolved', style: 'danger' }
      ]
    when 'unfulfilled_72h'
      [
        { text: 'Update Fulfillment', action: 'update_fulfillment', style: 'primary' },
        { text: 'Contact Customer', action: 'contact_customer', style: 'secondary' },
        { text: 'Mark Resolved', action: 'mark_resolved', style: 'danger' }
      ]
    else
      [
        { text: 'Mark Resolved', action: 'mark_resolved', style: 'danger' }
      ]
    end
  end

  def calculate_savings
    case rule_type
    when 'refund_spike'
      # Calculate potential refund amount saved
      refund_amount = metadata&.dig('refund_amount') || 0
      update!(money_saved: refund_amount, time_saved: 30) # 30 minutes saved
    when 'payment_failure_streak'
      # Calculate potential revenue saved
      failed_amount = metadata&.dig('failed_amount') || 0
      update!(money_saved: failed_amount, time_saved: 45) # 45 minutes saved
    when 'unfulfilled_72h'
      # Calculate potential chargeback saved
      order_value = metadata&.dig('order_value') || 0
      update!(money_saved: order_value * 0.1, time_saved: 60) # 10% of order value, 1 hour saved
    end
  end

  def update_action_rate
    total_actions = alert_actions.count
    return if total_actions.zero?

    successful_actions = alert_actions.where(status: 'successful').count
    rate = (successful_actions.to_f / total_actions) * 100
    update!(action_rate: rate)
  end

  private

  def set_defaults
    self.status ||= :active
    self.severity ||= :medium
    self.action_rate ||= 0
  end

  def send_slack_notification
    return if store.slack_webhook_url.blank?

    SlackNotifierJob.perform_later(self)
  end
end
