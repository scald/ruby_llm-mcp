# frozen_string_literal: true

module RubyLLM
  module MCP
    class Resource
      attr_reader :uri, :name, :description, :mime_type, :mcp_client

      def initialize(mcp_client, resource)
        @mcp_client = mcp_client
        @uri = resource["uri"]
        @name = resource["name"]
        @description = resource["description"]
        @mime_type = resource["mimeType"]
        if resource.key?("content_response")
          @content_response = resource["content_response"]
          @content = @content_response["text"] || @content_response["blob"]
        end
      end

      def content
        return @content unless @content.nil?

        response = read_response
        @content_response = response.dig("result", "contents", 0)
        @content = @content_response["text"] || @content_response["blob"]
      end

      def include(chat, **args)
        message = Message.new(
          role: "user",
          content: to_content(**args)
        )

        chat.add_message(message)
      end

      def to_content
        content = self.content

        case content_type
        when "text"
          MCP::Content.new(text: "#{name}: #{description}\n\n#{content}")
        when "blob"
          attachment = MCP::Attachment.new(content, mime_type)
          MCP::Content.new(text: "#{name}: #{description}", attachments: [attachment])
        end
      end

      private

      def content_type
        return "text" if @content_response.nil?

        if @content_response.key?("blob")
          "blob"
        else
          "text"
        end
      end

      def read_response(uri: @uri)
        parsed = URI.parse(uri)
        case parsed.scheme
        when "http", "https"
          fetch_uri_content(uri)
        else # file:// or git://
          @read_response ||= @mcp_client.resource_read_request(uri: uri)
        end
      end

      def fetch_uri_content(uri)
        response = Faraday.get(uri)
        { "result" => { "contents" => [{ "text" => response.body }] } }
      end
    end
  end
end
