require "test_helper"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  # Chrome's password manager shows a "password found in a data breach" popup after the
  # first sign-in with a common password, and that popup swallows the next click.
  driven_by :selenium, using: :headless_chrome, screen_size: [ 1400, 1000 ] do |options|
    options.add_preference("credentials_enable_service", false)
    options.add_preference("profile.password_manager_enabled", false)
    options.add_preference("profile.password_manager_leak_detection", false)
  end
end
