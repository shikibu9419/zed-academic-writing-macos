# Academic Paper Writing Instructions

This repository is an academic paper manuscript.

## Manuscript Work

When editing `.tex` manuscript files, follow these rules:

- Answer the user's concrete request briefly, then make the requested edits.
- When the user gives multiple instructions, first organize them into
  individual actionable items, then address them one by one.
- Keep edits scoped to the requested sections or files.
- Preserve existing LaTeX structure, labels, citations, and commands unless a
  requested edit requires changing them.
- After modifying `.tex` files, immediately compile with:

  ```sh
  zaw build -silent -synctex=1 -interaction=nonstopmode -file-line-error -halt-on-error main.tex >/dev/null
  ```

  If compilation fails, inspect `.build/main.log` to identify the cause.

- Do not run `git`, diff checks, tests, or other verification commands unless
  the user explicitly asks for them.
- Do not perform confirmation-only work after edits unless the user
  explicitly asks for it.

<!-- If you use a dedicated manuscript-writing skill (e.g.
research-paper-writing), instruct your agent to apply it here:
- Use the `research-paper-writing` skill when drafting, revising, polishing,
  reviewing, restructuring, or evaluating manuscript text. -->

## PDF Annotations

`zaw notes` exports the user's Skim PDF annotations to
`.build/skim-notes.md`, with SyncTeX-estimated source links. When asked to
address PDF annotations, read that file and handle each comment.

## Tooling Work

For LaTeX build setup, Zed configuration, Docker, Skim, or keybinding tasks,
work directly without manuscript-writing conventions.
