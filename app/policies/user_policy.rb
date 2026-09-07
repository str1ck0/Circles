class UserPolicy < ApplicationPolicy
  def show? = user.present?
end
