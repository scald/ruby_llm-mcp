# frozen_string_literal: true

class RubyLLM::MCP::Requests::Initialization < RubyLLM::MCP::Requests::Base
  def call
    client.request(initialize_body)
  end

  private

  def initialize_body
    {
      jsonrpc: "2.0",
      method: "initialize",
      params: {
        protocolVersion: @client.protocol_version,
        capabilities: {},
        clientInfo: {
          name: "RubyLLM-MCP Client",
          version: RubyLLM::MCP::VERSION
        }
      }
    }
  end
end
