# Every admin controller inherits from this, so none can forget the login check.
class Admin::BaseController < ApplicationController
  layout "admin"
  before_action :authenticate_admin_admin_user!
end
