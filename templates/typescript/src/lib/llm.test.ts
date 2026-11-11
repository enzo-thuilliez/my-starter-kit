import { beforeEach, describe, expect, it, vi } from "vitest";

const generateText = vi.fn();
vi.mock("ai", () => ({ generateText }));
vi.mock("@ai-sdk/anthropic", () => ({
  anthropic: (name: string) => ({ provider: "anthropic", name }),
}));
vi.mock("@ai-sdk/openai", () => ({
  openai: (name: string) => ({ provider: "openai", name }),
}));
vi.mock("@ai-sdk/openai-compatible", () => ({
  createOpenAICompatible:
    ({ name, baseURL }: { name: string; baseURL: string }) =>
    (model: string) => ({ provider: name, name: model, baseURL }),
}));

const { complete, resolveModel } = await import("./llm");

describe("resolveModel", () => {
  it("routes by provider prefix", () => {
    expect(resolveModel("openai:gpt-5.1")).toEqual({
      provider: "openai",
      name: "gpt-5.1",
    });
    expect(resolveModel("anthropic:claude-sonnet-5-5")).toEqual({
      provider: "anthropic",
      name: "claude-sonnet-5-5",
    });
  });

  it("sends local models to the Ollama server", () => {
    expect(resolveModel("ollama:qwen3:8b")).toEqual({
      provider: "ollama",
      name: "qwen3:8b",
      baseURL: "http://localhost:11434/v1",
    });
  });

  it("rejects malformed ids", () => {
    expect(() => resolveModel("gpt-5.1")).toThrow(/provider:model/);
    expect(() => resolveModel("mistral:large")).toThrow(
      /Unknown model provider/,
    );
  });
});

describe("complete", () => {
  beforeEach(() => generateText.mockReset());

  it("passes prompt, system and telemetry name to the SDK", async () => {
    generateText.mockResolvedValue({ text: "hi" });
    await expect(
      complete("hello", { system: "be brief", model: "openai:gpt-5.1" }),
    ).resolves.toBe("hi");
    expect(generateText).toHaveBeenCalledWith(
      expect.objectContaining({
        prompt: "hello",
        system: "be brief",
        telemetry: { functionId: "complete" },
      }),
    );
  });
});
