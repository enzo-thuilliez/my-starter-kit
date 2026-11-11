# Changelog

## [0.3.0](https://github.com/enzo-thuilliez/my-starter-kit/compare/my-starter-kit-v0.2.1...my-starter-kit-v0.3.0) (2026-11-11)


### Features

* add /kit:audit to check a repo against the kit conventions ([#60](https://github.com/enzo-thuilliez/my-starter-kit/issues/60)) ([2f51b5f](https://github.com/enzo-thuilliez/my-starter-kit/commit/2f51b5fa44a359862ee45c25edb47de07635821d))
* add /kit:sync to bring existing repos up to date with the templates ([#61](https://github.com/enzo-thuilliez/my-starter-kit/issues/61)) ([280e647](https://github.com/enzo-thuilliez/my-starter-kit/commit/280e6470cbd70f63258531a2237d081906351648))
* draft the readme diagram from the code graph and check it in ci ([#63](https://github.com/enzo-thuilliez/my-starter-kit/issues/63)) ([507af39](https://github.com/enzo-thuilliez/my-starter-kit/commit/507af399691abccd0a2445d3fc3a01434b358957))
* **kickoff:** suggest vetted skills and mcp servers from skills.sh and the mcp registry ([#59](https://github.com/enzo-thuilliez/my-starter-kit/issues/59)) ([856071e](https://github.com/enzo-thuilliez/my-starter-kit/commit/856071e6b6df6ddcd6176225abec2801045aaeee))
* **templates:** add a dev container per stack ([#50](https://github.com/enzo-thuilliez/my-starter-kit/issues/50)) ([3a244e4](https://github.com/enzo-thuilliez/my-starter-kit/commit/3a244e430c66593c46e2fbd4aeda37f44d5af80d))
* **templates:** add a local-first llm profile with ollama ([#57](https://github.com/enzo-thuilliez/my-starter-kit/issues/57)) ([5b5f263](https://github.com/enzo-thuilliez/my-starter-kit/commit/5b5f263e051e8507ec5a298cb05316bad1f060b3))
* **templates:** add a prompt-injection red-team suite ([#55](https://github.com/enzo-thuilliez/my-starter-kit/issues/55)) ([d2e78bc](https://github.com/enzo-thuilliez/my-starter-kit/commit/d2e78bc7267c9c12dd9b5dfb1a5f0b2ee54c04fe))
* **templates:** add a runtime guardrail for numbers in llm output ([#52](https://github.com/enzo-thuilliez/my-starter-kit/issues/52)) ([b213857](https://github.com/enzo-thuilliez/my-starter-kit/commit/b213857ba68c29f44461af620a98de093e3275ee))
* **templates:** add an opt-in privacy overlay for projects with real data ([#58](https://github.com/enzo-thuilliez/my-starter-kit/issues/58)) ([9479a55](https://github.com/enzo-thuilliez/my-starter-kit/commit/9479a5530ed3a938f80bdb9eb93ef91f065e693d))
* **templates:** add an optional agent pr review driven by agents.md ([#62](https://github.com/enzo-thuilliez/my-starter-kit/issues/62)) ([3ae1739](https://github.com/enzo-thuilliez/my-starter-kit/commit/3ae1739adcee572f6f24a12c69a791cb7f697371))
* **templates:** add claude code hooks for secrets and post-edit checks ([#48](https://github.com/enzo-thuilliez/my-starter-kit/issues/48)) ([d8bad64](https://github.com/enzo-thuilliez/my-starter-kit/commit/d8bad641cc2a9d3eb8da150cdc5b08699f1bcf4d))
* **templates:** add property-based tests and recorded llm calls ([#53](https://github.com/enzo-thuilliez/my-starter-kit/issues/53)) ([a6fc877](https://github.com/enzo-thuilliez/my-starter-kit/commit/a6fc87755a8acf5866c50f2ecef4e443407fa7a2))
* **templates:** commit the openapi schema and generate typescript types from it ([#54](https://github.com/enzo-thuilliez/my-starter-kit/issues/54)) ([9728183](https://github.com/enzo-thuilliez/my-starter-kit/commit/97281836c990238ed4793c6199e005cdd4ed3e64))
* **templates:** gate evals against main with a cost budget ([#56](https://github.com/enzo-thuilliez/my-starter-kit/issues/56)) ([d41ca0a](https://github.com/enzo-thuilliez/my-starter-kit/commit/d41ca0aa20af3bd40655b00ef1c74960c82e1519))
* **templates:** keep prompts in versioned files evaluated by promptfoo ([#51](https://github.com/enzo-thuilliez/my-starter-kit/issues/51)) ([62d6de2](https://github.com/enzo-thuilliez/my-starter-kit/commit/62d6de2300613e681929f1694d06ca60b5c3bff5))
* **templates:** scan dependencies for known vulnerabilities in ci ([#49](https://github.com/enzo-thuilliez/my-starter-kit/issues/49)) ([fdc1e06](https://github.com/enzo-thuilliez/my-starter-kit/commit/fdc1e061045596b62c06ec5ab0fb1428b5af2a85))

## [0.2.1](https://github.com/enzo-thuilliez/my-starter-kit/compare/my-starter-kit-v0.2.0...my-starter-kit-v0.2.1) (2026-11-09)


### Bug Fixes

* **templates:** let cargo-deny accept path dependencies in rust workspaces ([#29](https://github.com/enzo-thuilliez/my-starter-kit/issues/29)) ([f4e8e99](https://github.com/enzo-thuilliez/my-starter-kit/commit/f4e8e992473aa7dcec4c2a5f51b1a54269daf71f))

## [0.2.0](https://github.com/enzo-thuilliez/my-starter-kit/compare/my-starter-kit-v0.1.0...my-starter-kit-v0.2.0) (2026-11-09)


### Features

* add Rust stack template ([#16](https://github.com/enzo-thuilliez/my-starter-kit/issues/16)) ([00e6d29](https://github.com/enzo-thuilliez/my-starter-kit/commit/00e6d296029644d5e0c67a2cd9398f406ea5dbc2))
* backport rag-hive practices into the kit ([#11](https://github.com/enzo-thuilliez/my-starter-kit/issues/11)) ([bbeacc9](https://github.com/enzo-thuilliez/my-starter-kit/commit/bbeacc97b8247b7d5da01cc12f4c750b0f80abfa))
* gate releases until the project works ([#15](https://github.com/enzo-thuilliez/my-starter-kit/issues/15)) ([ffd3a90](https://github.com/enzo-thuilliez/my-starter-kit/commit/ffd3a90cff25429215e911bbbef981fbe668c49e))
* hybrid kickoff interview with pre-filled question buttons ([#22](https://github.com/enzo-thuilliez/my-starter-kit/issues/22)) ([77155a0](https://github.com/enzo-thuilliez/my-starter-kit/commit/77155a03aeb65e49ca9452cf53c85db96338b9b1))


### Bug Fixes

* bootstrap PR blocked by a check that cannot run ([#24](https://github.com/enzo-thuilliez/my-starter-kit/issues/24)) ([fea1a9f](https://github.com/enzo-thuilliez/my-starter-kit/commit/fea1a9feb5424cf1cff9f691e0a2943e4aabf37a))
* kickoff issues found by the first real run ([#20](https://github.com/enzo-thuilliez/my-starter-kit/issues/20)) ([681bab6](https://github.com/enzo-thuilliez/my-starter-kit/commit/681bab6b0dd5dfe261e1059698fb3f540a7dff2b))
* run the gitleaks hook from a binary instead of Go sources ([#18](https://github.com/enzo-thuilliez/my-starter-kit/issues/18)) ([629c91b](https://github.com/enzo-thuilliez/my-starter-kit/commit/629c91b902e18e2fa0a112fe67f508b66fd1be36))

## 0.1.0 (2026-11-07)


### Features

* add common repo template ([b376d61](https://github.com/enzo-thuilliez/my-starter-kit/commit/b376d61990cf5cf92bf445323ff2ca8e4a605738)), closes [#1](https://github.com/enzo-thuilliez/my-starter-kit/issues/1)
* add global CLAUDE.md rules ([cc3fd91](https://github.com/enzo-thuilliez/my-starter-kit/commit/cc3fd91f77bd8dcbcff63af4c51a1e475a62f6a5)), closes [#1](https://github.com/enzo-thuilliez/my-starter-kit/issues/1)
* add idempotent install.sh ([37b544a](https://github.com/enzo-thuilliez/my-starter-kit/commit/37b544a5bde51c33d4d22a51bcb38442da631f92)), closes [#1](https://github.com/enzo-thuilliez/my-starter-kit/issues/1)
* add kickoff and code-intel skills ([dc75ea5](https://github.com/enzo-thuilliez/my-starter-kit/commit/dc75ea521a653a4aae6a6ba71e4523919eaaad28)), closes [#1](https://github.com/enzo-thuilliez/my-starter-kit/issues/1)
* add Python stack template ([525ab35](https://github.com/enzo-thuilliez/my-starter-kit/commit/525ab356a762cd77d5a4ba6b6b474e781317f341)), closes [#1](https://github.com/enzo-thuilliez/my-starter-kit/issues/1)
* add TypeScript (Next.js) stack template ([5e92dbf](https://github.com/enzo-thuilliez/my-starter-kit/commit/5e92dbf763905eb3d480463f999a15331de8608c)), closes [#1](https://github.com/enzo-thuilliez/my-starter-kit/issues/1)
* kit v0.1 ([93c94d1](https://github.com/enzo-thuilliez/my-starter-kit/commit/93c94d1567daf6f6969f6863ddb923c57dfbcc9c))


### Bug Fixes

* pin the first release to v0.1.0 ([#7](https://github.com/enzo-thuilliez/my-starter-kit/issues/7)) ([03df167](https://github.com/enzo-thuilliez/my-starter-kit/commit/03df1670e135aa60623b70579f992f74d9e8ca90))
* release setup and kickoff repo settings ([#4](https://github.com/enzo-thuilliez/my-starter-kit/issues/4)) ([396b409](https://github.com/enzo-thuilliez/my-starter-kit/commit/396b409813aa9f97e47243a52fc7ab72bdae9880))

## Changelog

All notable changes to this project are documented here. Entries are generated by
[release-please](https://github.com/googleapis/release-please) from Conventional Commits.
