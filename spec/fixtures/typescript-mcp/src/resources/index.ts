import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { setupTextResources } from "./text.js";
import { setupMediaResources } from "./media.js";
import { setupTemplateResources } from "./templates.js";

export function setupResources(server: McpServer) {
  // Setup different categories of resources
  setupTextResources(server);
  setupMediaResources(server);
  setupTemplateResources(server);
}
