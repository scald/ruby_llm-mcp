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
              if param.item_type == :object
                {
                  type: param.type,
                  items: { type: param.item_type, properties: clean_parameters(param.properties) }
                }
              else
                {
                  type: param.type,
                  items: { type: param.item_type, enum: param.enum }.compact
                }
              end
            when :object
              {
                type: param.type,
                properties: clean_parameters(param.properties),
                required: required_parameters(param.properties)
              }
            when :union
              {
                param.union_type => param.properties.map { |properties| clean_parameters(properties) }
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
