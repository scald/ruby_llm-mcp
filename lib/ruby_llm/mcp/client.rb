# frozen_string_literal: true

module RubyLLM
  module MCP
    class Client
      PROTOCOL_VERSION = "2025-03-26"
      PV_2024_11_05 = "2024-11-05"

      attr_reader :name, :config, :transport_type, :transport, :request_timeout, :reverse_proxy_url, :protocol_version,
                  :capabilities

      def initialize(name:, transport_type:, request_timeout: 8000, reverse_proxy_url: nil, config: {})
        @name = name
        @config = config
        @protocol_version = PROTOCOL_VERSION
        @headers = config[:headers] || {}

        @transport_type = transport_type.to_sym

        case @transport_type
        when :sse
          @transport = RubyLLM::MCP::Transport::SSE.new(@config[:url], headers: @headers)
        when :stdio
          @transport = RubyLLM::MCP::Transport::Stdio.new(@config[:command], args: @config[:args], env: @config[:env])
        when :streamable
          @transport = RubyLLM::MCP::Transport::Streamable.new(@config[:url], headers: @headers)
        else
          raise "Invalid transport type: #{transport_type}"
        end
        @capabilities = nil

        @request_timeout = request_timeout
        @reverse_proxy_url = reverse_proxy_url

        initialize_request
        notification_request
      end

      def request(body, **options)
        @transport.request(body, **options)
      end

      def tools(refresh: false)
        @tools = nil if refresh
        @tools ||= fetch_and_create_tools
      end

      def resources(refresh: false)
        @resources = nil if refresh
        @resources ||= fetch_and_create_resources
      end

      def resource_templates(refresh: false)
        @resource_templates = nil if refresh
        @resource_templates ||= fetch_and_create_resources(set_as_template: true)
      end

      def prompts(refresh: false)
        @prompts = nil if refresh
        @prompts ||= fetch_and_create_prompts
      end

      def execute_tool(**args)
        RubyLLM::MCP::Requests::ToolCall.new(self, **args).call
      end

      def resource_read_request(**args)
        RubyLLM::MCP::Requests::ResourceRead.new(self, **args).call
      end

      def completion(**args)
        RubyLLM::MCP::Requests::Completion.new(self, **args).call
      end

      def execute_prompt(**args)
        RubyLLM::MCP::Requests::PromptCall.new(self, **args).call
      end

      private

      def initialize_request
        @initialize_response = RubyLLM::MCP::Requests::Initialization.new(self).call
        @capabilities = RubyLLM::MCP::Capabilities.new(@initialize_response["result"]["capabilities"])
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

      def fetch_and_create_tools
        tools_response = tool_list_request
        tools_response = tools_response["result"]["tools"]

        @tools = tools_response.map do |tool|
          RubyLLM::MCP::Tool.new(self, tool)
        end
      end

      def fetch_and_create_resources(set_as_template: false)
        resources_response = resources_list_request
        resources_response = resources_response["result"]["resources"]

        resources = {}
        resources_response.each do |resource|
          new_resource = RubyLLM::MCP::Resource.new(self, resource, template: set_as_template)
          resources[new_resource.name] = new_resource
        end

        resources
      end

      def fetch_and_create_prompts
        prompts_response = prompt_list_request
        prompts_response = prompts_response["result"]["prompts"]

        prompts = {}
        prompts_response.each do |prompt|
          new_prompt = RubyLLM::MCP::Prompt.new(self,
                                                name: prompt["name"],
                                                description: prompt["description"],
                                                arguments: prompt["arguments"])

          prompts[new_prompt.name] = new_prompt
        end

        prompts
      end
    end
  end
end
