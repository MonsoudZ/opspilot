class UpdateFulfillmentJob < ApplicationJob
  queue_as :default

  def perform(alert_action)
    alert = alert_action.alert
    store = alert.store

    # Update status to processing
    alert_action.update!(status: :processing)

    # Simulate Shopify API call to update fulfillment
    result = alert_action.shopify_api_call

    if result[:success]
      order_id = alert.metadata&.dig('order_id')
      if order_id
        # This would typically update the fulfillment status via Shopify API
        Rails.logger.info "Updated fulfillment for order #{order_id} for store #{store.name}"
      end

      alert_action.mark_successful!
    else
      alert_action.mark_failed!('Failed to update fulfillment')
    end
  rescue StandardError => e
    alert_action.mark_failed!(e.message)
    Rails.logger.error "UpdateFulfillmentJob failed: #{e.message}"
  end
end
