require 'simplecov'
SimpleCov.start

ENV['RAILS_ENV'] ||= 'test'
require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'
require 'minitest/reporters'
Minitest::Reporters.use!

Dir[Rails.root.join('test/shared/**/*')].each { |f| require f }

class ActiveSupport::TestCase
  # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
  fixtures :all

  # Add more helper methods to be used by all tests here...

  # Default user for testing has Admin privileges
  DEFAULT_TEST_USER = 'test_admin'.freeze
  CASClient::Frameworks::Rails::Filter.fake(DEFAULT_TEST_USER)

  # Runs the contents of a block using the given user as the current_user.
  # rubocop:disable Lint/RescueException
  def run_as_user(user)
    CASClient::Frameworks::Rails::Filter.fake(user.cas_directory_id)

    begin

      yield

    rescue Exception => e
      raise e
    ensure
      # Restore fake user
      CASClient::Frameworks::Rails::Filter.fake(ActiveSupport::TestCase::DEFAULT_TEST_USER)
    end
  end

  # Returns an array of divisions that have at least one record
  def divisions_with_records
    LaborRequest.select(:department_id).distinct.collect { |r| r.department.division }.uniq
  end

  # Returns an array of departments that have at least one record
  def departments_with_records
    LaborRequest.select(:department_id).distinct.collect(&:department)
  end

  # Returns an array of units that have at least one record
  def units_with_records
    LaborRequest.select(:unit_id).distinct.collect { |r| r.unit unless r.unit.nil? }.compact
  end
end
