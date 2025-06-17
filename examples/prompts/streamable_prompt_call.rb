# frozen_string_literal: true

require "bundler/setup"
require "ruby_llm/mcp"
require "debug"
require "dotenv"

Dotenv.load

RubyLLM.configure do |config|
  config.openai_api_key = ENV.fetch("OPENAI_API_KEY", nil)
end

# Test with streamable HTTP transport
client = RubyLLM::MCP.client(
  name: "streamable_mcp",
  transport_type: :streamable,
  config: {
    url: "http://localhost:3005/mcp"
  }
)

prompt_one = client.prompts["poem_of_the_day"]
prompt_two = client.prompts["greeting"]

chat = RubyLLM.chat(model: "gpt-4.1")

puts "Prompt One - Poem of the Day\n"
response = chat.ask_prompt(prompt_one)
puts response.content

puts "\n\nPrompt Two - Greeting\n"
response = chat.ask_prompt(prompt_two, arguments: { name: "John" })
puts response.content
