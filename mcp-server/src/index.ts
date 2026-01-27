#!/usr/bin/env node

import { Server } from "@modelcontextprotocol/sdk/server/index.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import {
  CallToolRequestSchema,
  ListToolsRequestSchema,
} from "@modelcontextprotocol/sdk/types.js";

const COMPANION_PORT = 52532;
const COMPANION_URL = `http://localhost:${COMPANION_PORT}`;

let heartbeatInterval: NodeJS.Timeout | null = null;

interface CompanionResult {
  success: boolean;
  error?: string;
}

async function sendToCompanion(endpoint: string, body?: object): Promise<CompanionResult> {
  try {
    const response = await fetch(`${COMPANION_URL}${endpoint}`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: body ? JSON.stringify(body) : undefined,
    });

    return response.ok
      ? { success: true }
      : { success: false, error: `HTTP ${response.status}` };
  } catch (error) {
    return {
      success: false,
      error: error instanceof Error ? error.message : "Unknown error",
    };
  }
}

function setState(state: string, duration?: number): Promise<CompanionResult> {
  return sendToCompanion("/state", { state, duration });
}

function notify(message?: string, duration?: number): Promise<CompanionResult> {
  return sendToCompanion("/notify", { message, duration });
}

function sendHeartbeat(): Promise<CompanionResult> {
  return sendToCompanion("/heartbeat");
}

function startHeartbeat(): void {
  if (heartbeatInterval) return;
  sendHeartbeat();
  heartbeatInterval = setInterval(sendHeartbeat, 10000);
}

function stopHeartbeat(): void {
  if (heartbeatInterval) {
    clearInterval(heartbeatInterval);
    heartbeatInterval = null;
  }
}

const server = new Server(
  { name: "claude-companion", version: "1.0.0" },
  { capabilities: { tools: {} } }
);

const emptySchema = { type: "object" as const, properties: {}, required: [] as string[] };

function durationSchema(description: string, defaultValue: number) {
  return {
    type: "object" as const,
    properties: {
      duration: { type: "number" as const, description, default: defaultValue },
    },
    required: [] as string[],
  };
}

const tools = [
  { name: "companion_thinking", description: "Set the companion to thinking state. Use when processing or analyzing something.", inputSchema: emptySchema },
  { name: "companion_working", description: "Set the companion to working state. Use when actively doing a task.", inputSchema: emptySchema },
  { name: "companion_attention", description: "Get the user's attention. Companion will bounce and make a sound. Use when you need user input or have important information.", inputSchema: durationSchema("How long to show attention state (seconds)", 3) },
  { name: "companion_success", description: "Show success/celebration. Companion will look happy. Use when completing a task successfully.", inputSchema: durationSchema("How long to celebrate (seconds)", 2) },
  { name: "companion_error", description: "Show concern/error state. Companion will look worried. Use when something went wrong.", inputSchema: durationSchema("How long to show error state (seconds)", 2) },
  { name: "companion_idle", description: "Return companion to idle/default state.", inputSchema: emptySchema },
  { name: "companion_listening", description: "Set companion to listening state. Use when waiting for user input.", inputSchema: emptySchema },
  { name: "companion_wave", description: "Make the companion wave hello! A friendly greeting.", inputSchema: emptySchema },
];

server.setRequestHandler(ListToolsRequestSchema, async () => ({ tools }));

server.setRequestHandler(CallToolRequestSchema, async (request) => {
  const { name, arguments: args } = request.params;
  const duration = (args?.duration as number | undefined);

  const toolHandlers: Record<string, () => Promise<CompanionResult>> = {
    companion_thinking: () => setState("thinking"),
    companion_working: () => setState("working"),
    companion_attention: () => notify(undefined, duration ?? 3),
    companion_success: () => setState("success", duration ?? 2),
    companion_error: () => setState("error", duration ?? 2),
    companion_idle: () => setState("idle"),
    companion_listening: () => setState("listening"),
    companion_wave: () => setState("waving", 2),
  };

  const handler = toolHandlers[name];
  if (!handler) {
    return {
      content: [{ type: "text", text: `Unknown tool: ${name}` }],
      isError: true,
    };
  }

  const result = await handler();

  return result.success
    ? { content: [{ type: "text", text: `Companion state updated: ${name}` }] }
    : {
        content: [{ type: "text", text: `Failed to update companion: ${result.error}. Is the companion app running?` }],
        isError: true,
      };
});

async function handleShutdown(): Promise<void> {
  stopHeartbeat();
  await sendToCompanion("/sleep");
  process.exit(0);
}

async function main(): Promise<void> {
  startHeartbeat();

  const transport = new StdioServerTransport();
  await server.connect(transport);
  await setState("idle");

  process.on("SIGINT", handleShutdown);
  process.on("SIGTERM", handleShutdown);
}

main().catch(console.error);
