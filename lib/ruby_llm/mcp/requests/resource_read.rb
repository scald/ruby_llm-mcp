# frozen_string_literal: true

module RubyLLM
  module MCP
    module Requests
      class ReadingResource < Base
        def call(uri:)
          client.request(reading_resource_body(uri), wait_for_response: false)
        end

        def reading_resource_body(uri)
          {
            jsonrpc: "2.0",
            method: "resources/read",
            params: {
              uri: uri
            }
          }
        end
      end
    end
  end
end
