# frozen_string_literal: true

module RubyLLM
  module MCP
    class Resource
      attr_reader :uri, :name, :description, :mime_type, :mcp_client, :template

      def initialize(mcp_client, resource, template: false)
        @mcp_client = mcp_client
        @uri = resource["uri"]
        @name = resource["name"]
        @description = resource["description"]
        @mime_type = resource["mimeType"]
        @content = resource["content"] || nil
        @template = template
      end

      def content(arguments: {})
        return @content if @content && !template?

        response = if template?
                     templated_uri = apply_template(@uri, arguments)

                     read_response(uri: templated_uri)
                   else
                     read_response
                   end

        content = response.dig("result", "contents", 0)
        @type = if content.key?("type")
                  content["type"]
                else
                  "text"
                end

        @content = content["text"] || content["blob"]
      end

      def include(chat, **args)
        message = Message.new(
          role: "user",
          content: to_content(**args)
        )

        chat.add_message(message)
      end

      def to_content(arguments: {})
        content = content(arguments: arguments)

        case @type
        when "text"
          MCP::Content.new(content)
        when "blob"
          attachment = MCP::Attachment.new(content, mime_type)
          MCP::Content.new(text: "#{name}: #{description}", attachments: [attachment])
        end
      end

      def arguments_search(argument, value)
        if template? && @mcp_client.capabilities.completion?
          response = @mcp_client.completion(type: :resource, name: @name, argument: argument, value: value)
          response = response.dig("result", "completion")

          Completion.new(values: response["values"], total: response["total"], has_more: response["hasMore"])
        else
          raise Errors::CompletionNotAvailable, "Completion is not available for this MCP server"
        end
      end

      def template?
        @template
      end

      private

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

      def apply_template(uri, arguments)
        uri.gsub(/\{(\w+)\}/) do
          arguments[::Regexp.last_match(1).to_sym] || "{#{::Regexp.last_match(1)}}"
        end
      end
    end
  end
end
