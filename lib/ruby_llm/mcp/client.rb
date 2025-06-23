# frozen_string_literal: true

module RubyLLM
  module MCP
    class Client
      attr_reader :name, :config, :transport_type, :transport, :request_timeout, :reverse_proxy_url, :protocol_version

      def initialize(name:, transport_type:, start: true, request_timeout: 8000, config: {})
        @name = name
        @config = config
        @transport_type = transport_type.to_sym
        @request_timeout = request_timeout
        @config[:request_timeout] = request_timeout

        @coordinator = RubyLLM::MCP::Coordinator.new(self, transport_type: @transport_type, config: config)

        if start
          self.start
        end
      end

      def capabilities
        @coordinator.capabilities
      end

      def start
        @coordinator.start_transport
      end

      def stop
        @coordinator.stop_transport
      end

      def restart!
        stop
        start
      end

      def alive?
        @coordinator.alive?
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

      private

      def fetch_and_create_tools
        tools_response = @coordinator.tool_list_request
        tools_response = tools_response["result"]["tools"]

        tools = {}
        tools_response.each do |tool|
          new_tool = RubyLLM::MCP::Tool.new(@coordinator, tool)
          tools[new_tool.name] = new_tool
        end

        tools
      end

      def fetch_and_create_resources
        resources_response = @coordinator.resources_list_request
        resources_response = resources_response["result"]["resources"]

        resources = {}
        resources_response.each do |resource|
          new_resource = RubyLLM::MCP::Resource.new(@coordinator, resource)
          resources[new_resource.name] = new_resource
        end

        resources
      end

      def fetch_and_create_resource_templates
        resource_templates_response = @coordinator.resource_template_list_request
        resource_templates_response = resource_templates_response["result"]["resourceTemplates"]

        resource_templates = {}
        resource_templates_response.each do |resource_template|
          new_resource_template = RubyLLM::MCP::ResourceTemplate.new(@coordinator, resource_template)
          resource_templates[new_resource_template.name] = new_resource_template
        end

        resource_templates
      end

      def fetch_and_create_prompts
        prompts_response = @coordinator.prompt_list_request
        prompts_response = prompts_response["result"]["prompts"]

        prompts = {}
        prompts_response.each do |prompt|
          new_prompt = RubyLLM::MCP::Prompt.new(@coordinator, prompt)
          prompts[new_prompt.name] = new_prompt
        end

        prompts
      end
    end
  end
end
