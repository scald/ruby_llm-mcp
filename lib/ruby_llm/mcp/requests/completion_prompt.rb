# frozen_string_literal: true

module RubyLLM
  module MCP
    module Requests
      class CompletionPrompt
        def initialize(client, name:, argument:, value:)
          @client = client
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
                type: "ref/prompt",
                name: @name
              },
              argument: {
                name: @argument,
                value: @value
              }
            }
          }
        end
      end
    end
  end
end
