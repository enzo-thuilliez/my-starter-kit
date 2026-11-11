# TypeScript stack — notes for /kit:kickoff

Not copied into the project. Read by the skill. This template is an **overlay**:
create-next-app generates the base app, then these files are copied on top.

## Scaffold (run before copying the overlay)

```bash
# 1. Generate the base app in a temp dir (create-next-app refuses non-empty dirs;
#    the name must be a valid npm package name, so no leading dot)
CI=1 pnpm create next-app@latest kit-tmp-web --ts --app --tailwind --biome --src-dir \
  --import-alias "@/*" --use-pnpm --no-agents-md --no-react-compiler --disable-git --yes
# 2. Move it in without overwriting the kit's files (README, .gitignore, AGENTS.md...)
cp -a --update=none kit-tmp-web/. ./ && rm -rf kit-tmp-web
# 3. Allow the native builds pnpm blocks by default
printf '  protobufjs: true\n  esbuild: true\n' >> pnpm-workspace.yaml   # under allowBuilds:
# 4. Dependencies
pnpm add ai @ai-sdk/anthropic @ai-sdk/openai zod \
  @langfuse/otel @langfuse/vercel-ai-sdk @opentelemetry/sdk-node
pnpm add -D vitest vite-tsconfig-paths @playwright/test
# 5. UI kit (non-interactive, default style)
pnpm dlx shadcn@latest init --yes --defaults
```

Then copy the overlay (stack files overwrite common ones; `.gitignore.append` is appended),
and merge these scripts into `package.json`:

```json
"typecheck": "tsc --noEmit",
"test": "vitest run",
"test:watch": "vitest",
"test:e2e": "playwright test",
"evals": "promptfoo eval -c evals/promptfooconfig.yaml"
```

Verify: `pnpm lint && pnpm typecheck && pnpm test && SKIP_ENV_VALIDATION=1 pnpm build`.

## AGENTS.md values

| Task | Command |
|---|---|
| Install | `pnpm install` |
| Dev server | `pnpm dev` |
| Lint + format | `pnpm lint` (fix: `pnpm exec biome check --write`) |
| Type-check | `pnpm typecheck` |
| Tests | `pnpm test` (e2e: `pnpm test:e2e`) |
| Evals | `pnpm evals` |

Stack: Next.js (App Router, src/), React, TypeScript, pnpm, Tailwind + shadcn/ui, Biome,
Vercel AI SDK (Anthropic + OpenAI), Zod env validation, Langfuse via OpenTelemetry,
Vitest, Playwright, promptfoo.

Security checks: CI runs `pnpm audit --prod --audit-level high` (job `audit`, part of
`ci-pass`). Accepted advisories go under `auditConfig.ignoreGhsas` in `pnpm-workspace.yaml`.

Conventions: all LLM calls go through `src/lib/llm.ts` (`complete()` / `resolveModel()`);
env vars only through `env()` from `src/env.ts`; unit tests mock `ai`, never call a real model;
UI components come from shadcn (`pnpm dlx shadcn@latest add <component>`).

## Options to drop

- No LLM: delete `src/lib/llm*`, `src/app/api/ask`, `src/instrumentation.ts`, `evals/`,
  `evals.yml`, and the ai/@ai-sdk/@langfuse/@opentelemetry deps.

## Monorepo (apps/web)

Scaffold and copy into `apps/web/`. In `ci.yml` and `evals.yml` add
`defaults.run.working-directory: apps/web`, set `cache-dependency-path: apps/web/pnpm-lock.yaml`,
add `on.pull_request.paths: [apps/web/**]`; in `dependabot.yml` use `directory: /apps/web`
for npm; in `release-please-config.json` use the key `apps/web`.
