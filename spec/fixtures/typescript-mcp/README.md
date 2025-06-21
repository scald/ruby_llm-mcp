# MCP Streamable Server Test

A Model Context Protocol (MCP) server using Streamable HTTP transport to test Ruby MCP, following the patterns from the [official TypeScript SDK](https://github.com/modelcontextprotocol/typescript-sdk).

## Usage

### Development

```bash
# Install dependencies
bun install

# Start the server
bun start

# Start with auto-reload during development
bun run dev
```

The server will start on port 3005 (or the port specified in the `PORT` environment variable).

### Endpoints

- **MCP Protocol**: `http://localhost:3005/mcp` - Main MCP endpoint (supports GET, POST, DELETE)
- **Health Check**: `http://localhost:3005/health` - Server health status
