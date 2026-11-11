import { readdirSync } from "node:fs";
import path from "node:path";
import { describe, expect, it } from "vitest";
import { PROMPTS_DIR, PromptError, renderPrompt } from "./prompts";

describe("renderPrompt", () => {
  it("fills placeholders", () => {
    const text = renderPrompt("ask", 1, { question: "What is 2 + 2?" });
    expect(text).toContain("What is 2 + 2?");
    expect(text).not.toContain("{{");
  });

  it("rejects a missing variable", () => {
    expect(() => renderPrompt("ask", 1, {})).toThrow(PromptError);
    expect(() => renderPrompt("ask", 1, {})).toThrow(/question/);
  });

  it("rejects an unknown version", () => {
    expect(() => renderPrompt("ask", 999, { question: "x" })).toThrow(
      /version 999/,
    );
  });

  it("names every prompt file v<N>.md", () => {
    for (const name of readdirSync(PROMPTS_DIR)) {
      for (const file of readdirSync(path.join(PROMPTS_DIR, name))) {
        expect(file).toMatch(/^v\d+\.md$/);
      }
    }
  });
});
