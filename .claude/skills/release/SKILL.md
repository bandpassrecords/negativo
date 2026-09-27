---
name: release
description: Cut a Negativo release end to end. Writes the in-app changelog entry, checks the CI version gate, publishes the GitHub release (which creates the tag and starts android-release.yml and ios-build.yml), watches both runs, and if one fails deletes the release and tag, diagnoses, fixes, commits, pushes and tries again until both builds are green. Use when the user says "release", "cut a release", "release 0.4.0", "ship vX.Y.Z", or "publish a new version".
argument-hint: "[X.Y.Z]"
---

# Release

Carries a release from "the code is on `main`" to "every asset is on the
GitHub release". Two checkpoints need the user, both at the start:

1. the version number, and
2. the notes: the in-app changelog highlights plus the GitHub release notes.

Once the user has said go, keep going on your own through the pipeline,
failures and retries, reporting as you go.

## How releasing works in this repo (read first)

- **The GitHub release has to exist before the builds finish.** Both
  workflows end by looking the release up by tag (`getReleaseByTag`) and
  uploading their asset to it; with no release they fail.
  - So **never push a bare tag.** Create the release with `gh release create`,
    which creates the tag on the remote, and that tag push starts both
    workflows within seconds.
- **The version gate:** the newest entry in `assets/changelog/changelog.json`
  must match the tag. It's checked in `android-release.yml`'s `Unit Tests` job
  (which the Android build waits on) and at the start of `ios-build.yml`.
- **The version comes from the tag.** `pubspec.yaml` stays at
  `version: 0.0.0+0`; don't change it. CI passes `--build-name`,
  `--build-number` (MAJOR*10000 + MINOR*100 + PATCH) and
  `--dart-define=APP_VERSION`. The app reads `APP_VERSION` for Settings >
  Version and the "What's New" dialog; `0.0.0` means a dev build.
- **What a tag run builds:** Unit Tests, then the signed Android App Bundle
  (`Negativo_Android_vX.Y.Z.aab`); separately, an unsigned iOS `.ipa` for
  sideloading (`Negativo_iOS_unsigned_vX.Y.Z.ipa`). About **10 minutes**.
- **Retries are safe.** Nothing is uploaded to a store; deleting a failed
  release and its tag, then recreating them, leaves nothing behind.
- **Use `gh` for anything on GitHub** — tags, releases, runs, logs, PRs, the
  remote state of `main` — with `-R bandpassrecords/negativo` (no default repo
  is set). Use `git` only for staging, committing, pushing and removing a
  local tag. The remote is `origin`.
- **Commits and notes:** follow the user's global rules — no
  `Co-Authored-By:` trailer and no "Generated with Claude Code" footer.

## 1. Version and pre-flight

- Version: from `$ARGUMENTS` if given (strip a leading `v`). Otherwise:
  - Newest **remote** tag:
    ```
    gh api repos/bandpassrecords/negativo/git/matching-refs/tags/v \
      --jq '.[].ref | sub("refs/tags/"; "")' | sort -V | tail -1
    ```
  - If the newest `changelog.json` entry is ahead of that tag, it's the
    version being released. Otherwise propose a patch or minor bump from the
    changes since the last tag, and ask.
- It must be `X.Y.Z` and higher than the newest remote tag. Neither a
  release nor a tag may exist for it yet; both of these must 404:
  - `gh release view vX.Y.Z -R bandpassrecords/negativo`
  - `gh api repos/bandpassrecords/negativo/git/ref/tags/vX.Y.Z`
- **Release from `main`.** `git checkout main`, then
  `gh repo sync --source bandpassrecords/negativo --branch main`. If it
  refuses (diverged local commits), stop and report rather than forcing.
  - If the work to ship sits on an unmerged branch or PR
    (`gh pr list -R bandpassrecords/negativo --state open`), stop and say
    so. Merging it is the user's call.
- The working tree must be clean apart from
  `android/app/src/main/java/io/flutter/plugins/GeneratedPluginRegistrant.java`
  if the local Flutter regenerated it.

## 2. Notes (checkpoint: user approval)

Collect what changed since the last tag:

```
gh api repos/bandpassrecords/negativo/compare/<last-tag>...main \
  --jq '.commits[] | select(.parents | length == 1) | .commit.message'
gh pr list -R bandpassrecords/negativo --state merged --base main \
  --search "merged:>=<date of last tag>" --json number,title,body
```

(The date comes from `gh release view <last-tag> -R bandpassrecords/negativo --json publishedAt`.)

Draft two things and show them together:

- **In-app changelog highlights** (`changelog.json`)
  - One short sentence per change someone using the app would notice, in the
    tone of the existing entries. Leave out refactors, CI, tests, debug-only
    tools and dependency bumps.
  - English is required. Also write `pt` (**Brazilian** Portuguese); `es`,
    `fr`, `de` and `it` are welcome, and any missing locale falls back to
    English. Use the app's own names for buttons and screens (`lib/l10n/`).
  - If an entry for this version already exists, show it and ask if it's
    final rather than rewriting it.
- **GitHub release notes**, in the shape of the previous release
  (`gh release view <last-tag> -R bandpassrecords/negativo --json body`):
  `## ✨ New` with a `###` per feature, `## 🎞️ Improved`, `## 🐛 Fixed`,
  and a closing `**Full changelog:** …/compare/<last-tag>...vX.Y.Z`.

Wait for the user's OK or edits. Then write the entry:

```
python scripts/new_changelog_entry.py X.Y.Z --highlight "…" --highlight "…"
python scripts/new_changelog_entry.py X.Y.Z --locale pt --highlight "…"
```

(`--replace` amends an existing locale.) Save the GitHub notes to a scratch
file for step 4.

## 3. Verify and commit

- The gate, locally — this must print `X.Y.Z`:
  ```
  python -c "import json;print(json.load(open('assets/changelog/changelog.json',encoding='utf-8'))['releases'][0]['version'])"
  ```
- `git diff`: only `assets/changelog/changelog.json` should have changed.
- `flutter analyze` and the full `flutter test` (the bundled changelog is
  tested too). A failure here would fail `Unit Tests` in CI, so fix it
  first (see step 6).
- Commit that file alone as `Prepare release vX.Y.Z`, then
  `git push origin main`.
- Confirm GitHub has it:
  `gh api repos/bandpassrecords/negativo/commits/main --jq .sha` must equal
  `git rev-parse HEAD`.

## 4. Publish

```
gh release create vX.Y.Z -R bandpassrecords/negativo \
  --target <sha of the pushed commit> --title vX.Y.Z --notes-file <notes file>
```

- Use `--target` with the exact SHA, not `main`, so a later push can't slip
  into the tag.
- Find the two runs it started (a few seconds to appear; poll briefly):
  ```
  gh run list -R bandpassrecords/negativo --branch vX.Y.Z --limit 4 \
    --json databaseId,workflowName,createdAt,status
  ```
  Don't add `--event push` (with `--branch` it matches nothing). Only accept
  runs created after this attempt's release was published.

## 5. Watch the pipeline

- Watch both in the background:
  `gh run watch <run-id> -R bandpassrecords/negativo --exit-status`
  with `run_in_background`, and tell the user it's running and roughly when
  it should finish.
- **Success:** check the release has both assets:
  ```
  gh release view vX.Y.Z -R bandpassrecords/negativo --json assets --jq '.assets[].name'
  ```
  expecting `Negativo_Android_vX.Y.Z.aab` and
  `Negativo_iOS_unsigned_vX.Y.Z.ipa`. A missing one counts as a failure.
  Then report the release URL, its assets and how many attempts it took.
- **Failure:** go to step 6.

## 6. When a run fails

1. **Diagnose:** `gh run view <run-id> -R bandpassrecords/negativo --log-failed`.
   Name the failing job and step and quote the actual error.
2. **Sort out what kind of failure it is.**

   **Transient** (runner lost, network timeout, a download hiccup, rate
   limit): nothing to delete. `gh run rerun <run-id> --failed`, then back to
   step 5. At most twice for the same job, then treat it as real.

   **Needs something only the user can do** (a missing or expired secret
   such as `ANDROID_KEYSTORE_BASE64`, `ANDROID_KEYSTORE_PASSWORD`,
   `ANDROID_KEY_ALIAS`, `ANDROID_KEY_PASSWORD`; a Google or Apple account
   problem): **stop** and report exactly what's needed. Don't delete the
   release: once it's fixed, a `--failed` rerun finishes it.

   **A real problem in the repo** (test failure, version gate, build error,
   workflow bug):
   - Delete the release **and** its tag:
     ```
     gh release delete vX.Y.Z -R bandpassrecords/negativo --cleanup-tag --yes
     gh api repos/bandpassrecords/negativo/git/ref/tags/vX.Y.Z   # must now 404
     git tag -d vX.Y.Z 2>/dev/null
     ```
     If the tag survived, `gh api -X DELETE repos/bandpassrecords/negativo/git/refs/tags/vX.Y.Z`.
   - Fix the root cause on `main`, with a regression test when it's a code
     bug. Reproduce locally where you can (`flutter test`, `flutter analyze`,
     the gate check, `flutter build apk`).
   - Run the full test suite, commit the fix on its own with a normal
     descriptive message, `git push origin main`, and confirm it landed.
   - Back to step 4 with the new SHA. The notes only change if the fix is
     something users would notice.
3. **Stop after 3 attempts that each needed a code fix.** Delete the
   half-finished release first, so the repo isn't left with a failed release
   marked Latest, then report what each attempt changed and the current
   error, and ask how to proceed.

Keep the user posted at each transition: published, failed (and why), fix
pushed, retry started, done.
