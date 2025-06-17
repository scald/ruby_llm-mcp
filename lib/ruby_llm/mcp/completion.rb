# frozen_string_literal: true

module RubyLLM
  module MCP
    class Completion
      attr_reader :values, :total, :has_more

      def initialize(values:, total:, has_more:)
        @values = values
        @total = total
        @has_more = has_more
      end
    end
  end
end
