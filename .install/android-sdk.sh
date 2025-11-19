#!/usr/bin/env bash
set -euo pipefail

# install.android-sdk.sh
# Installs Android SDK command-line tools, platform-tools, build-tools and accepts licenses

if [ "$(uname -s)" != "Linux" ]; then
  echo "This script supports Linux only. Exiting."
  
  # 0
fi

ANDROID_SDK_ROOT=${ANDROID_SDK_ROOT:-"$HOME/Android/Sdk"}
CMDLINE_TOOLS_VERSION=${CMDLINE_TOOLS_VERSION:-8512546_latest}
TMPDIR=$(mktemp -d)
mkdir -p "$ANDROID_SDK_ROOT"

echo "Android SDK root: $ANDROID_SDK_ROOT"

cd "$TMPDIR"
CLI_ZIP="commandlinetools.zip"
CLI_URL="https://dl.google.com/android/repository/commandlinetools-linux-${CMDLINE_TOOLS_VERSION}.zip"

if [ ! -f "$CLI_ZIP" ]; then
  echo "Downloading Android command-line tools..."
  wget -q "$CLI_URL" -O "$CLI_ZIP"
fi

unzip -q "$CLI_ZIP" -d "$TMPDIR/cmdline"

mkdir -p "$ANDROID_SDK_ROOT/cmdline-tools"
# Move extracted folder into expected path
if [ -d "$TMPDIR/cmdline/cmdline-tools" ]; then
  mv "$TMPDIR/cmdline/cmdline-tools" "$ANDROID_SDK_ROOT/cmdline-tools/latest" 2>/dev/null || true
else
  mv "$TMPDIR/cmdline" "$ANDROID_SDK_ROOT/cmdline-tools/latest" 2>/dev/null || true
fi

export ANDROID_SDK_ROOT
export PATH="$ANDROID_SDK_ROOT/cmdline-tools/latest/bin:$ANDROID_SDK_ROOT/platform-tools:$PATH"

SDKMANAGER="$ANDROID_SDK_ROOT/cmdline-tools/latest/bin/sdkmanager"
if [ ! -x "$SDKMANAGER" ]; then
  echo "sdkmanager missing or not executable at $SDKMANAGER"
  
  # 1
fi

echo "Updating Android SDK packages (this may take a while)..."
# Ensure platform-tools and a recent platform + build-tools
yes | "$SDKMANAGER" --sdk_root="$ANDROID_SDK_ROOT" --licenses || true
"$SDKMANAGER" --sdk_root="$ANDROID_SDK_ROOT" "platform-tools" "platforms;android-36" "build-tools;28.0.3" || true

# Persist environment for user shells
SHELL_PROFILE="$HOME/.bashrc"
if [ -n "${ZSH_VERSION-}" ]; then
  SHELL_PROFILE="$HOME/.zshrc"
fi

if ! grep -q '## android sdk' "$SHELL_PROFILE" 2>/dev/null; then
  cat >> "$SHELL_PROFILE" <<EOF
## android sdk
export ANDROID_SDK_ROOT="$ANDROID_SDK_ROOT"
export PATH="\$ANDROID_SDK_ROOT/cmdline-tools/latest/bin:\$ANDROID_SDK_ROOT/platform-tools:\$PATH"
EOF
  echo "Updated $SHELL_PROFILE with Android SDK environment.";
fi

echo "Android SDK installation finished. Run 'source $SHELL_PROFILE' or restart shell."
