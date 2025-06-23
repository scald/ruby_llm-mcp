# frozen_string_literal: true

module RubyLLM
  module MCP
    class Coordinator
      PROTOCOL_VERSION = "2025-03-26"
      PV_2024_11_05 = "2024-11-05"

      attr_reader :client, :transport_type, :config, :request_timeout, :headers, :transport, :initialize_response,
                  :capabilities, :protocol_version

      def initialize(client, transport_type:, config: {})
        @client = client
        @transport_type = transport_type
        @config = config

        @request_timeout = config[:request_timeout] || 8000
        @protocol_version = PROTOCOL_VERSION
        @headers = config[:headers] || {}
        @transport = nil
        @capabilities = nil
      end

      def request(body, **options)
        @transport.request(body, **options)
      end

      def start_transport
        case @transport_type
        when :sse
          @transport = RubyLLM::MCP::Transport::SSE.new(@config[:url], request_timeout: @request_timeout,
                                                                       headers: @headers)
        when :stdio
          @transport = RubyLLM::MCP::Transport::Stdio.new(@config[:command], request_timeout: @request_timeout,
                                                                             args: @config[:args], env: @config[:env])
        when :streamable
          @transport = RubyLLM::MCP::Transport::Streamable.new(@config[:url], request_timeout: @request_timeout,
                                                                              headers: @headers)
        else
          raise "Invalid transport type: #{transport_type}"
        end

        @initialize_response = initialize_request
        @capabilities = RubyLLM::MCP::Capabilities.new(@initialize_response["result"]["capabilities"])
        notification_request
      end

      def stop_transport
        @transport&.close
        @transport = nil
      end

      def restart_transport
        stop_transport
        start_transport
      end

      def alive?
        !!@transport&.alive?
      end

      def execute_tool(**args)
        RubyLLM::MCP::Requests::ToolCall.new(self, **args).call
      end

      def resource_read_request(**args)
        RubyLLM::MCP::Requests::ResourceRead.new(self, **args).call
      end

      def completion_resource(**args)
        RubyLLM::MCP::Requests::CompletionResource.new(self, **args).call
      end

      def completion_prompt(**args)
        RubyLLM::MCP::Requests::CompletionPrompt.new(self, **args).call
      end

      def execute_prompt(**args)
        RubyLLM::MCP::Requests::PromptCall.new(self, **args).call
      end

      def initialize_request
        RubyLLM::MCP::Requests::Initialization.new(self).call
      end

      def notification_request
        RubyLLM::MCP::Requests::Notification.new(self).call
      end

      def tool_list_request
        RubyLLM::MCP::Requests::ToolList.new(self).call
      end

      def resources_list_request
        RubyLLM::MCP::Requests::ResourceList.new(self).call
      end

      def resource_template_list_request
        RubyLLM::MCP::Requests::ResourceTemplateList.new(self).call
      end

      def prompt_list_request
        RubyLLM::MCP::Requests::PromptList.new(self).call
      end
    end
  end
end
