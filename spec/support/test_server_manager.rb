# frozen_string_literal: true

class TestServerManager
  @server_pid = nil

  COMMAND = "bun"
  ARGS = "spec/support/server/src/index.ts"
  FLAGS = ["--silent"].freeze

  class << self
    attr_accessor :server_pid

    def start_server
      return if server_pid

      begin
        puts "Starting test MCP server..."
        self.server_pid = spawn(COMMAND, ARGS, "--", *FLAGS)
        Process.detach(server_pid)

        # Give the server a moment to start up
        sleep 1
        puts "Test MCP server started with PID: #{server_pid}"
      rescue StandardError => e
        puts "Failed to start test server: #{e.message}"
        raise
      end
    end

    def stop_server
      return unless server_pid

      begin
        puts "Stopping test MCP server with PID: #{server_pid}"
        Process.kill("TERM", server_pid)
        Process.wait(server_pid)
        puts "Test MCP server stopped"
      rescue Errno::ESRCH, Errno::ECHILD
        # Process already dead or doesn't exist
        puts "Test MCP server was already stopped"
      rescue StandardError => e
        puts "Warning: Failed to cleanly shutdown test server: #{e.message}"
      ensure
        self.server_pid = nil
      end
    end

    def ensure_cleanup
      stop_server if server_pid
    end

    def running?
      server_pid && process_exists?(server_pid)
    end

    private

    def process_exists?(pid)
      Process.kill(0, pid)
      true
    rescue Errno::ESRCH
      false
    end
  end
end

# Ensure server is always killed on exit
at_exit do
  TestServerManager.ensure_cleanup
end
