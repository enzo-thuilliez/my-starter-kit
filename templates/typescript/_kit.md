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

Eval gate: `evals.yml` runs the promptfoo suite on PRs that touch the prompts, the LLM layer
or the evals, compares it with the last run on `main` (kept as the `eval-baseline` artifact)
and posts the result on the PR. It fails when the pass rate drops by more than `EVAL_MAX_DROP`
or a run costs more than `EVAL_MAX_COST_USD` (both set in the workflow). It is a separate check
from `ci-pass` on purpose: it only runs on some PRs and needs an API key, so making it a
required check would block every other PR.

Red team: `evals/redteam.yaml` is a fixed prompt-injection suite (instruction and role
override, injection hidden in user data, fake authority, exfiltration by encoding, by link and
by translation). A canary code in the system prompt must never leak. The `redteam.yml` workflow
runs it by hand and on PRs that touch the prompts or the LLM layer, and skips without an API key.
For generated attacks on top, `promptfoo redteam init` builds a larger plan; check its data
settings first, as some plugins generate attacks through promptfoo's hosted service.

Prompt files are read at runtime. With `output: "standalone"` or on Vercel, include them in
the server bundle: `outputFileTracingIncludes: { "/api/**": ["./src/prompts/**"] }` in
`next.config.ts`.

Security checks: CI runs `pnpm audit --prod --audit-level high` (job `audit`, part of
`ci-pass`). Accepted advisories go under `auditConfig.ignoreGhsas` in `pnpm-workspace.yaml`.

Conventions: all LLM calls go through `src/lib/llm.ts` (`complete()` / `resolveModel()`);
prompts live in `src/prompts/<name>/v<N>.md` and are rendered with `renderPrompt()` from
`src/lib/prompts.ts` (a change is a new version file, evaluated by promptfoo first);
env vars only through `env()` from `src/env.ts`; unit tests mock `ai`, never call a real model;
UI components come from shadcn (`pnpm dlx shadcn@latest add <component>`).

## Options to drop

- No LLM: delete `src/lib/llm*`, `src/app/api/ask`, `src/instrumentation.ts`, `evals/`,
  `evals.yml`, `redteam.yml`, `.github/scripts/eval-gate.mjs`, and the ai/@ai-sdk/@langfuse/@opentelemetry deps.

## Monorepo (apps/web)

Scaffold and copy into `apps/web/`.

Typed API client: generate the types from the API's committed `openapi.json` instead of
writing them by hand. `pnpm add -D openapi-typescript` (and `pnpm add openapi-fetch` for a
typed `fetch`), then add the script
`"api:types": "openapi-typescript ../api/openapi.json -o src/api/schema.d.ts"`, run it, commit
`src/api/schema.d.ts`, and add this step to the web job in `ci.yml` so drift fails CI:

```yaml
      - name: API types match the API schema
        run: pnpm api:types && git diff --exit-code src/api/schema.d.ts
```
 In `ci.yml` and `evals.yml` add
`defaults.run.working-directory: apps/web`, set `cache-dependency-path: apps/web/pnpm-lock.yaml`,
add `on.pull_request.paths: [apps/web/**]`; in `dependabot.yml` use `directory: /apps/web`
for npm; in `release-please-config.json` use the key `apps/web`.
The Python stack's dev container (Python with Node) is used at the root; this stack's
`devcontainer.json` is listed as skipped, which is expected.
In a monorepo, prefix the `paths:` filters of `evals.yml` and `redteam.yml` with `apps/web/`.
