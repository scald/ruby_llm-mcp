# frozen_string_literal: true

require "forwardable"

module RubyLLM
  module MCP
    class Client
      extend Forwardable

      attr_reader :name, :config, :transport_type, :request_timeout

      def initialize(name:, transport_type:, start: true, request_timeout: 8000, config: {})
        @name = name
        @config = config.merge(request_timeout: request_timeout)
        @transport_type = transport_type.to_sym
        @request_timeout = request_timeout

        @coordinator = Coordinator.new(self, transport_type: @transport_type, config: @config)

        start_transport if start
      end

      def_delegators :@coordinator, :start_transport, :stop_transport, :restart_transport, :alive?, :capabilities

      alias start start_transport
      alias stop stop_transport
      alias restart! restart_transport

      def tools(refresh: false)
        fetch(:tools, refresh) do
          tools_data = @coordinator.tool_list.dig("result", "tools")
          build_map(tools_data, MCP::Tool)
        end

        @tools.values
      end

      def tool(name, refresh: false)
        tools(refresh: refresh)

        @tools[name]
      end

      def resources(refresh: false)
        fetch(:resources, refresh) do
          resources_data = @coordinator.resource_list.dig("result", "resources")
          build_map(resources_data, MCP::Resource)
        end

        @resources.values
      end

      def resource(name, refresh: false)
        resources(refresh: refresh)

        @resources[name]
      end

      def resource_templates(refresh: false)
        fetch(:resource_templates, refresh) do
          templates_data = @coordinator.resource_template_list.dig("result", "resourceTemplates")
          build_map(templates_data, MCP::ResourceTemplate)
        end

        @resource_templates.values
      end

      def resource_template(name, refresh: false)
        resource_templates(refresh: refresh)

        @resource_templates[name]
      end

      def prompts(refresh: false)
        fetch(:prompts, refresh) do
          prompts_data = @coordinator.prompt_list.dig("result", "prompts")
          build_map(prompts_data, MCP::Prompt)
        end

        @prompts.values
      end

      def prompt(name, refresh: false)
        prompts(refresh: refresh)

        @prompts[name]
      end

      private

      def fetch(cache_key, refresh)
        instance_variable_set("@#{cache_key}", nil) if refresh
        instance_variable_get("@#{cache_key}") || instance_variable_set("@#{cache_key}", yield)
      end

      def build_map(raw_data, klass)
        raw_data.each_with_object({}) do |item, acc|
          instance = klass.new(@coordinator, item)
          acc[instance.name] = instance
        end
      end
    end
  end
end
