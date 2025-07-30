class MarkResolvedJob < ApplicationJob
  queue_as :default

  def perform(alert_action)
    alert = alert_action.alert

    # Update status to processing
    alert_action.update!(status: :processing)

    # Mark the alert as resolved
    alert.resolve!

    # Calculate savings
    alert.calculate_savings

    alert_action.mark_successful!

    Rails.logger.info "Alert #{alert.id} marked as resolved"
  rescue StandardError => e
    alert_action.mark_failed!(e.message)
    Rails.logger.error "MarkResolvedJob failed: #{e.message}"
  end
end
