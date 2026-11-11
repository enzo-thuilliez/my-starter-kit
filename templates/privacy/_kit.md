# Privacy stack — notes for /kit:kickoff (not copied)

For projects that handle real or personal data (staff, clients, patients, accounts). Apply it
on top of the other stacks:

```bash
$KIT/scripts/apply-template.sh --target . --stack privacy "${VARS[@]}"
```

It adds `scripts/denylist-check.sh` and ignores `private/` (real exports stay on the
maintainer's machine). Then, by hand:

1. **CI job** in `ci.yml`, and add `denylist` to `ci-pass`'s `needs`:

   ```yaml
     denylist:
       runs-on: ubuntu-latest
       steps:
         - uses: actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1 # v7.0.1
           with:
             fetch-depth: 0
         - name: No real data in files or commit messages
           env:
             DENYLIST: ${{ secrets.DENYLIST }}
             BASE: ${{ github.event.pull_request.base.sha }}
           run: scripts/denylist-check.sh "${BASE:-}"
   ```

2. **Secret**: the user sets `DENYLIST` (one term per line: real names, the organisation's
   name, addresses) with `gh secret set DENYLIST` and types the terms themselves. Never ask for
   the terms in the conversation, never write them anywhere, never print them. CI fails until
   the secret exists, on purpose.

3. **`.claude/settings.json`**: add `"Read(./private/**)"` to `permissions.deny`.

4. **AGENTS.md**, under the project's hard rules:

   ```markdown
   1. **No real data, ever.** Fixtures use fictitious names. Never paste real names, the
      organisation's name, real records or exports into code, tests, issues, PRs or commit
      messages. If you see real data, stop and tell the user. CI enforces this with a denylist
      kept in a GitHub secret.
   2. **Pseudonymize** before anything leaves the app (LLM calls, external services, logs):
      send stable IDs, never names or free-text notes.
   3. Never read `private/` unless the user asks, and never copy from it.
   ```

5. **DECISIONS.md**, two ADRs (renumber to follow ADR-001):

   ```markdown
   ## ADR-002: No real data in the repository

   - **Status:** accepted
   - **Context:** {what real data the project touches, and whether the repo is public}.
   - **Decision:** fixtures and tests use fictitious data. CI runs gitleaks and a denylist
     check whose terms are stored as a GitHub secret, not in the repo. Real exports stay in the
     ignored `private/` folder.
   - **Consequences:** the denylist must be updated when the real data changes (new staff,
     new client).

   ## ADR-003: Pseudonymize before any call that leaves the app

   - **Status:** accepted
   - **Context:** LLM providers and external services give limited confidentiality guarantees.
   - **Decision:** the app replaces names with stable IDs before any outbound call and maps
     them back on return. Free-text notes are never sent.
   - **Consequences:** prompts and tools work with IDs; the mapping lives only in the app.
   ```
