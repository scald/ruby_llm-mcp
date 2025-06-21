import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";

export function setupSimplePrompts(server: McpServer) {
  server.prompt(
    "say_hello",
    "This is a simple prompt that will say hello",
    async () => ({
      messages: [
        {
          role: "user",
          content: {
            type: "text",
            text: "Hello, how are you?",
          },
        },
      ],
    })
  );

  server.prompt(
    "multiple_messages",
    "This is a simple prompt that will say hello with a name",
    async () => ({
      messages: [
        {
          role: "assistant",
          content: {
            type: "text",
            text: "You are great at saying hello, the best in the world at it.",
          },
        },
        {
          role: "user",
          content: {
            type: "text",
            text: "Hello, how are you?",
          },
        },
      ],
    })
  );

  server.prompt("poem_of_the_day", "Generates a poem of the day", async () => ({
    messages: [
      {
        role: "user",
        content: {
          type: "text",
          text: "Can you write me a beautiful poem about the current day?",
        },
      },
    ],
  }));
}
