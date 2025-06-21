# frozen_string_literal: true

# This is an override of the RubyLLM::Chat class to convient methods for easy MCP support
module RubyLLM
  class Chat
    def with_resources(*resources, **args)
      resources.each do |resource|
        resource.include(self, **args)
      end
      self
    end

    def with_resource(resource)
      resource.include(self)
      self
    end

    def with_resource_template(resource_template, arguments: {})
      resource = resource_template.fetch_resource(arguments: arguments)
      resource.include(self)
      self
    end

    def with_prompt(prompt, arguments: {})
      prompt.include(self, arguments: arguments)
      self
    end

    def ask_prompt(prompt, ...)
      prompt.ask(self, ...)
    end
  end
end
