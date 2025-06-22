import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { setupSimplePrompts } from "./simple.js";
import { setupGreetingPrompts } from "./greetings.js";

export function setupPrompts(server: McpServer) {
  // Setup different categories of prompts
  setupSimplePrompts(server);
  setupGreetingPrompts(server);
}
