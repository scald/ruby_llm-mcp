# frozen_string_literal: true

module RubyLLM
  module MCP
    module Providers
      module Anthropic
        module ComplexParameterSupport
          module_function

          def clean_parameters(parameters)
            parameters.transform_values do |param|
              build_properties(param).compact
            end
          end

          def required_parameters(parameters)
            parameters.select { |_, param| param.required }.keys
          end

          def build_properties(param)
            case param.type
            when :array
              {
                type: param.type,
                items: { type: param.item_type }
              }
            when :object
              {
                type: param.type,
                properties: clean_parameters(param.properties),
                required: required_parameters(param.properties)
              }
            else
              {
                type: param.type,
                description: param.description
              }
            end
          end
        end
      end
    end
  end
end

RubyLLM::Providers::Anthropic.extend(RubyLLM::MCP::Providers::Anthropic::ComplexParameterSupport)
