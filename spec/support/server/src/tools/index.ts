import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { z } from "zod";
import { readFile } from "node:fs/promises";

const messages: { channel: string; message: string }[] = [
  {
    channel: "general",
    message: "Hello, world!",
  },
  {
    channel: "general",
    message:
      "Welcome to the general channel! Feel free to share your thoughts and ideas here.",
  },
  {
    channel: "ruby",
    message:
      "Ruby is a great language for web development. It's easy to learn and has a large community.",
  },
];

async function listMessages(channel: string) {
  return messages
    .filter((message) => message.channel === channel)
    .map((message) => message.message)
    .join("\n");
}

let permission = "read";
const permissions = ["read", "write", "admin"];

async function upgradeAuthAndStoreToken(new_permission: string) {
  const previous = permission;
  if (!permissions.includes(new_permission)) {
    return { ok: false, err: "Invalid permission", previous: previous };
  }

  permission = new_permission;
  return { ok: true, err: null, previous: previous };
}

async function putMessage(channel: string, message: string) {
  messages.push({ channel, message });
  return message;
}

export function setupTools(server: McpServer) {
  server.tool(
    "add",
    "Addes two numbers together",
    { a: z.number(), b: z.number() },
    async ({ a, b }) => ({
      content: [{ type: "text", text: String(a + b) }],
    })
  );

  server.tool(
    "list_messages",
    { channel: z.string() },
    async ({ channel }) => ({
      content: [{ type: "text", text: await listMessages(channel) }],
    })
  );

  const putMessageTool = server.tool(
    "put_message",
    { channel: z.string(), message: z.string() },
    async ({ channel, message }) => ({
      content: [{ type: "text", text: await putMessage(channel, message) }],
    })
  );
  // Until we upgrade auth, `putMessage` is disabled (won't show up in listTools)
  putMessageTool.disable();

  const upgradeAuthTool = server.tool(
    "upgrade_auth",
    "Upgrade authentication permissions",
    { permission: z.enum(["read", "write"]) },
    // Any mutations here will automatically emit `listChanged` notifications
    async ({ permission }) => {
      const { ok, err, previous } = await upgradeAuthAndStoreToken(permission);
      if (!ok) return { content: [{ type: "text", text: `Error: ${err}` }] };

      // If we previously had read-only access, 'putMessage' is now available
      if (previous === "read") {
        putMessageTool.enable();
      } else if (previous === "write") {
        // If we've just upgraded to 'write' permissions, we can still call 'upgradeAuth'
        // but can only upgrade to 'admin'.
        upgradeAuthTool.update({
          paramsSchema: { permission: z.enum(["read", "write", "admin"]) }, // change validation rules
        });
      } else {
        // If we're now an admin, we no longer have anywhere to upgrade to, so fully remove that tool
        upgradeAuthTool.remove();
      }

      return {
        content: [
          { type: "text", text: `Upgraded from ${previous} to ${permission}` },
        ],
      };
    }
  );

  server.tool(
    "tool_error",
    "Returns an error",
    {
      shouldError: z.boolean().optional(),
    },
    async ({ shouldError }) => {
      if (shouldError) {
        const error = Error("Tool error");
        return {
          content: [
            {
              type: "text",
              text: `Error: ${error.message}`,
            },
          ],
          isError: true,
        };
      }

      return {
        content: [{ type: "text", text: "No error" }],
      };
    }
  );

  server.tool(
    "get_jackhammer_audio",
    "Returns the jackhammer audio file as a base64-encoded WAV",
    {},
    async () => {
      try {
        // Read the jackhammer audio file from resources
        const audioBuffer = await readFile("./resources/jackhammer.wav");

        // Convert to base64
        const base64Audio = audioBuffer.toString("base64");

        return {
          content: [
            {
              type: "audio",
              data: base64Audio,
              mimeType: "audio/wav",
            },
          ],
        };
      } catch (error) {
        const errorMessage =
          error instanceof Error ? error.message : String(error);
        return {
          content: [
            {
              type: "text",
              text: `Error reading jackhammer audio file: ${errorMessage}`,
            },
          ],
        };
      }
    }
  );

  server.tool(
    "get_dog_image",
    "Returns the dog image as a base64-encoded JPEG",
    {},
    async () => {
      try {
        // Read the dog image file from resources
        const imageBuffer = await readFile("./resources/dog.jpeg");

        // Convert to base64
        const base64Image = imageBuffer.toString("base64");

        return {
          content: [
            {
              type: "image",
              data: base64Image,
              mimeType: "image/jpeg",
            },
          ],
        };
      } catch (error) {
        const errorMessage =
          error instanceof Error ? error.message : String(error);
        return {
          content: [
            {
              type: "text",
              text: `Error reading dog image file: ${errorMessage}`,
            },
          ],
        };
      }
    }
  );
}
