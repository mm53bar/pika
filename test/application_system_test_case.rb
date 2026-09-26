require "test_helper"
require "capybara/cuprite"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driven_by :cuprite, screen_size: [ 1280, 900 ], options: { headless: true, process_timeout: 20, js_errors: true }
end
