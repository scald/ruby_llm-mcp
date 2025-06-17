# frozen_string_literal: true

module RubyLLM
  module MCP
    module Requests
      class PromptCall
        def initialize(client, name:, arguments: {})
          @client = client
          @name = name
          @arguments = arguments
        end

        def call
          @client.request(request_body)
        end

        private

        def request_body
          {
            jsonrpc: "2.0",
            method: "prompts/get",
            params: {
              name: @name,
              arguments: @arguments
            }
          }
        end
      end
    end
  end
end
