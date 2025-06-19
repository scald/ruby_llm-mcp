import {
  McpServer,
  ResourceTemplate,
} from "@modelcontextprotocol/sdk/server/mcp.js";
import { readFile } from "node:fs/promises";

async function getFileContents(path: string) {
  const filepath = path.replace("file://", "");
  console.log(`Reading file: ${filepath}`);
  const content = await readFile(`./resources/${filepath}`, "utf-8");
  return content;
}

export function setupResources(server: McpServer) {
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
    async (uri, { name }) => ({
      contents: [
        {
          uri: uri.href,
          text: `Hello, ${name}!`,
        },
      ],
    })
  );

  server.resource("test.txt", "file://test.txt/", async (uri) => {
    const content = await getFileContents("test.txt");
    return {
      contents: [
        {
          uri: uri.href,
          text: content,
        },
      ],
    };
  });

  server.resource("second_file.txt", "file://second-file.txt/", async (uri) => {
    const content = await getFileContents("second-file.txt");
    return {
      contents: [
        {
          uri: uri.href,
          text: content,
        },
      ],
    };
  });

  server.resource("my.md", "file://my.md/", async (uri) => {
    const content = await getFileContents("my.md");
    return {
      contents: [
        {
          uri: uri.href,
          text: content,
        },
      ],
    };
  });
}
