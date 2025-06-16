# frozen_string_literal: true

module RubyLLM
  module MCP
    module Providers
      module OpenAI
        module ComplexParameterSupport
          module_function

          def param_schema(param)
            properties = case param.type
                         when :array
                           {
                             type: param.type,
                             items: { type: param.item_type }
                           }
                         when :object
                           {
                             type: param.type,
                             properties: param.properties.transform_values { |value| param_schema(value) },
                             required: param.properties.select { |_, p| p.required }.keys
                           }
                         else
                           {
                             type: param.type,
                             description: param.description
                           }
                         end

            properties.compact
          end
        end
      end
    end
  end
end

RubyLLM::Providers::OpenAI.extend(RubyLLM::MCP::Providers::OpenAI::ComplexParameterSupport)
