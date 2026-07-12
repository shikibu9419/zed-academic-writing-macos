# Zed Academic Writing for macOS

Write academic LaTeX papers in [Zed](https://zed.dev) on macOS, with:

- **Docker builds** — TeX Live runs in a container (Overleaf-comparable, pinned, nothing to install with `tlmgr`), all artifacts in `.build/`
- **Skim integration** — open the PDF, forward search (source line → PDF position), reverse search (⌘⇧-click in the PDF → source line in Zed)
- **Annotation-driven agent workflow** — export your Skim PDF annotations to a Markdown file with SyncTeX-estimated source links, ready to hand to a coding agent ("address the reviewer comments in `.build/skim-notes.md`")
- **One command per paper** — `zaw new my-paper` scaffolds a project from a template and opens it in Zed

Everything is a subcommand of a single CLI, `zaw`.

## Requirements

- macOS
- [Docker](https://www.docker.com/) (Desktop or compatible)
- [Zed](https://zed.dev) with the `latex` extension (texlab)
- [Skim](https://skim-app.sourceforge.io/)
- [jq](https://jqlang.github.io/jq/) (`brew install jq`) — JSON handling for
  `zaw setup-zed` and `zaw notes`

Nice to have: `pdfinfo` (poppler), `synctex` — used by `zaw notes`; when `synctex` is missing locally the Docker TeX image is used instead.

## Install

```sh
curl -fsSL https://raw.githubusercontent.com/shikibu9419/zed-academic-writing-macos/main/install.sh | sh
# or
git clone https://github.com/shikibu9419/zed-academic-writing-macos.git
cd zed-academic-writing-macos && ./install.sh --link
```

**Nix / devbox**:

```sh
nix profile install github:shikibu9419/zed-academic-writing-macos
# or: devbox add github:shikibu9419/zed-academic-writing-macos
```

## Quick start

```sh
zaw new my-paper       # scaffold from the built-in template and open in Zed
```

In Zed, with a `.tex` file focused:

- `cmd-enter` — build (task `LaTeX: Docker build`); errors appear in the task
  panel, the full log is in `.build/<root>.log`
- task `LaTeX: Open PDF in Skim` — view the PDF (auto-reloads on rebuild)
- task `LaTeX: Forward Search in Skim` — jump Skim to the current line
- task `LaTeX: Open Skim Notes` — export PDF annotations to
  `.build/skim-notes.md` and open it
- task `LaTeX: Toggle Build On Save` — flip `texlab.build.onSave`

For an existing paper repository, run `zaw init` in it instead of `zaw new`
(detects the root TeX file and writes `.env.local`).

### Agentic Writing

Projects created by `zaw new` include an `AGENTS.md` with manuscript-editing rules (compile after every edit, keep changes scoped, etc.). The annotation loop: annotate the PDF in Skim → save the PDF → run the `LaTeX: Open Skim Notes` task → tell your agent to address `.build/skim-notes.md` (each comment carries a SyncTeX-estimated source link).

An agent skill is included for `npx skills`:

```sh
npx skills add shikibu9419/zed-academic-writing-macos --skill zed-academic-writing-macos
```

### Skim settings

Forward search needs no Skim configuration — the Zed tasks drive Skim through its bundled `displayline` CLI. Two things are set once in Skim's own preferences: **auto-reload** (so the PDF refreshes after each rebuild) and **reverse search** (⌘⇧-click in the PDF → source line in Zed).

Apply them from the terminal with `defaults write` (quit Skim first, then relaunch afterwards so it re-reads the domain):

```sh
osascript -e 'quit app "Skim"' 2>/dev/null || true

# Auto-reload the PDF when it changes on disk
defaults write -app Skim SKAutoCheckFileUpdate  -bool true
defaults write -app Skim SKAutoReloadFileUpdate -bool true

# Reverse search: ⌘⇧-click in the PDF opens the source line in Zed
defaults write -app Skim SKTeXEditorPreset    "Custom"
defaults write -app Skim SKTeXEditorCommand   "open"
defaults write -app Skim SKTeXEditorArguments 'zed://file"%urlfile":%line'

open -a Skim
```

Equivalent GUI path: **Skim → Settings → Sync** — check *Check for file changes* + *Reload automatically*, and under *PDF-TeX Sync support* set Preset **Custom**, Command `open`, Arguments `zed://file"%urlfile":%line`.

Reverse search works because `zaw build` mounts your project at its own absolute path inside the container, so the SyncTeX file carries host-valid paths — Skim silently ignores paths that don't exist on your Mac.

## Commands

| Command | What it does |
| --- | --- |
| `zaw new <dir>` | Scaffold a paper project from a template (`--template`, `--no-open`) |
| `zaw init [<dir>]` | Set up an existing project (`.env.local`, `AGENTS.md`, `.gitignore`) |
| `zaw templates` | List built-in and user templates |
| `zaw templates default [<name>]` | Show or set the default template for `zaw new` |
| `zaw templates add <name> <src>` | Add a template from a local dir or GitHub repo |
| `zaw build [args] [file.tex]` | latexmk in Docker; artifacts in `.build/` |
| `zaw open-pdf [file.tex]` | Open the built PDF in Skim |
| `zaw forward-search <file> <line>` | Skim `displayline` to the PDF position |
| `zaw notes [--open] [file.tex]` | Export Skim annotations to `.build/skim-notes.md` |
| `zaw toggle-onsave` | Toggle `texlab.build.onSave` in Zed settings |
| `zaw setup-zed [--write]` | Merge Zed config snippets (dry run by default) |
| `zaw update` | Update zaw |
| `zaw uninstall [--purge]` | Remove zaw |

## Configuration

Precedence: environment variables → project `.env.local` → global `~/.config/zaw/config.env` → defaults.

Global (`~/.config/zaw/config.env`) — machine-wide choices:

```sh
# public and multi-arch image (amd64 + arm64 — native on Apple Silicon)
ZED_LATEX_IMAGE=ghcr.io/ayaka-notes/texlive-full:2025.1
ZED_LATEX_OUT_DIR=.build
# ZED_LATEX_MODE=auto            # auto | latexmkrc | platex | pdflatex
# ZAW_NOTES_LANG=en              # en | ja — language of zaw notes output
# ZAW_TEMPLATE=base              # default `zaw new` template; set via
#                                # `zaw templates default <name>`
```

Per project (`.env.local`, gitignored, written by `zaw new`/`zaw init`):

```sh
ZED_LATEX_ROOT=main.tex
# ZED_LATEX_MODE=latexmkrc       # per-project override if needed
```

Build modes: `latexmkrc` follows the project's `latexmkrc`; `platex` / `pdflatex` force a toolchain; `auto` guesses (existing `latexmkrc` wins, Japanese documents get `-pdfdvi`).


## Templates

The built-in template, `base`, is a minimal ACM (`acmart`) conference skeleton — `acmart` itself ships with TeX Live inside the image, so no class files are committed.

Add your own templates from a local directory or a GitHub repo:

```sh
zaw templates add ieee ~/my-templates/ieee          # from a local directory
zaw templates add ieee shikibu9419/paper-template   # from GitHub (owner/repo)
zaw templates add ieee https://github.com/u/r --force
```

They land in `~/.local/share/zaw/templates/<name>/` (you can also create that directory by hand). A template is just a directory with your `.tex` skeleton, `latexmkrc`, etc.; a `gitignore` file in it is renamed to `.gitignore` on `zaw new`, and any VCS history is stripped on add.

Use and manage them:

```sh
zaw templates                  # list (default marked)
zaw new paper --template ieee  # scaffold from a specific template
zaw templates default ieee     # set the default for a bare `zaw new`
zaw templates default --unset  # revert to the built-in base
```

## Portability beyond macOS

Only three things are macOS-specific; swap them and the rest works on Linux:

- Skim's CLIs (`displayline`, `skimnotes`) — e.g. Zathura/Okular equivalents
- `open -a Skim` in `zaw open-pdf`
- the Zed app CLI fallback path (`/Applications/Zed.app/Contents/MacOS/cli`)

Design policy: no AppleScript / UI automation — the only Skim integration
points are its official bundled CLIs.

## Uninstall

```sh
zaw uninstall          # remove the CLI (+ downloaded payload)
zaw uninstall --purge  # also remove config and user templates (asks first)
```

## License

MIT (see `LICENSE`). The ACM template skeleton follows `acmart`'s own license terms.
