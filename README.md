# RubyLLM::MCP

Aiming to make using MCP with RubyLLM as easy as possible.

This project is a Ruby client for the [Model Context Protocol (MCP)](https://modelcontextprotocol.io/), designed to work seamlessly with [RubyLLM](https://github.com/crmne/ruby_llm). This gem enables Ruby applications to connect to MCP servers and use their tools, resources and prompts as part of LLM conversations.

**Note:** This project is still under development and the API is subject to change.

## Features

- 🔌 **Multiple Transport Types**: Support for SSE (Server-Sent Events), Streamable HTTP, and stdio transports
- 🛠️ **Tool Integration**: Automatically converts MCP tools into RubyLLM-compatible tools
- 📄 **Resource Management**: Access and include MCP resources (files, data) and resource templates in conversations
- 🎯 **Prompt Integration**: Use predefined MCP prompts with arguments for consistent interactions
- 🔄 **Real-time Communication**: Efficient bidirectional communication with MCP servers
- 🎨 **Enhanced Chat Interface**: Extended RubyLLM chat methods for seamless MCP integration
- 📚 **Simple API**: Easy-to-use interface that integrates seamlessly with RubyLLM

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'ruby_llm-mcp'
```

And then execute:

```bash
bundle install
```

Or install it yourself as:

```bash
gem install ruby_llm-mcp
```

## Usage

### Basic Setup

First, configure your RubyLLM client and create an MCP connection:

```ruby
require 'ruby_llm/mcp'

# Configure RubyLLM
RubyLLM.configure do |config|
  config.openai_api_key = "your-api-key"
end

# Connect to an MCP server via SSE
client = RubyLLM::MCP.client(
  name: "my-mcp-server",
  transport_type: :sse,
  config: {
    url: "http://localhost:9292/mcp/sse"
  }
)

# Or connect via stdio
client = RubyLLM::MCP.client(
  name: "my-mcp-server",
  transport_type: :stdio,
  config: {
    command: "node",
    args: ["path/to/mcp-server.js"],
    env: { "NODE_ENV" => "production" }
  }
)

# Or connect via streamable HTTP
client = RubyLLM::MCP.client(
  name: "my-mcp-server",
  transport_type: :streamable,
  config: {
    url: "http://localhost:8080/mcp",
    headers: { "Authorization" => "Bearer your-token" }
  }
)
```

### Using MCP Tools with RubyLLM

```ruby
# Get available tools from the MCP server
tools = client.tools
puts "Available tools:"
tools.each do |tool|
  puts "- #{tool.name}: #{tool.description}"
end

# Create a chat session with MCP tools
chat = RubyLLM.chat(model: "gpt-4")
chat.with_tools(*client.tools)

# Ask a question that will use the MCP tools
response = chat.ask("Can you help me search for recent files in my project?")
puts response
```

### Support Complex Parameters

If you want to support complex parameters, like an array of objects it currently requires a patch to RubyLLM itself. This is planned to be temporary until the RubyLLM is updated.

```ruby
RubyLLM::MCP.support_complex_parameters!
```

### Streaming Responses with Tool Calls

```ruby
chat = RubyLLM.chat(model: "gpt-4")
chat.with_tools(*client.tools)

chat.ask("Analyze my project structure") do |chunk|
  if chunk.tool_call?
    chunk.tool_calls.each do |key, tool_call|
      puts "\n🔧 Using tool: #{tool_call.name}"
    end
  else
    print chunk.content
  end
end
```

### Manual Tool Execution

You can also execute MCP tools directly:

```ruby
# Execute a specific tool
result = client.execute_tool(
  name: "search_files",
  parameters: {
    query: "*.rb",
    directory: "/path/to/search"
  }
)

puts result
```

### Working with Resources

MCP servers can provide access to resources - structured data that can be included in conversations. Resources come in two types: normal resources and resource templates.

#### Normal Resources

```ruby
# Get available resources from the MCP server
resources = client.resources
puts "Available resources:"
resources.each do |name, resource|
  puts "- #{name}: #{resource.description}"
end

# Access a specific resource
file_resource = resources["project_readme"]
content = file_resource.content
puts "Resource content: #{content}"

# Include a resource in a chat conversation for reference with an LLM
chat = RubyLLM.chat(model: "gpt-4")
chat.with_resource(file_resource)

# Or add a resource directly to the conversation
file_resource.include(chat)

response = chat.ask("Can you summarize this README file?")
puts response
```

#### Resource Templates

Resource templates are parameterized resources that can be dynamically configured:

```ruby
# Get available resource templates
templates = client.resource_templates
log_template = templates["application_logs"]

# Use a template with parameters
chat = RubyLLM.chat(model: "gpt-4")
chat.with_resource(log_template, arguments: {
  date: "2024-01-15",
  level: "error"
})

response = chat.ask("What errors occurred on this date?")
puts response

# You can also get templated content directly
content = log_template.content(arguments: {
  date: "2024-01-15",
  level: "error"
})
puts content
```

#### Resource Argument Completion

For resource templates, you can get suggested values for arguments:

```ruby
template = client.resource_templates["user_profile"]

# Search for possible values for a specific argument
suggestions = template.arguments_search("username", "john")
puts "Suggested usernames:"
suggestions.arg_values.each do |value|
  puts "- #{value}"
end
puts "Total matches: #{suggestions.total}"
puts "Has more: #{suggestions.has_more}"
```

### Working with Prompts

MCP servers can provide predefined prompts that can be used in conversations:

```ruby
# Get available prompts from the MCP server
prompts = client.prompts
puts "Available prompts:"
prompts.each do |name, prompt|
  puts "- #{name}: #{prompt.description}"
  prompt.arguments.each do |arg|
    puts "  - #{arg.name}: #{arg.description} (required: #{arg.required})"
  end
end

# Use a prompt in a conversation
greeting_prompt = prompts["daily_greeting"]
chat = RubyLLM.chat(model: "gpt-4")

# Method 1: Ask prompt directly
response = chat.ask_prompt(greeting_prompt, arguments: { name: "Alice", time: "morning" })
puts response

# Method 2: Add prompt to chat and then ask
chat.with_prompt(greeting_prompt, arguments: { name: "Alice", time: "morning" })
response = chat.ask("Continue with the greeting")
```

### Combining Resources, Prompts, and Tools

You can combine all MCP features for powerful conversations:

```ruby
client = RubyLLM::MCP.client(
  name: "development-assistant",
  transport_type: :sse,
  config: { url: "http://localhost:9292/mcp/sse" }
)

chat = RubyLLM.chat(model: "gpt-4")

# Add tools for capabilities
chat.with_tools(*client.tools)

# Add resources for context
chat.with_resource(client.resources["project_structure"])
chat.with_resource(
  client.resource_templates["recent_commits"],
  arguments: { days: 7 }
)

# Add prompts for guidance
chat.with_prompt(
  client.prompts["code_review_checklist"],
  arguments: { focus: "security" }
)

# Now ask for analysis
response = chat.ask("Please review the recent commits using the checklist and suggest improvements")
puts response
```

## Transport Types

### SSE (Server-Sent Events)

Best for web-based MCP servers or when you need HTTP-based communication:

```ruby
client = RubyLLM::MCP.client(
  name: "web-mcp-server",
  transport_type: :sse,
  config: {
    url: "https://your-mcp-server.com/mcp/sse"
  }
)
```

### Streamable HTTP

Best for HTTP-based MCP servers that support streaming responses:

```ruby
client = RubyLLM::MCP.client(
  name: "streaming-mcp-server",
  transport_type: :streamable,
  config: {
    url: "https://your-mcp-server.com/mcp",
    headers: { "Authorization" => "Bearer your-token" }
  }
)
```

### Stdio

Best for local MCP servers or command-line tools:

```ruby
client = RubyLLM::MCP.client(
  name: "local-mcp-server",
  transport_type: :stdio,
  config: {
    command: "python",
    args: ["-m", "my_mcp_server"],
    env: { "DEBUG" => "1" }
  }
)
```

## Configuration Options

- `name`: A unique identifier for your MCP client
- `transport_type`: Either `:sse`, `:streamable`, or `:stdio`
- `request_timeout`: Timeout for requests in milliseconds (default: 8000)
- `config`: Transport-specific configuration
  - For SSE: `{ url: "http://..." }`
  - For Streamable: `{ url: "http://...", headers: {...} }`
  - For stdio: `{ command: "...", args: [...], env: {...} }`

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Examples

Check out the `examples/` directory for more detailed usage examples:

- `examples/test_local_mcp.rb` - Complete example with SSE transport

## Contributing

We welcome contributions! Bug reports and pull requests are welcome on GitHub at https://github.com/patvice/ruby_llm-mcp.

## License

Released under the MIT License.
