class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  # Add admin role for invite-only access
  enum :role, { user: 0, admin: 1 }

  # Validations
  validates :email, presence: true, uniqueness: true
  validates :role, presence: true

  # Scopes
  scope :active, -> { where(active: true) }
  scope :admins, -> { where(role: :admin) }

  # Check if user can access the system (invite-only)
  def can_access?
    admin? || active?
  end

  # Check if user can manage other users
  def can_manage_users?
    admin?
  end
end
