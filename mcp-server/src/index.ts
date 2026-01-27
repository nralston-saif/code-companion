#!/usr/bin/env node

import { Server } from "@modelcontextprotocol/sdk/server/index.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import {
  CallToolRequestSchema,
  ListToolsRequestSchema,
} from "@modelcontextprotocol/sdk/types.js";

const COMPANION_PORT = 52532;
const COMPANION_URL = `http://localhost:${COMPANION_PORT}`;

// Heartbeat interval to keep companion awake
let heartbeatInterval: NodeJS.Timeout | null = null;

async function sendToCompanion(
  endpoint: string,
  body?: object
): Promise<{ success: boolean; error?: string }> {
  try {
    const response = await fetch(`${COMPANION_URL}${endpoint}`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: body ? JSON.stringify(body) : undefined,
    });

    if (!response.ok) {
      return { success: false, error: `HTTP ${response.status}` };
    }

    return { success: true };
  } catch (error) {
    return {
      success: false,
      error: error instanceof Error ? error.message : "Unknown error",
    };
  }
}

async function setState(
  state: string,
  duration?: number
): Promise<{ success: boolean; error?: string }> {
  return sendToCompanion("/state", { state, duration });
}

async function notify(
  message?: string,
  duration?: number
): Promise<{ success: boolean; error?: string }> {
  return sendToCompanion("/notify", { message, duration });
}

async function sendHeartbeat(): Promise<void> {
  await sendToCompanion("/heartbeat");
}

function startHeartbeat(): void {
  if (heartbeatInterval) return;

  // Send immediate heartbeat
  sendHeartbeat();

  // Then every 10 seconds
  heartbeatInterval = setInterval(() => {
    sendHeartbeat();
  }, 10000);
}

function stopHeartbeat(): void {
  if (heartbeatInterval) {
    clearInterval(heartbeatInterval);
    heartbeatInterval = null;
  }
}

// Create the MCP server
const server = new Server(
  {
    name: "claude-companion",
    version: "1.0.0",
  },
  {
    capabilities: {
      tools: {},
    },
  }
);

// Define available tools
server.setRequestHandler(ListToolsRequestSchema, async () => {
  return {
    tools: [
      {
        name: "companion_thinking",
        description:
          "Set the companion to thinking state. Use when processing or analyzing something.",
        inputSchema: {
          type: "object",
          properties: {},
          required: [],
        },
      },
      {
        name: "companion_working",
        description:
          "Set the companion to working state. Use when actively doing a task.",
        inputSchema: {
          type: "object",
          properties: {},
          required: [],
        },
      },
      {
        name: "companion_attention",
        description:
          "Get the user's attention. Companion will bounce and make a sound. Use when you need user input or have important information.",
        inputSchema: {
          type: "object",
          properties: {
            duration: {
              type: "number",
              description: "How long to show attention state (seconds)",
              default: 3,
            },
          },
          required: [],
        },
      },
      {
        name: "companion_success",
        description:
          "Show success/celebration. Companion will look happy. Use when completing a task successfully.",
        inputSchema: {
          type: "object",
          properties: {
            duration: {
              type: "number",
              description: "How long to celebrate (seconds)",
              default: 2,
            },
          },
          required: [],
        },
      },
      {
        name: "companion_error",
        description:
          "Show concern/error state. Companion will look worried. Use when something went wrong.",
        inputSchema: {
          type: "object",
          properties: {
            duration: {
              type: "number",
              description: "How long to show error state (seconds)",
              default: 2,
            },
          },
          required: [],
        },
      },
      {
        name: "companion_idle",
        description: "Return companion to idle/default state.",
        inputSchema: {
          type: "object",
          properties: {},
          required: [],
        },
      },
      {
        name: "companion_listening",
        description:
          "Set companion to listening state. Use when waiting for user input.",
        inputSchema: {
          type: "object",
          properties: {},
          required: [],
        },
      },
      {
        name: "companion_wave",
        description: "Make the companion wave hello! A friendly greeting.",
        inputSchema: {
          type: "object",
          properties: {},
          required: [],
        },
      },
    ],
  };
});

// Handle tool calls
server.setRequestHandler(CallToolRequestSchema, async (request) => {
  const { name, arguments: args } = request.params;

  let result: { success: boolean; error?: string };

  switch (name) {
    case "companion_thinking":
      result = await setState("thinking");
      break;

    case "companion_working":
      result = await setState("working");
      break;

    case "companion_attention":
      result = await notify(undefined, (args?.duration as number) ?? 3);
      break;

    case "companion_success":
      result = await setState("success", (args?.duration as number) ?? 2);
      break;

    case "companion_error":
      result = await setState("error", (args?.duration as number) ?? 2);
      break;

    case "companion_idle":
      result = await setState("idle");
      break;

    case "companion_listening":
      result = await setState("listening");
      break;

    case "companion_wave":
      result = await setState("waving", 2);
      break;

    default:
      return {
        content: [{ type: "text", text: `Unknown tool: ${name}` }],
        isError: true,
      };
  }

  if (result.success) {
    return {
      content: [{ type: "text", text: `Companion state updated: ${name}` }],
    };
  } else {
    return {
      content: [
        {
          type: "text",
          text: `Failed to update companion: ${result.error}. Is the companion app running?`,
        },
      ],
      isError: true,
    };
  }
});

// Start the server
async function main() {
  // Start heartbeat to keep companion awake
  startHeartbeat();

  const transport = new StdioServerTransport();
  await server.connect(transport);

  // Set initial state to idle (wake up)
  await setState("idle");

  // Cleanup on exit
  process.on("SIGINT", async () => {
    stopHeartbeat();
    await sendToCompanion("/sleep");
    process.exit(0);
  });

  process.on("SIGTERM", async () => {
    stopHeartbeat();
    await sendToCompanion("/sleep");
    process.exit(0);
  });
}

main().catch(console.error);
