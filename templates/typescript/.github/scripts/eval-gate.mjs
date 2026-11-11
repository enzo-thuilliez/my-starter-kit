#!/usr/bin/env node
// Compare a promptfoo run with the baseline from main, and enforce a cost budget.
//
//   node eval-gate.mjs <current.json> [baseline.json]
//
// Prints a Markdown report (used as the PR comment) and exits 1 when the pass rate dropped by
// more than EVAL_MAX_DROP (default 0.05, i.e. 5 points) or the run cost more than
// EVAL_MAX_COST_USD (default 1.00). Without a baseline, only the budget is checked.
import { existsSync, readFileSync } from "node:fs";

const [currentPath, baselinePath] = process.argv.slice(2);
if (!currentPath) {
  console.error("usage: eval-gate.mjs <current.json> [baseline.json]");
  process.exit(2);
}
const maxDrop = Number(process.env.EVAL_MAX_DROP ?? "0.05");
const maxCost = Number(process.env.EVAL_MAX_COST_USD ?? "1.00");

function load(path) {
  const run = JSON.parse(readFileSync(path, "utf8"));
  const rows = run.results?.results ?? [];
  const tests = new Map();
  let cost = 0;
  for (const row of rows) {
    const name =
      row.testCase?.description ??
      JSON.stringify(row.vars ?? row.testCase?.vars ?? {});
    const prompt =
      row.prompt?.label ?? String(row.prompt?.raw ?? "").slice(0, 40);
    tests.set(`${name} | ${prompt}`, row.success === true);
    cost += Number(row.cost ?? row.response?.cost ?? 0);
  }
  const passed = [...tests.values()].filter(Boolean).length;
  return {
    tests,
    passed,
    total: tests.size,
    rate: tests.size ? passed / tests.size : 0,
    cost,
  };
}

const pct = (x) => `${(100 * x).toFixed(1)}%`;
const usd = (x) => `$${x.toFixed(4)}`;

const current = load(currentPath);
const baseline =
  baselinePath && existsSync(baselinePath) ? load(baselinePath) : null;
const problems = [];

const lines = [
  "<!-- eval-gate -->",
  "### Evals",
  "",
  "| | This PR | main |",
  "|---|---|---|",
];
lines.push(
  `| Pass rate | ${pct(current.rate)} (${current.passed}/${current.total}) | ${
    baseline
      ? `${pct(baseline.rate)} (${baseline.passed}/${baseline.total})`
      : "no baseline yet"
  } |`,
);
lines.push(
  `| Cost | ${usd(current.cost)} | ${baseline ? usd(baseline.cost) : "-"} |`,
);

if (baseline) {
  const drop = baseline.rate - current.rate;
  if (drop > maxDrop) {
    problems.push(
      `pass rate dropped by ${(100 * drop).toFixed(1)} points (limit ${(100 * maxDrop).toFixed(1)})`,
    );
  }
  const broken = [...current.tests].filter(
    ([key, ok]) => !ok && baseline.tests.get(key) === true,
  );
  if (broken.length) {
    lines.push("", "Newly failing:", ...broken.map(([key]) => `- ${key}`));
  }
}
if (current.cost > maxCost) {
  problems.push(`run cost ${usd(current.cost)} (budget ${usd(maxCost)})`);
}

lines.push(
  "",
  problems.length
    ? `**Gate failed:** ${problems.join("; ")}.`
    : `**Gate passed** (max drop ${(100 * maxDrop).toFixed(1)} points, budget ${usd(maxCost)}).`,
);
console.log(lines.join("\n"));
process.exit(problems.length ? 1 : 0);
