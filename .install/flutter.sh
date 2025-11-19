#!/usr/bin/env bash
set -euo pipefail

# install.flutter.sh
# Installs Flutter SDK (stable by default), required Linux dependencies, and runs `flutter doctor`.

if [ "$(uname -s)" != "Linux" ]; then
  echo "This script supports Linux only. Exiting."
  exit 0
fi

FLUTTER_DIR=${FLUTTER_DIR:-"$HOME/flutter"}
FLUTTER_CHANNEL=${FLUTTER_CHANNEL:-stable}

echo "Installing system dependencies for Flutter (may require sudo)..."
sudo apt-get update
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
  git curl unzip xz-utils zip libglu1-mesa libgtk-3-0 libpulse0 ca-certificates clang cmake pkg-config || true

if [ ! -d "$FLUTTER_DIR" ]; then
  echo "Cloning Flutter (channel=$FLUTTER_CHANNEL) into $FLUTTER_DIR..."
  git clone https://github.com/flutter/flutter.git -b "$FLUTTER_CHANNEL" "$FLUTTER_DIR"
else
  echo "Flutter directory exists — updating to latest $FLUTTER_CHANNEL..."
  git -C "$FLUTTER_DIR" fetch --all --tags || true
  git -C "$FLUTTER_DIR" checkout "$FLUTTER_CHANNEL" || true
  git -C "$FLUTTER_DIR" pull origin "$FLUTTER_CHANNEL" || true
fi

export PATH="$FLUTTER_DIR/bin:$PATH"

# Persist PATH to shell profile
SHELL_PROFILE="$HOME/.bashrc"
if [ -n "${ZSH_VERSION-}" ]; then
  SHELL_PROFILE="$HOME/.zshrc"
fi

if ! grep -q '## flutter' "$SHELL_PROFILE" 2>/dev/null; then
  cat >> "$SHELL_PROFILE" <<EOF
## flutter
export PATH="$FLUTTER_DIR/bin:\$PATH"
EOF
  echo "Appended Flutter PATH to $SHELL_PROFILE"
fi

echo "Running 'flutter --version' and 'flutter doctor' (these may download artifacts)..."
"$FLUTTER_DIR/bin/flutter" --version || true
"$FLUTTER_DIR/bin/flutter" doctor || true

echo "Flutter install finished. Restart your shell or run: source $SHELL_PROFILE"
