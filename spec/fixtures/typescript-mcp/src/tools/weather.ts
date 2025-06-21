import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { z } from "zod";

export function setupWeatherTools(server: McpServer) {
  server.tool(
    "get_weather_from_locations",
    "Get the weather from a list of locations",
    { locations: z.array(z.string()) },
    async ({ locations }) => ({
      content: [
        { type: "text", text: `Weather for ${locations.join(", ")} is great!` },
      ],
    })
  );

  server.tool(
    "get_weather_from_geocode",
    "Get the weather from a list of locations",
    {
      geocode: z.object({
        latitude: z.number(),
        longitude: z.number(),
      }),
    },
    async ({ geocode }) => ({
      content: [
        {
          type: "text",
          text: `Weather for ${geocode.latitude}, ${geocode.longitude} is great!`,
        },
      ],
    })
  );
}
