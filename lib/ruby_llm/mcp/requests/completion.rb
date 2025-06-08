# frozen_string_literal: true

module RubyLLM
  module MCP
    module Requests
      class Completion
        def initialize(client, type:, name:, argument:, value:)
          @client = client
          @type = type
          @name = name
          @argument = argument
          @value = value
        end

        def call
          @client.request(request_body)
        end

        private

        def request_body
          {
            jsonrpc: "2.0",
            id: 1,
            method: "completion/complete",
            params: {
              ref: {
                type: ref_type,
                name: @name
              },
              argument: {
                name: @argument,
                value: @value
              }
            }
          }
        end

        def ref_type
          case @type
          when :prompt
            "ref/prompt"
          when :resource
            "ref/resource"
          end
        end
      end
    end
  end
end
