import {
  McpServer,
  ResourceTemplate,
} from "@modelcontextprotocol/sdk/server/mcp.js";

export function setupTemplateResources(server: McpServer) {
  server.resource(
    "greeting",
    new ResourceTemplate("greeting://{name}", {
      list: undefined,
      complete: {
        name: async (value) => {
          const names = ["Alice", "Bob", "Charlie"];

          if (!value) {
            return names;
          }

          return names.filter((name) =>
            name.toLowerCase().includes(value.toLowerCase())
          );
        },
      },
    }),
    {
      name: "greeting",
      description: "A greeting resource",
      mimeType: "text/plain",
    },
    async (uri, { name }) => ({
      contents: [
        {
          uri: uri.href,
          text: `Hello, ${name}!`,
        },
      ],
    })
  );
}
