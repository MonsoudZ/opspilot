class DashboardController < ApplicationController
  before_action :authenticate_user!
  before_action :ensure_user_can_access!

  def index
    @total_money_saved = Alert.sum(:money_saved) || 0
    @total_time_saved = Alert.sum(:time_saved) || 0
    @recent_alerts = Alert.includes(:store).recent.limit(20)
    @active_alerts_count = Alert.active.count
    @resolved_alerts_count = Alert.resolved.count
    @average_action_rate = Alert.average(:action_rate) || 0
  end

  private

  def ensure_user_can_access!
    return if current_user.can_access?

    redirect_to new_user_session_path, alert: 'Access denied. Please contact an administrator.'
  end
end
