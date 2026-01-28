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

function setStatus(message?: string): Promise<CompanionResult> {
  return sendToCompanion("/status", { message });
}

function showBubble(emoji?: string, text?: string, type?: string, duration?: number): Promise<CompanionResult> {
  return sendToCompanion("/bubble", { emoji, text, type, duration });
}

function showParticles(effect: string, duration?: number): Promise<CompanionResult> {
  return sendToCompanion("/particles", { effect, duration });
}

function queueNotification(message: string, emoji?: string, priority?: string): Promise<CompanionResult> {
  return sendToCompanion("/notification", { message, emoji, priority });
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
  { name: "code-companion", version: "1.0.0" },
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

const statusSchema = {
  type: "object" as const,
  properties: {
    status: { type: "string" as const, description: "Brief description of what you're doing (shown on hover)" },
  },
  required: [] as string[],
};

const tools = [
  { name: "companion_thinking", description: "Set the companion to thinking state. Use when processing or analyzing something.", inputSchema: statusSchema },
  { name: "companion_working", description: "Set the companion to working state. Use when actively doing a task.", inputSchema: statusSchema },
  { name: "companion_attention", description: "Get the user's attention. Companion will bounce and make a sound. Use when you need user input or have important information.", inputSchema: durationSchema("How long to show attention state (seconds)", 3) },
  { name: "companion_success", description: "Show success/celebration. Companion will look happy. Use when completing a task successfully.", inputSchema: durationSchema("How long to celebrate (seconds)", 2) },
  { name: "companion_error", description: "Show concern/error state. Companion will look worried. Use when something went wrong.", inputSchema: durationSchema("How long to show error state (seconds)", 2) },
  { name: "companion_idle", description: "Return companion to idle/default state.", inputSchema: emptySchema },
  { name: "companion_listening", description: "Set companion to listening state. Use when waiting for user input.", inputSchema: emptySchema },
  { name: "companion_wave", description: "Make the companion wave hello! A friendly greeting.", inputSchema: emptySchema },
  {
    name: "companion_status",
    description: "Set a status message shown as tooltip when hovering over the companion. Use to show what you're currently working on.",
    inputSchema: {
      type: "object" as const,
      properties: {
        message: { type: "string" as const, description: "Status message to display (or empty to clear)" },
      },
      required: [] as string[],
    }
  },
  {
    name: "companion_bubble",
    description: "Show a speech or thought bubble with emoji or text.",
    inputSchema: {
      type: "object" as const,
      properties: {
        emoji: { type: "string" as const, description: "Single emoji to show in bubble" },
        text: { type: "string" as const, description: "Short text to show (if no emoji)" },
        type: { type: "string" as const, enum: ["speech", "thought"], description: "Bubble style (default: speech)" },
        duration: { type: "number" as const, description: "How long to show (seconds)", default: 3 },
      },
      required: [] as string[],
    }
  },
  {
    name: "companion_particles",
    description: "Show particle effects around the companion.",
    inputSchema: {
      type: "object" as const,
      properties: {
        effect: { type: "string" as const, enum: ["confetti", "hearts", "sparkles", "rainCloud"], description: "Particle effect type" },
        duration: { type: "number" as const, description: "How long to show (seconds)", default: 2 },
      },
      required: ["effect"],
    }
  },
  {
    name: "companion_notify",
    description: "Queue a notification to be shown. Notifications stack with a badge count.",
    inputSchema: {
      type: "object" as const,
      properties: {
        message: { type: "string" as const, description: "Notification message" },
        emoji: { type: "string" as const, description: "Optional emoji" },
        priority: { type: "string" as const, enum: ["low", "normal", "high"], description: "Priority level (default: normal)" },
      },
      required: ["message"],
    }
  },
];

server.setRequestHandler(ListToolsRequestSchema, async () => ({ tools }));

server.setRequestHandler(CallToolRequestSchema, async (request) => {
  const { name, arguments: args } = request.params;
  const duration = (args?.duration as number | undefined);

  const message = args?.message as string | undefined;
  const status = args?.status as string | undefined;
  const emoji = args?.emoji as string | undefined;
  const text = args?.text as string | undefined;
  const bubbleType = args?.type as string | undefined;
  const effect = args?.effect as string | undefined;
  const priority = args?.priority as string | undefined;

  // Helper to set state and status together
  async function setStateWithStatus(state: string, defaultStatus?: string): Promise<CompanionResult> {
    const statusMsg = status || defaultStatus;
    if (statusMsg) {
      await setStatus(statusMsg);
    }
    return setState(state);
  }

  const toolHandlers: Record<string, () => Promise<CompanionResult>> = {
    companion_thinking: () => setStateWithStatus("thinking", "Thinking..."),
    companion_working: () => setStateWithStatus("working", "Working..."),
    companion_attention: async () => { await setStatus("Needs attention"); return notify(undefined, duration ?? 3); },
    companion_success: async () => { await setStatus(null as any); return setState("success", duration ?? 2); },
    companion_error: async () => { await setStatus("Something went wrong"); return setState("error", duration ?? 2); },
    companion_idle: async () => { await setStatus(null as any); return setState("idle"); },
    companion_listening: () => setStateWithStatus("listening", "Waiting for input..."),
    companion_wave: async () => { await setStatus(null as any); return setState("waving", 2); },
    companion_status: () => setStatus(message),
    companion_bubble: () => showBubble(emoji, text, bubbleType, duration),
    companion_particles: () => showParticles(effect ?? "sparkles", duration),
    companion_notify: () => queueNotification(message ?? "", emoji, priority),
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
