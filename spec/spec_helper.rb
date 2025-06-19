# frozen_string_literal: true

require "debug"
require "simplecov"
require "vcr"

require_relative "support/client_runner"
require_relative "support/test_server_manager"

SimpleCov.start do
  add_filter "/spec/"
  add_filter "/examples/"

  enable_coverage :branch
end

require "bundler/setup"
require "ruby_llm/mcp"

CLIENT_OPTIONS = [
  {
    name: "stdio",
    options: {
      name: "stdio-server",
      transport_type: :stdio,
      config: {
        command: "bun",
        args: [
          "spec/support/server/src/index.ts",
          "--stdio"
        ]
      }
    }
  },
  { name: "streamable",
    options: {
      name: "streamable-server",
      transport_type: :streamable,
      config: {
        url: "http://localhost:3005/mcp"
      }
    } }
].freeze

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.before(:all) do
    TestServerManager.start_server
  end

  config.after(:all) do
    TestServerManager.stop_server
  end
end
