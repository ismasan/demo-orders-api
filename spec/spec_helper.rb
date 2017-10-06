require "dotenv"
Dotenv.load('env.example')
require 'byebug'
spec_dir = File.dirname(__FILE__)
Dir[File.join(spec_dir, "support/**/*.rb")].each {|f| require f}

# See http://rubydoc.info/gems/rspec-core/RSpec/Core/Configuration
RSpec.configure do |config|
  config.around(:each) do |example|
    REDIS.select 3
    example.run
    REDIS.flushdb
  end

  config.include RequestHelpers, type: [:request, :feature]

  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups
end
