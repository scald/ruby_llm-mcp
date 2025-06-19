import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { z } from "zod";

export function setupPrompts(server: McpServer) {
  // Prompt that takes no arguments
  server.prompt(
    "poem_of_the_day",
    "Generate the poem of the day",
    {},
    async () => ({
      messages: [
        {
          role: "user",
          content: {
            type: "text",
            text: "Can you create a poem for of the day me? Make sure say what style of poem you are writing.",
          },
        },
      ],
    })
  );

  // Prompt that takes a name argument
  server.prompt(
    "greeting",
    "Generates a greeting in a random language",
    {
      name: z.string().describe("Name of the person I am to greet"),
    },
    async ({ name }) => {
      const languages = [
        "English",
        "Spanish",
        "French",
        "German",
        "Italian",
        "Portuguese",
        "Russian",
        "Chinese",
        "Japanese",
        "Korean",
      ];
      const randomLanguage =
        languages[Math.floor(Math.random() * languages.length)];
      const greeting = `Can you create a greeting for ${name} in ${randomLanguage}?`;

      return {
        messages: [
          {
            role: "user",
            content: {
              type: "text",
              text: greeting,
            },
          },
        ],
      };
    }
  );
}
