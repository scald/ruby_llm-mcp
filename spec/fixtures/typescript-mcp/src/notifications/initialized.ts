import { Server } from "@modelcontextprotocol/sdk/server/index.js";
import { InitializedNotificationSchema } from "@modelcontextprotocol/sdk/types.js";

export function setupInitializedNotification(server: Server) {
  // Handle the notifications/initialized notification from the client
  server.setNotificationHandler(
    InitializedNotificationSchema,
    async (notification) => {
      console.log("=== CLIENT INITIALIZED NOTIFICATION ===");
      console.log("Client has completed initialization and is ready");
      console.log("Notification details:", notification);

      // The server can now perform any post-initialization setup
      // This is where you can:
      // - Start background tasks
      // - Send initial notifications to the client
      // - Perform any client-specific initialization

      console.log("Server acknowledges client initialization complete");
    }
  );
}
