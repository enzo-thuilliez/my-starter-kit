import { z } from "zod";

/**
 * Server-side environment, validated once on first use.
 * Fails fast with a readable message when a required variable is missing.
 * Set SKIP_ENV_VALIDATION=1 for builds and CI jobs that do not call models.
 */
const schema = z.object({
  NODE_ENV: z
    .enum(["development", "test", "production"])
    .default("development"),
  DEFAULT_MODEL: z.string().default("anthropic:claude-sonnet-5-5"),
  ANTHROPIC_API_KEY: z.string().min(1).optional(),
  OPENAI_API_KEY: z.string().min(1).optional(),
  OLLAMA_BASE_URL: z.url().default("http://localhost:11434/v1"),
  LANGFUSE_PUBLIC_KEY: z.string().optional(),
  LANGFUSE_SECRET_KEY: z.string().optional(),
  LANGFUSE_BASE_URL: z.url().optional(),
});

export type Env = z.infer<typeof schema>;

let cached: Env | undefined;

export function env(): Env {
  if (cached) return cached;
  const parsed = schema.safeParse(process.env);
  if (!parsed.success) {
    if (process.env.SKIP_ENV_VALIDATION === "1") return schema.parse({});
    throw new Error(
      `Invalid environment variables:\n${z.prettifyError(parsed.error)}`,
    );
  }
  cached = parsed.data;
  return cached;
}
