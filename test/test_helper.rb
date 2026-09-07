ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    # Excludes test/fixtures/content and test/fixtures/invalid_content, which hold
    # ContentLoader markdown/YAML fixtures (plain data files, not ActiveRecord
    # fixture sets).
    non_ar_fixture_roots = [
      Rails.root.join("test/fixtures/content").to_s,
      Rails.root.join("test/fixtures/invalid_content").to_s
    ]
    fixture_set_names = Dir[Rails.root.join("test/fixtures/{**,*}/*.yml")]
      .reject { |f| non_ar_fixture_roots.any? { |root| f.start_with?(root) } }
      .map { |f| f.delete_prefix("#{Rails.root.join('test/fixtures')}/").delete_suffix(".yml") }

    fixtures(*fixture_set_names) if fixture_set_names.any?

    # Add more helper methods to be used by all tests here...
  end
end
