namespace :demo do
  desc 'Seed demo data with fake orders, refunds, and alerts'
  task seed: :environment do
    puts 'Seeding demo data...'

    # Create admin user if doesn't exist
    User.find_or_create_by(email: 'admin@opspilot.com') do |user|
      user.password = 'password123'
      user.role = :admin
      user.active = true
    end

    # Create demo store
    store = Store.find_or_create_by(shopify_domain: 'demo-store.myshopify.com') do |s|
      s.name = 'Demo Store'
      s.stripe_account_id = 'acct_demo123'
      s.slack_webhook_url = 'https://hooks.slack.com/services/demo/webhook'
      s.active = true
    end

    # Create default alert rules
    AlertRule.create_default_rules(store) if store.alert_rules.empty?

    # Create fake webhook events
    create_fake_webhook_events(store)

    # Create some alerts
    create_fake_alerts(store)

    puts 'Demo data seeded successfully!'
    puts 'Admin login: admin@opspilot.com / password123'
  end

  private

  def create_fake_webhook_events(store)
    # Create orders over the last 7 days
    20.times do |i|
      order_data = {
        id: "order_#{SecureRandom.hex(8)}",
        customer: { email: "customer#{i}@example.com" },
        total_price: rand(50..500),
        currency: 'USD',
        created_at: rand(7).days.ago.iso8601
      }

      store.webhook_events.create!(
        event_type: 'order.created',
        payload: order_data,
        processed: true
      )
    end

    # Create some refunds (to trigger refund spike)
    3.times do |_i|
      refund_data = {
        id: "refund_#{SecureRandom.hex(8)}",
        order_id: "order_#{SecureRandom.hex(8)}",
        amount: rand(25..150),
        reason: %w[customer_request defective_item wrong_size].sample
      }

      store.webhook_events.create!(
        event_type: 'refund.created',
        payload: refund_data,
        processed: true
      )
    end

    # Create payment failures
    5.times do |i|
      failure_data = {
        id: "pi_#{SecureRandom.hex(8)}",
        amount: rand(50..300),
        last_payment_error: { message: 'Card declined' },
        customer: { email: "customer#{i}@example.com" }
      }

      store.webhook_events.create!(
        event_type: 'payment_intent.payment_failed',
        payload: failure_data,
        processed: true
      )
    end

    # Create some old unfulfilled orders
    3.times do |i|
      old_order_data = {
        id: "order_#{SecureRandom.hex(8)}",
        customer: { email: "customer#{i}@example.com" },
        total_price: rand(100..400),
        currency: 'USD',
        created_at: rand(4..7).days.ago.iso8601
      }

      store.webhook_events.create!(
        event_type: 'order.created',
        payload: old_order_data,
        processed: true
      )
    end
  end

  def create_fake_alerts(store)
    # Create refund spike alert
    store.alerts.create!(
      rule_type: :refund_spike,
      title: 'Refund Spike Detected',
      description: 'Refund rate has exceeded 5% in the last 24 hours',
      severity: :high,
      status: :active,
      metadata: {
        refund_count: 3,
        total_orders: 20,
        refund_rate: 15.0
      },
      money_saved: 150.0,
      time_saved: 30,
      action_rate: 75.0
    )

    # Create payment failure alert
    store.alerts.create!(
      rule_type: :payment_failure_streak,
      title: 'Payment Failure Streak',
      description: 'Multiple consecutive payment failures detected',
      severity: :critical,
      status: :active,
      metadata: {
        failure_count: 5,
        customer_email: 'customer@example.com'
      },
      money_saved: 250.0,
      time_saved: 45,
      action_rate: 60.0
    )

    # Create unfulfilled order alert
    store.alerts.create!(
      rule_type: :unfulfilled_72h,
      title: 'Unfulfilled Order > 72h',
      description: 'Order has been unfulfilled for over 72 hours',
      severity: :medium,
      status: :active,
      metadata: {
        order_id: 'order_123456',
        order_value: 299.99,
        days_unfulfilled: 4
      },
      money_saved: 30.0,
      time_saved: 60,
      action_rate: 80.0
    )

    # Create some resolved alerts
    2.times do |i|
      store.alerts.create!(
        rule_type: %i[refund_spike payment_failure_streak unfulfilled_72h].sample,
        title: "Resolved Alert #{i + 1}",
        description: 'This alert was resolved successfully',
        severity: %i[low medium high].sample,
        status: :resolved,
        resolved_at: rand(1..3).days.ago,
        resolved_by: User.first,
        money_saved: rand(50..200),
        time_saved: rand(30..90),
        action_rate: rand(70..95)
      )
    end
  end
end
