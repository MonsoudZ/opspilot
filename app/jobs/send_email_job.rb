class SendEmailJob < ApplicationJob
  queue_as :default

  def perform(alert_action)
    alert = alert_action.alert
    alert.store

    # Update status to processing
    alert_action.update!(status: :processing)

    # Simulate sending email
    result = alert_action.send_email_notification

    if result[:success]
      # Log the email sent
      customer_email = alert.metadata&.dig('customer_email')
      Rails.logger.info "Sent email to #{customer_email} for alert #{alert.id}" if customer_email

      alert_action.mark_successful!
    else
      alert_action.mark_failed!('Failed to send email')
    end
  rescue StandardError => e
    alert_action.mark_failed!(e.message)
    Rails.logger.error "SendEmailJob failed: #{e.message}"
  end
end
