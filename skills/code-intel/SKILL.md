---
name: code-intel
description: Pick the right code-graph tool for the current repo (GitNexus for code-heavy repos, Graphify when docs, PDFs or notes matter as much as code), index it, and document the choice in AGENTS.md. Use when the user runs /kit:code-intel, at the end of /kit:kickoff, when an AGENTS.md has no "Code intelligence" section, or before a large refactor in a repo that has never been indexed.
---

# Code intelligence

Two graph tools are installed by the kit. They overlap (both build a graph and both can steer
the agent away from grep), so each repo uses **one** as its primary tool.

| | GitNexus | Graphify |
|---|---|---|
| Best at | Call chains, dependencies, **impact / blast radius** before a change | Mixed corpora: code **plus** docs, PDFs, papers, images, notes |
| Inputs | Code only | Code (AST) + docs/images (via the model) |
| Output | `.gitnexus/` index, MCP tools, wiki | `graphify-out/` (graph.html, report, graph.json, Obsidian vault) |
| Refresh | `gitnexus analyze` (hooks also reindex after commits) | `/graphify . --update` |
| Cost | Local parsing, no model tokens | Docs and images cost tokens on first build |

## 1. Measure the repo

```bash
git ls-files | sed 's/.*\.//' | sort | uniq -c | sort -rn | head -20
git ls-files | grep -ciE '\.(pdf|md|mdx|txt|rst|ipynb|png|jpe?g|svg)$'
git ls-files | grep -ciE '\.(py|ts|tsx|js|jsx|go|rs|java|kt|scala|rb|php|c|cpp|cs)$'
```

Also look for folders such as `docs/`, `papers/`, `notes/`, `data/`, `research/` and their size.
Ignore generated docs (CHANGELOG, LICENSE, templates) when judging.

## 2. Decide

Choose **Graphify** if any of these hold, otherwise **GitNexus**:

- PDFs, papers or images are part of what the project reasons about (a RAG corpus, research notes).
- Non-generated docs are roughly a third or more of the meaningful files.
- The user's questions are about concepts across docs and code, not about call chains.

Tell the user the choice and the one-line reason, and let them override it. Using both is
allowed only if the user asks; then say that GitNexus owns impact analysis and Graphify owns
docs questions.

## 3. Index

- **GitNexus**: `gitnexus analyze` at the repo root. Large repo or no GPU: add `--skip-embeddings`.
  Check with `gitnexus list`.
- **Graphify**: invoke the graphify skill with `/graphify .` (use `--mode deep` only if the
  user wants more inferred links). Check that `graphify-out/GRAPH_REPORT.md` exists.

Make sure `.gitnexus/` and `graphify-out/` are in `.gitignore` (the kit template already does this).

## 4. Document it in AGENTS.md

Replace the "Code intelligence" section (or add it before "Out of scope") with:

```markdown
## Code intelligence

This repo is indexed with **<GitNexus|Graphify>** (<one-line reason>).

- Refresh: `<command>` (run after large changes; GitNexus also reindexes after commits).
- Before a refactor, rename or change to a shared function: <GitNexus: run the impact
  analysis and list affected callers in the PR | Graphify: query the graph for every node
  linked to the symbol and check them>.
- Start exploring from <GitNexus: the clusters and processes resources | Graphify:
  `graphify-out/GRAPH_REPORT.md` (god nodes, surprising links)>.
```

If this runs inside `/kit:kickoff`, the AGENTS.md change goes into the bootstrap PR.
Otherwise commit it as `docs: document code intelligence setup` on a branch and open a PR.
