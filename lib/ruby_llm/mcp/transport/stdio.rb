# frozen_string_literal: true

require "open3"
require "json"
require "timeout"
require "securerandom"

module RubyLLM
  module MCP
    module Transport
      class Stdio
        attr_reader :command, :stdin, :stdout, :stderr, :id

        def initialize(command, request_timeout:, args: [], env: {})
          @request_timeout = request_timeout
          @command = command
          @args = args
          @env = env || {}
          @client_id = SecureRandom.uuid

          @id_counter = 0
          @id_mutex = Mutex.new
          @pending_requests = {}
          @pending_mutex = Mutex.new
          @running = true
          @reader_thread = nil
          @stderr_thread = nil

          start_process
        end

        def request(body, add_id: true, wait_for_response: true)
          if add_id
            @id_mutex.synchronize { @id_counter += 1 }
            request_id = @id_counter
            body["id"] = request_id
          end

          response_queue = Queue.new
          if wait_for_response
            @pending_mutex.synchronize do
              @pending_requests[request_id.to_s] = response_queue
            end
          end

          begin
            @stdin.puts(JSON.generate(body))
            @stdin.flush
          rescue IOError, Errno::EPIPE => e
            @pending_mutex.synchronize { @pending_requests.delete(request_id.to_s) }
            restart_process
            raise "Failed to send request: #{e.message}"
          end

          return unless wait_for_response

          begin
            Timeout.timeout(@request_timeout / 1000) do
              response_queue.pop
            end
          rescue Timeout::Error
            @pending_mutex.synchronize { @pending_requests.delete(request_id.to_s) }
            raise RubyLLM::MCP::Errors::TimeoutError.new(
              message: "Request timed out after #{@request_timeout / 1000} seconds"
            )
          end
        end

        def alive?
          @running
        end

        def close # rubocop:disable Metrics/MethodLength
          @running = false

          begin
            @stdin&.close
          rescue StandardError
            nil
          end

          begin
            @wait_thread&.join(1)
          rescue StandardError
            nil
          end

          begin
            @stdout&.close
          rescue StandardError
            nil
          end

          begin
            @stderr&.close
          rescue StandardError
            nil
          end

          begin
            @reader_thread&.join(1)
          rescue StandardError
            nil
          end

          begin
            @stderr_thread&.join(1)
          rescue StandardError
            nil
          end

          @stdin = nil
          @stdout = nil
          @stderr = nil
          @wait_thread = nil
          @reader_thread = nil
          @stderr_thread = nil
        end

        private

        def start_process
          close if @stdin || @stdout || @stderr || @wait_thread

          @stdin, @stdout, @stderr, @wait_thread = if @env.empty?
                                                     Open3.popen3(@command, *@args)
                                                   else
                                                     Open3.popen3(@env, @command, *@args)
                                                   end

          start_reader_thread
          start_stderr_thread
        end

        def restart_process
          puts "Process connection lost. Restarting..."
          start_process
        end

        def start_reader_thread
          @reader_thread = Thread.new do
            while @running
              begin
                if @stdout.closed? || @wait_thread.nil? || !@wait_thread.alive?
                  sleep 1
                  restart_process if @running
                  next
                end

                line = @stdout.gets
                next unless line && !line.strip.empty?

                process_response(line.strip)
              rescue IOError, Errno::EPIPE => e
                puts "Reader error: #{e.message}. Restarting in 1 second..."
                sleep 1
                restart_process if @running
              rescue StandardError => e
                puts "Error in reader thread: #{e.message}, #{e.backtrace.join("\n")}"
                sleep 1
              end
            end
          end

          @reader_thread.abort_on_exception = true
        end

        def start_stderr_thread
          @stderr_thread = Thread.new do
            while @running
              begin
                if @stderr.closed? || @wait_thread.nil? || !@wait_thread.alive?
                  sleep 1
                  next
                end

                line = @stderr.gets
                next unless line && !line.strip.empty?

                puts "STDERR: #{line.strip}"
              rescue IOError, Errno::EPIPE => e
                puts "Stderr reader error: #{e.message}"
                sleep 1
              rescue StandardError => e
                puts "Error in stderr thread: #{e.message}"
                sleep 1
              end
            end
          end

          @stderr_thread.abort_on_exception = true
        end

        def process_response(line)
          response = JSON.parse(line)
          request_id = response["id"]&.to_s

          @pending_mutex.synchronize do
            if request_id && @pending_requests.key?(request_id)
              response_queue = @pending_requests.delete(request_id)
              response_queue&.push(response)
            end
          end
        rescue JSON::ParserError => e
          RubyLLM.logger.error("Error parsing response as JSON: #{e.message}\nRaw response: #{line}")
        end
      end
    end
  end
end
