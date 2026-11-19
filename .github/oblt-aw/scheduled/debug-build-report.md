# debug-build-report (obs:repo-scheduled)

Analyze the `golang-crossbuild` Buildkite pipeline (`org_slug: elastic`,
`pipeline_slug: golang-crossbuild`) for the last **7** days. Use the skill's
scheduled-run branch selection (`main` and `N.N` branches). Prefer `noop` when
every eligible branch is healthy (no unrecovered failures). Create at most one
issue, and apply label `observablt-ci` when creating one.

Docker may be unavailable on the scheduled runner. If you cannot reproduce in
Docker, keep the diagnosis tentative and say so under Reproduction status.

## Diagnosis and issue format

Follow the **debug-build** skill and the **build-debug-issue** issue format from
`additional-instructions` (resolved from `.apm/skills/debug-build/SKILL.md` and
`.apm/instructions/build-debug-issue.instructions.md`). Do not invent a
different investigation or issue layout.
