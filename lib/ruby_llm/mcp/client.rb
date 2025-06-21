# frozen_string_literal: true

module RubyLLM
  module MCP
    class Client
      PROTOCOL_VERSION = "2025-03-26"
      PV_2024_11_05 = "2024-11-05"

      attr_reader :name, :config, :transport_type, :transport, :request_timeout, :reverse_proxy_url, :protocol_version,
                  :capabilities

      def initialize(name:, transport_type:, start: true, request_timeout: 8000, reverse_proxy_url: nil, config: {}) # rubocop:disable Metrics/ParameterLists
        @name = name
        @config = config
        @protocol_version = PROTOCOL_VERSION
        @headers = config[:headers] || {}

        @transport_type = transport_type.to_sym
        @transport = nil

        @capabilities = nil

        @request_timeout = request_timeout
        @reverse_proxy_url = reverse_proxy_url

        if start
          self.start
        end
      end

      def request(body, **options)
        @transport.request(body, **options)
      end

      def start
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

      def stop
        @transport&.close
        @transport = nil
      end

      def restart!
        stop
        start
      end

      def alive?
        !!@transport&.alive?
      end

      def tools(refresh: false)
        @tools = nil if refresh
        @tools ||= fetch_and_create_tools
        @tools.values
      end

      def tool(name, refresh: false)
        @tools = nil if refresh
        @tools ||= fetch_and_create_tools

        @tools[name]
      end

      def resources(refresh: false)
        @resources = nil if refresh
        @resources ||= fetch_and_create_resources
        @resources.values
      end

      def resource(name, refresh: false)
        @resources = nil if refresh
        @resources ||= fetch_and_create_resources

        @resources[name]
      end

      def resource_templates(refresh: false)
        @resource_templates = nil if refresh
        @resource_templates ||= fetch_and_create_resource_templates
        @resource_templates.values
      end

      def resource_template(name, refresh: false)
        @resource_templates = nil if refresh
        @resource_templates ||= fetch_and_create_resource_templates

        @resource_templates[name]
      end

      def prompts(refresh: false)
        @prompts = nil if refresh
        @prompts ||= fetch_and_create_prompts
        @prompts.values
      end

      def prompt(name, refresh: false)
        @prompts = nil if refresh
        @prompts ||= fetch_and_create_prompts

        @prompts[name]
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

      private

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

      def fetch_and_create_tools
        tools_response = tool_list_request
        tools_response = tools_response["result"]["tools"]

        tools = {}
        tools_response.each do |tool|
          new_tool = RubyLLM::MCP::Tool.new(self, tool)
          tools[new_tool.name] = new_tool
        end

        tools
      end

      def fetch_and_create_resources
        resources_response = resources_list_request
        resources_response = resources_response["result"]["resources"]

        resources = {}
        resources_response.each do |resource|
          new_resource = RubyLLM::MCP::Resource.new(self, resource)
          resources[new_resource.name] = new_resource
        end

        resources
      end

      def fetch_and_create_resource_templates
        resource_templates_response = resource_template_list_request
        resource_templates_response = resource_templates_response["result"]["resourceTemplates"]

        resource_templates = {}
        resource_templates_response.each do |resource_template|
          new_resource_template = RubyLLM::MCP::ResourceTemplate.new(self, resource_template)
          resource_templates[new_resource_template.name] = new_resource_template
        end

        resource_templates
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
