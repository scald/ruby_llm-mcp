# frozen_string_literal: true

module RubyLLM
  module MCP
    module Requests
      class CompletionResource
        def initialize(client, uri:, argument:, value:)
          @client = client
          @uri = uri
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
                type: "ref/resource",
                uri: @uri
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
