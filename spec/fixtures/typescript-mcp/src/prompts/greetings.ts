import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { completable } from "@modelcontextprotocol/sdk/server/completable.js";
import { z } from "zod";

export function setupGreetingPrompts(server: McpServer) {
  server.prompt(
    "specific_language_greeting",
    "Generates a greeting in a specific language",
    {
      name: z.string().describe("Name of the person I am to greet"),
      language: completable(
        z.string().describe("Name the language you are to greet in"),
        (name: string) => {
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

          return languages.filter((language) =>
            language.toLowerCase().includes(name.toLowerCase())
          );
        }
      ),
    },
    async ({ name, language }) => {
      const greeting = `Can you create a greeting for ${name} in ${language}?`;

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
