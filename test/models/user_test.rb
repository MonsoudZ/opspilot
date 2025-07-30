require 'test_helper'

class UserTest < ActiveSupport::TestCase
  test "user can be created" do
    user = User.new(
      email: 'test@example.com',
      password: 'password123',
      password_confirmation: 'password123'
    )
    assert user.valid?
  end

  test "user requires email" do
    user = User.new(password: 'password123')
    assert_not user.valid?
    assert_includes user.errors[:email], "can't be blank"
  end

  test "user requires password" do
    user = User.new(email: 'test@example.com')
    assert_not user.valid?
    assert_includes user.errors[:password], "can't be blank"
  end
end
