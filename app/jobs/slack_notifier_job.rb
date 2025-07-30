class SlackNotifierJob < ApplicationJob
  queue_as :default

  def perform(alert)
    return if alert.store.slack_webhook_url.blank?

    message = build_slack_message(alert)

    # Send to Slack webhook
    response = HTTP.post(
      alert.store.slack_webhook_url,
      json: message
    )

    Rails.logger.info "Slack notification sent for alert #{alert.id}: #{response.status}"
  rescue StandardError => e
    Rails.logger.error "Failed to send Slack notification: #{e.message}"
  end

  private

  def build_slack_message(alert)
    {
      text: alert.title,
      blocks: [
        {
          type: 'header',
          text: {
            type: 'plain_text',
            text: alert.title,
            emoji: true
          }
        },
        {
          type: 'section',
          text: {
            type: 'mrkdwn',
            text: alert.description
          }
        },
        {
          type: 'section',
          fields: [
            {
              type: 'mrkdwn',
              text: "*Store:*\n#{alert.store.name}"
            },
            {
              type: 'mrkdwn',
              text: "*Severity:*\n#{alert.severity.humanize}"
            },
            {
              type: 'mrkdwn',
              text: "*Money at Risk:*\n$#{alert.money_saved || 0}"
            },
            {
              type: 'mrkdwn',
              text: "*Time Saved:*\n#{alert.time_saved || 0} minutes"
            }
          ]
        },
        {
          type: 'actions',
          elements: build_action_buttons(alert)
        }
      ]
    }
  end

  def build_action_buttons(alert)
    alert.action_buttons.map do |button|
      {
        type: 'button',
        text: {
          type: 'plain_text',
          text: button[:text],
          emoji: true
        },
        style: button[:style],
        value: "#{alert.id}_#{button[:action]}",
        action_id: button[:action]
      }
    end
  end
end
