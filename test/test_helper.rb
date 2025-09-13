ENV['RAILS_ENV'] ||= 'test'
require_relative '../config/environment'
require 'rails/test_help'

class ActiveSupport::TestCase
  # Run tests in parallel with specified workers
  parallelize(workers: 1)

  # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
  fixtures :all
end

class ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
end

# Configure OmniAuth test mode for callback tests
OmniAuth.config.test_mode = true

# Simple helper to stub singleton methods (like .new) without external libs
def stub_singleton_method(klass, method_name, impl)
  original = klass.method(method_name)
  klass.define_singleton_method(method_name, &impl)
  yield
ensure
  klass.define_singleton_method(method_name) do |*args, **kwargs, &blk|
    original.call(*args, **kwargs, &blk)
  end
end
