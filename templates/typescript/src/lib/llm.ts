import { anthropic } from "@ai-sdk/anthropic";
import { openai } from "@ai-sdk/openai";
import { createOpenAICompatible } from "@ai-sdk/openai-compatible";
import { generateText, type LanguageModel } from "ai";
import { env } from "@/env";

/**
 * Single entry point for LLM calls. Models are written "provider:model-id",
 * e.g. "anthropic:claude-sonnet-5-5", "openai:gpt-5.1", or "ollama:qwen3:8b" for a
 * local model served by Ollama at OLLAMA_BASE_URL.
 */
export function resolveModel(id: string = env().DEFAULT_MODEL): LanguageModel {
  const [provider, ...rest] = id.split(":");
  const name = rest.join(":");
  if (!name)
    throw new Error(`Model id must look like "provider:model", got "${id}"`);
  switch (provider) {
    case "anthropic":
      return anthropic(name);
    case "openai":
      return openai(name);
    case "ollama":
      return createOpenAICompatible({
        name: "ollama",
        baseURL: env().OLLAMA_BASE_URL,
      })(name);
    default:
      throw new Error(`Unknown model provider "${provider}"`);
  }
}

export interface CompleteOptions {
  system?: string;
  model?: string;
  /** Name shown in Langfuse traces. */
  functionId?: string;
}

export async function complete(
  prompt: string,
  options: CompleteOptions = {},
): Promise<string> {
  const { text } = await generateText({
    model: resolveModel(options.model),
    system: options.system,
    prompt,
    telemetry: { functionId: options.functionId ?? "complete" },
  });
  return text;
}
