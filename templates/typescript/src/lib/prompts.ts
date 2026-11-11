import { readFileSync } from "node:fs";
import path from "node:path";

/**
 * Versioned prompts, kept out of the code.
 *
 * Each prompt lives in `src/prompts/<name>/v<N>.md` with plain `{{var}}` placeholders
 * (no logic, so promptfoo renders the same files). Versions are immutable: to change a
 * prompt, add `v<N+1>.md`, evaluate it against the current one with promptfoo, then bump
 * the version where the prompt is used.
 */
export const PROMPTS_DIR = path.join(process.cwd(), "src", "prompts");

const PLACEHOLDER = /\{\{\s*(\w+)\s*\}\}/g;
const cache = new Map<string, string>();

export class PromptError extends Error {}

export function loadPrompt(name: string, version: number): string {
  const file = path.join(PROMPTS_DIR, name, `v${version}.md`);
  const cached = cache.get(file);
  if (cached !== undefined) return cached;
  let text: string;
  try {
    text = readFileSync(file, "utf8");
  } catch {
    throw new PromptError(
      `No prompt "${name}" version ${version} (expected ${file})`,
    );
  }
  cache.set(file, text);
  return text;
}

export function renderPrompt(
  name: string,
  version: number,
  variables: Record<string, string>,
): string {
  const template = loadPrompt(name, version);
  const needed = new Set(
    Array.from(template.matchAll(PLACEHOLDER), (m) => m[1]),
  );
  const missing = [...needed].filter((key) => !(key in variables)).sort();
  if (missing.length > 0) {
    throw new PromptError(
      `Prompt "${name}" v${version} needs ${missing.join(", ")}`,
    );
  }
  return template.replace(PLACEHOLDER, (_, key: string) => variables[key]);
}
