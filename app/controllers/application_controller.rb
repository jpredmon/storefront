class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  helper_method :cart

  private

  def cart
    @cart ||= Cart.new(session)
  end

  def after_sign_in_path_for(resource)
    admin_products_path
  end
end
