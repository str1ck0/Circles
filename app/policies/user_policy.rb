class UserPolicy < ApplicationPolicy
  def index? = user.present?
  def show?  = user.present?
end
