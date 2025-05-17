module AdminAuthentication
  extend ActiveSupport::Concern

  included do
    before_action :require_admin!
    helper_method :admin_signed_in?
  end

  private

  def admin_signed_in?
    Current.session&.user&.admin?
  end

  def require_admin!
    unless admin_signed_in?
      flash[:alert] = "You must be an admin to access that page."
      redirect_to root_path
    end
  end
end
