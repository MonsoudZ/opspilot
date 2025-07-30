class ContactCustomerJob < ApplicationJob
  queue_as :default

  def perform(alert_action)
    alert = alert_action.alert
    alert_action.alert.store

    # Update status to processing
    alert_action.update!(status: :processing)

    # Simulate contacting customer
    customer_email = alert.metadata&.dig('customer_email')

    if customer_email
      # This would typically send a personalized email or create a support ticket
      Rails.logger.info "Contacted customer #{customer_email} for alert #{alert.id}"

      alert_action.mark_successful!
    else
      alert_action.mark_failed!('No customer email found')
    end
  rescue StandardError => e
    alert_action.mark_failed!(e.message)
    Rails.logger.error "ContactCustomerJob failed: #{e.message}"
  end
end
