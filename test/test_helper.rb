ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

module ActiveSupport
  class TestCase
    # Process-based parallelism (Rails' default) needs fork, which Windows lacks.
    # Thread-based parallelism shared one PG connection across threads and crashed
    # (`cmd_tuples` for nil) once the suite passed the 50-test threshold, so Windows runs serially.
    parallelize(workers: Gem.win_platform? ? 1 : :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Add more helper methods to be used by all tests here...
    include Devise::Test::IntegrationHelpers
  end
end
