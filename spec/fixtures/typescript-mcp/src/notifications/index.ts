import { Server } from "@modelcontextprotocol/sdk/server/index.js";
import { setupInitializedNotification } from "./initialized.js";

export function setupNotifications(server: Server) {
  console.log("=== SETTING UP NOTIFICATIONS ===");

  // Setup all notification handlers
  setupInitializedNotification(server);

  console.log("Notification handlers registered successfully");
}
