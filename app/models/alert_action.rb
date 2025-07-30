class AlertAction < ApplicationRecord
  # Associations
  belongs_to :alert

  # Validations
  validates :action_type, presence: true
  validates :status, presence: true

  # Enums
  enum :action_type, {
    refresh_order: 'refresh_order',
    send_email: 'send_email',
    mark_resolved: 'mark_resolved',
    retry_payment: 'retry_payment',
    contact_customer: 'contact_customer',
    update_fulfillment: 'update_fulfillment'
  }

  enum :status, {
    pending: 'pending',
    processing: 'processing',
    successful: 'successful',
    failed: 'failed'
  }

  # Scopes
  scope :recent, -> { order(created_at: :desc) }
  scope :successful, -> { where(status: :successful) }
  scope :failed, -> { where(status: :failed) }

  # Callbacks
  before_create :set_defaults
  after_create :execute_action

  # Instance methods
  def execute_action
    case action_type
    when 'refresh_order'
      RefreshOrderJob.perform_later(self)
    when 'send_email'
      SendEmailJob.perform_later(self)
    when 'mark_resolved'
      MarkResolvedJob.perform_later(self)
    when 'retry_payment'
      RetryPaymentJob.perform_later(self)
    when 'contact_customer'
      ContactCustomerJob.perform_later(self)
    when 'update_fulfillment'
      UpdateFulfillmentJob.perform_later(self)
    end
  end

  def mark_successful!
    update!(status: :successful, executed_at: Time.current)
    alert.update_action_rate
  end

  def mark_failed!(error_message = nil)
    update!(
      status: :failed,
      executed_at: Time.current,
      metadata: metadata.merge(error: error_message)
    )
    alert.update_action_rate
  end

  def shopify_api_call
    alert.store
    # This would integrate with Shopify API
    # For now, we'll simulate the API call
    {
      success: true,
      data: { order_id: metadata&.dig('order_id') }
    }
  end

  def stripe_api_call
    alert.store
    # This would integrate with Stripe API
    # For now, we'll simulate the API call
    {
      success: true,
      data: { payment_intent_id: metadata&.dig('payment_intent_id') }
    }
  end

  def send_email_notification
    # This would integrate with your email service
    # For now, we'll simulate sending an email
    {
      success: true,
      message_id: SecureRandom.uuid
    }
  end

  private

  def set_defaults
    self.status ||= :pending
  end
end
