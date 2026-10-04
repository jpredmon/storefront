require "application_system_test_case"

class MobileNavigationTest < ApplicationSystemTestCase
  # Resize per test and restore afterwards: the browser is shared across test classes,
  # so a class-level screen_size would leak into later tests.
  setup { page.current_window.resize_to(375, 812) }
  teardown { page.current_window.resize_to(1400, 1000) }

  test "cart link is visible at phone width without opening a menu" do
    visit root_path
    assert_link "Cart (0)"

    within(".card", text: "Art Poster") { click_on "View" }
    click_on "Add to Cart"
    assert_link "Cart (1)"
  end
end
