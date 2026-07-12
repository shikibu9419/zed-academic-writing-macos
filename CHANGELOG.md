# Changelog

## v0.1.0

First release — a single `zaw` CLI for writing academic LaTeX papers in Zed
on macOS.

### Projects & templates

- `zaw new <dir>` — scaffold a paper from a template, initialize version
  control (git, plus a colocated Jujutsu repo when `jj` is installed), and
  open it in Zed.
- `zaw init [<dir>]` — set up an existing project: detect the root TeX file,
  write `.env.local`, and add `AGENTS.md`/`.gitignore` when absent.
- `zaw templates` — list built-in and user templates.
- `zaw templates default [<name>]` — show or set the default template.
- `zaw templates add <name> <path|github-url>` — install a template from a
  local directory or a GitHub repo.

### Build & Skim

- `zaw build [args] [file.tex]` — latexmk in Docker; artifacts in `.build/`.
  Modes: `auto`, `latexmkrc`, `platex`, `pdflatex`.
- `zaw open-pdf` / `zaw forward-search <file> <line>` — Skim preview and
  source-line → PDF jump.
- `zaw notes [--open]` — export Skim PDF annotations to `.build/skim-notes.md`
  with SyncTeX-estimated source links (`en`/`ja`).

### Zed integration

- `zaw setup-zed [--write]` — merge Zed settings/tasks/keymap without
  overwriting your values (backs up first, warns on conflicts). Run
  automatically, with confirmation, during install.
- `zaw toggle-onsave` — toggle `texlab.build.onSave`.

### Configuration

- Global `~/.config/zaw/config.env` + per-project `.env.local`
  (precedence: environment → `.env.local` → global config → defaults).

### Install

- curl one-liner, `git clone` + `./install.sh --link`, or Nix flake.
- `zaw update` / `zaw uninstall [--purge]`.
