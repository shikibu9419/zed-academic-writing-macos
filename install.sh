#!/bin/sh
# Installer for zed-academic-writing-macos (zaw).
#
#   curl -fsSL https://raw.githubusercontent.com/shikibu9419/zed-academic-writing-macos/main/install.sh | sh
#
# Or from a git clone (symlinks into the clone so `git pull` updates):
#
#   ./install.sh --link
set -eu

REPO="shikibu9419/zed-academic-writing-macos"
DATA_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/zaw"
BIN_DIR="$HOME/.local/bin"

mode="fetch"
remote=0
for arg in "$@"; do
  case "$arg" in
    --link) mode="link" ;;
    --remote) remote=1 ;;
    -h | --help)
      printf 'Usage: install.sh [--link] [--remote]\n\n'
      printf '  --link    Symlink the CLI from this checkout\n'
      printf '  --remote  Configure an SSH server; default PDF preview to false\n'
      exit 0
      ;;
    *)
      printf 'install.sh: unknown option: %s\n' "$arg" >&2
      exit 2
      ;;
  esac
done

if [ "$mode" = "link" ]; then
  src=$(cd "$(dirname "$0")" && pwd)
  if [ ! -x "$src/bin/zaw" ]; then
    printf 'install.sh: --link must run from a checkout (bin/zaw not found next to install.sh)\n' >&2
    exit 1
  fi
else
  command -v curl >/dev/null 2>&1 || { printf 'install.sh: curl is required\n' >&2; exit 1; }
  tmp=$(mktemp -d)
  trap 'rm -rf "$tmp"' EXIT
  url="https://github.com/$REPO/archive/refs/heads/main.tar.gz"
  printf 'Downloading %s ...\n' "$url"
  curl -fsSL "$url" -o "$tmp/zaw.tar.gz"
  mkdir -p "$tmp/unpack"
  tar -xzf "$tmp/zaw.tar.gz" -C "$tmp/unpack" --strip-components 1
  mkdir -p "$DATA_DIR"
  rm -rf "$DATA_DIR/app"
  mv "$tmp/unpack" "$DATA_DIR/app"
  src="$DATA_DIR/app"
fi

mkdir -p "$BIN_DIR"
ln -sf "$src/bin/zaw" "$BIN_DIR/zaw"
printf 'Installed: %s -> %s\n' "$BIN_DIR/zaw" "$src/bin/zaw"

case ":$PATH:" in
  *":$BIN_DIR:"*) ;;
  *)
    printf '\nWARNING: %s is not on your PATH. Add to your shell profile:\n' "$BIN_DIR"
    printf '  export PATH="$HOME/.local/bin:$PATH"\n'
    ;;
esac

# Wire up Zed: check Zed is present, show what would change (additions +
# conflicts), then ask before applying. Never overwrites your values and
# backs up first. Skip entirely with ZAW_SKIP_SETUP_ZED=1; auto-apply
# without a prompt with ZAW_ASSUME_YES=1.
if [ "${ZAW_SKIP_SETUP_ZED:-0}" != "1" ]; then
  if [ "$remote" = "0" ] && ! command -v zed >/dev/null 2>&1 && [ ! -d /Applications/Zed.app ]; then
    printf '\nZed not found — skipping Zed config setup.\n'
    printf 'After installing Zed, run: zaw setup-zed --write\n'
  else
    set --
    if [ "$remote" = "1" ]; then set -- --remote; fi
    printf '\nZed config changes — dry run:\n\n'
    "$src/bin/zaw" setup-zed "$@" || true   # exit 1 just flags conflicts

    apply=0
    if [ "${ZAW_ASSUME_YES:-0}" = "1" ]; then
      apply=1
    elif [ -r /dev/tty ]; then
      printf '\nApply these changes to your Zed config? [y/N] '
      read -r reply < /dev/tty || reply=""
      case "$reply" in
        y | Y | yes | YES) apply=1 ;;
      esac
    else
      printf '\nNon-interactive shell — not applied.\n'
    fi

    if [ "$apply" = "1" ]; then
      printf '\n'
      "$src/bin/zaw" setup-zed "$@" --write || true   # exit 1 = conflicts kept; not fatal
    else
      printf 'Skipped. Apply later with: zaw setup-zed %s --write\n' "$*"
    fi
  fi
fi

if [ "$remote" = "1" ]; then
  cat <<EOF

Next steps (on the server):
  zaw new my-paper --no-open
  zaw setup-zed --remote --project my-paper --write

Install the latex extension in your local Zed, then open the server project over SSH.
Requirements on the server: Bash, Docker, jq. No GUI Zed or Skim required.
EOF
else
  cat <<EOF

Next step:
  zaw new my-paper    # create a paper project and open it in Zed

Requirements: Bash, Docker, Zed, jq.
EOF
fi

if [ "$remote" = "0" ] && [ "$(uname -s)" = "Darwin" ]; then
  printf '\nFor Skim preview and reverse search (PDF -> Zed), install Skim and see "Skim settings" in the README.\n'
else
  printf '\nPDF preview defaults to disabled. Enable with enable_pdf_preview in Zed settings.\n'
fi
