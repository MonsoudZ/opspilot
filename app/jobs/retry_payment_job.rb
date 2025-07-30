class RetryPaymentJob < ApplicationJob
  queue_as :default

  def perform(alert_action)
    alert = alert_action.alert
    store = alert.store

    # Update status to processing
    alert_action.update!(status: :processing)

    # Simulate Stripe API call to retry payment
    result = alert_action.stripe_api_call

    if result[:success]
      payment_intent_id = alert.metadata&.dig('payment_intent_id')
      Rails.logger.info "Retried payment #{payment_intent_id} for store #{store.name}" if payment_intent_id

      alert_action.mark_successful!
    else
      alert_action.mark_failed!('Failed to retry payment')
    end
  rescue StandardError => e
    alert_action.mark_failed!(e.message)
    Rails.logger.error "RetryPaymentJob failed: #{e.message}"
  end
end
