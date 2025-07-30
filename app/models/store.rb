class Store < ApplicationRecord
  # Associations
  has_many :webhook_events, dependent: :destroy
  has_many :alerts, dependent: :destroy
  has_many :alert_rules, dependent: :destroy

  # Validations
  validates :name, presence: true
  validates :shopify_domain, presence: true, uniqueness: true
  validates :stripe_account_id, presence: true
  validates :slack_webhook_url, presence: true

  # Scopes
  scope :active, -> { where(active: true) }

  # Enums
  enum :status, { active: 'active', inactive: 'inactive', suspended: 'suspended' }

  # Callbacks
  before_create :set_default_status

  # Instance methods
  def shopify_url
    "https://#{shopify_domain}"
  end

  def stripe_dashboard_url
    "https://dashboard.stripe.com/accounts/#{stripe_account_id}"
  end

  def recent_alerts(limit = 20)
    alerts.order(created_at: :desc).limit(limit)
  end

  def active_alerts
    alerts.where(status: 'active')
  end

  def resolved_alerts
    alerts.where(status: 'resolved')
  end

  def total_money_saved
    alerts.sum(:money_saved) || 0
  end

  def total_time_saved
    alerts.sum(:time_saved) || 0
  end

  def average_action_rate
    return 0 if alerts.none?

    alerts.average(:action_rate) || 0
  end

  private

  def set_default_status
    self.status ||= :active
  end
end
