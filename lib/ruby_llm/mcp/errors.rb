# frozen_string_literal: true

module RubyLLM
  module MCP
    module Errors
      class BaseError < StandardError
        attr_reader :message

        def initialize(message:)
          @message = message
          super(message)
        end
      end

      class InvalidProtocolVersionError < BaseError; end

      class SessionExpiredError < BaseError; end

      class TimeoutError < BaseError; end

      class PromptArgumentError < BaseError; end

      class CompletionNotAvailable < BaseError; end
    end
  end
end
