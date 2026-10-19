---
name: zed-academic-writing-macos
description: Set up and operate a Zed + Docker LaTeX + Skim academic writing workflow on macOS using the zaw CLI, including Docker-based LaTeX builds, PDF forward/reverse search, and exporting Skim PDF annotations as agent-ready Markdown.
---

# Zed Academic Writing (macOS)

This skill operates an academic LaTeX writing environment built around Zed, a
Dockerized TeX Live, and Skim on macOS. Everything is driven by the `zaw`
CLI (from https://github.com/shikibu9419/zed-academic-writing-macos).

If `zaw` is missing, install it first:

```sh
curl -fsSL https://raw.githubusercontent.com/shikibu9419/zed-academic-writing-macos/main/install.sh | sh
```

## Commands

- `zaw new <dir>` — scaffold a paper project from a template and open it in
  Zed (`--template <name>`, `--root <file.tex>`, `--no-git`, `--no-open`).
- `zaw init [<dir>]` — set up an existing paper repository (`.env.local`,
  `AGENTS.md`, `.gitignore`).
- `zaw build [latexmk args] [file.tex]` — compile with latexmk inside
  Docker; all artifacts go to `.build/`.
- `zaw open-pdf [file.tex]` — open the built PDF in Skim.
- `zaw forward-search <file.tex> <line>` — move Skim to the PDF position of
  a source line.
- `zaw notes [--open] [file.tex]` — export Skim PDF annotations to
  `.build/skim-notes.md` with SyncTeX-estimated source links.
- `zaw toggle-onsave` — toggle `texlab.build.onSave` in Zed settings.
- `zaw setup-zed [--write]` — merge the Zed settings/tasks/keymap snippets
  (dry run by default; never overwrites existing values, warns on conflict).

## Building

Compile after manuscript edits with:

```sh
zaw build -silent -synctex=1 -interaction=nonstopmode -file-line-error -halt-on-error main.tex >/dev/null
```

On failure, inspect `.build/main.log` (replace `main` with the project's
root TeX name).

## Configuration

Precedence: environment variables → project `.env.local` (gitignored) →
global `~/.config/zaw/config.env` → defaults.

```sh
# ~/.config/zaw/config.env (machine-wide)
ZED_LATEX_IMAGE=ghcr.io/ayaka-notes/texlive-full:2025.1
ZED_LATEX_OUT_DIR=.build

# <project>/.env.local (per project)
ZED_LATEX_ROOT=main.tex
# ZED_LATEX_MODE=latexmkrc   # auto | latexmkrc | platex | pdflatex
```

`zaw build` locates the project root by walking upward to the first
directory containing `.env.local`, a `latexmkrc`, or `.git`, so it works
from any subdirectory.

## Skim annotation workflow

`zaw notes` writes `.build/skim-notes.md`:

```md
---
created: YYYYmmdd-hhmmss
pdf: /absolute/path/to/.build/main.pdf
root: /absolute/path/to/main.tex
---

# Skim PDF Annotations

The user annotated the PDF with the comments below. Address each instruction.
TeX source locations are estimated via reverse SyncTeX lookup and point at the line closest to each annotation.

---

- source: [sections/example.tex](/absolute/path/to/sections/example.tex:10)
- comment: comment text

---
```

When asked to address PDF annotations, read this file and handle each
comment at its linked source location. Notes must be saved in Skim before
export — if the file shows no notes, ask the user to save the PDF in Skim
and rerun `zaw notes`.

## Invariants — do not "fix" these

- `zaw build` mounts the project at its own absolute host path inside the
  Docker container. This is what makes SyncTeX paths host-valid, which Skim
  requires for forward/reverse search (it silently ignores nonexistent
  paths). Never change the mount to a fixed container path.
- `texlab.build.forwardSearchAfter` stays `false` (prevents focus jumping to
  Skim on every save).
- No AppleScript, System Events, or clipboard automation. The only Skim
  integration points are its official CLIs (`displayline`, `skimnotes`).

## Zed integration reference

Tasks registered by `zaw setup-zed`: `LaTeX: Docker build` (bound to
`cmd-enter` in `.tex` files), `LaTeX: Docker pdflatex`,
`LaTeX: Docker latexmkrc`, `LaTeX: Open PDF`,
`LaTeX: Forward Search`, `LaTeX: Open Skim Notes`,
`LaTeX: Toggle Build On Save`.

Skim reverse search (one-time, in Skim Settings → Sync → Preset Custom):
command `open`, arguments `zed://file"%urlfile":%line`.
