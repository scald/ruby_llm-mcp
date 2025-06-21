import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { readFile } from "node:fs/promises";

async function getFileContents(path: string) {
  const filepath = path.replace("file://", "");
  const content = await readFile(
    `./spec/fixtures/typescript-mcp/resources/${filepath}`,
    "utf-8"
  );
  return content;
}

export function setupTextResources(server: McpServer) {
  server.resource(
    "test.txt",
    "file://test.txt/",
    {
      name: "test.txt",
      description: "A text file",
      mimeType: "text/plain",
    },
    async (uri) => {
      const content = await getFileContents("test.txt");
      return {
        contents: [
          {
            uri: uri.href,
            text: content,
          },
        ],
      };
    }
  );

  server.resource(
    "resource_without_metadata",
    "file://resource_without_metadata.txt/",
    async (uri) => {
      const content = await getFileContents("resource_without_metadata.txt");
      return {
        contents: [
          {
            uri: uri.href,
            text: content,
          },
        ],
      };
    }
  );

  server.resource(
    "second_file.txt",
    "file://second-file.txt/",
    {
      name: "second_file.txt",
      description: "A second text file",
      mimeType: "text/plain",
    },
    async (uri) => {
      const content = await getFileContents("second-file.txt");
      return {
        contents: [
          {
            uri: uri.href,
            text: content,
          },
        ],
      };
    }
  );

  server.resource(
    "my.md",
    "file://my.md/",
    {
      name: "my.md",
      description: "A markdown file",
      mimeType: "text/markdown",
    },
    async (uri) => {
      const content = await getFileContents("my.md");
      return {
        contents: [
          {
            uri: uri.href,
            text: content,
          },
        ],
      };
    }
  );
}
