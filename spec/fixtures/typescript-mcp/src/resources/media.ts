import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { readFile } from "node:fs/promises";

export function setupMediaResources(server: McpServer) {
  server.resource(
    "dog.jpeg",
    "file://dog.jpeg/",
    {
      name: "dog.jpeg",
      description: "A picture of a dog",
      mimeType: "image/jpeg",
    },
    async (uri) => {
      try {
        const imageBuffer = await readFile(
          "./spec/fixtures/typescript-mcp/resources/dog.jpeg"
        );
        const base64Image = imageBuffer.toString("base64");

        return {
          contents: [
            {
              uri: uri.href,
              blob: base64Image,
              mimeType: "image/jpeg",
            },
          ],
        };
      } catch (error) {
        const errorMessage =
          error instanceof Error ? error.message : String(error);
        return {
          contents: [
            {
              uri: uri.href,
              text: `Error reading dog image: ${errorMessage}`,
            },
          ],
        };
      }
    }
  );

  server.resource(
    "jackhammer.wav",
    "file://jackhammer.wav/",
    {
      name: "jackhammer.wav",
      description: "A jackhammer audio file",
      mimeType: "audio/wav",
    },
    async (uri) => {
      try {
        const audioBuffer = await readFile(
          "./spec/fixtures/typescript-mcp/resources/jackhammer.wav"
        );
        const base64Audio = audioBuffer.toString("base64");

        return {
          contents: [
            {
              uri: uri.href,
              blob: base64Audio,
              mimeType: "audio/wav",
            },
          ],
        };
      } catch (error) {
        const errorMessage =
          error instanceof Error ? error.message : String(error);
        return {
          contents: [
            {
              uri: uri.href,
              text: `Error reading jackhammer audio: ${errorMessage}`,
            },
          ],
        };
      }
    }
  );
}
