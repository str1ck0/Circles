require "test_helper"

# Rails 7.0's Selenium adapter passes the removed `capabilities` keyword.
# Register through Capybara using the current `options` API until Rails is upgraded.
Capybara.register_driver :circles_chrome do |app|
  options = Selenium::WebDriver::Chrome::Options.new
  options.add_argument("--headless=new")
  options.add_argument("--window-size=1280,900")
  Capybara::Selenium::Driver.new(app, browser: :chrome, options: options)
end

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driven_by :circles_chrome
end
