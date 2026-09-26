require "test_helper"
require "fugit"

class RecurringScheduleTest < ActiveSupport::TestCase
  test "email intake polls every 15 minutes, never on the quarter hours" do
    task = YAML.load_file(Rails.root.join("config/recurring.yml")).dig("production", "email_intake")
    cron = Fugit.parse_cron(task["schedule"])

    minutes = (0..59).select { |minute| cron.match?(Time.utc(2026, 1, 1, 10, minute)) }

    assert_equal [ 7, 22, 37, 52 ], minutes
  end
end
