
#!/usr/bin/env bash
set -euo pipefail

echo "Installing Java 17, Gradle 8.1, Android SDK 33 and Flutter (Linux)"

# Support only Linux in this script; exit gracefully otherwise
OS="$(uname -s)"
if [ "$OS" != "Linux" ]; then
	echo "This installer currently supports Linux only. See https://flutter.dev/docs/get-started/install for other platforms."
	exit 0
fi

# Ensure essential packages are present
sudo apt-get update
sudo apt-get install -y curl wget git unzip xz-utils zip libglu1-mesa openjdk-17-jdk || true

export JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
export PATH="${JAVA_HOME}/bin:${PATH}"

# Install Gradle (if not already installed)
GRADLE_VERSION=8.1
GRADLE_ZIP="/tmp/gradle-${GRADLE_VERSION}-bin.zip"
if ! command -v gradle >/dev/null 2>&1; then
	echo "Installing Gradle ${GRADLE_VERSION}..."
	wget -q "https://services.gradle.org/distributions/gradle-${GRADLE_VERSION}-bin.zip" -O "$GRADLE_ZIP"
	sudo unzip -o -d /opt/gradle "$GRADLE_ZIP"
	sudo ln -sf "/opt/gradle/gradle-${GRADLE_VERSION}" /opt/gradle/latest
	export GRADLE_HOME="/opt/gradle/gradle-${GRADLE_VERSION}"
	export PATH="${GRADLE_HOME}/bin:${PATH}"
else
	echo "Gradle found: $(gradle --version | sed -n '1p')"
fi

# Android SDK Command-line tools
ANDROID_SDK_ROOT="${HOME}/Android/Sdk"
mkdir -p "${ANDROID_SDK_ROOT}/cmdline-tools" "${ANDROID_SDK_ROOT}/platforms"
TMPDIR=$(mktemp -d)
cd "$TMPDIR"
CLI_ZIP=commandlinetools.zip
if [ ! -f "$CLI_ZIP" ]; then
	echo "Downloading Android command-line tools..."
	wget -q "https://dl.google.com/android/repository/commandlinetools-linux-8512546_latest.zip" -O "$CLI_ZIP"
fi
unzip -q "$CLI_ZIP"
# Move cmdline-tools into place (some zips produce a top-level 'cmdline-tools' dir)
mkdir -p "${ANDROID_SDK_ROOT}/cmdline-tools"
mv cmdline-tools "${ANDROID_SDK_ROOT}/cmdline-tools/latest" 2>/dev/null || true
export ANDROID_SDK_ROOT
export PATH="${ANDROID_SDK_ROOT}/cmdline-tools/latest/bin:${ANDROID_SDK_ROOT}/platform-tools:${PATH}"

# Install platform tools and SDK components
SDKMANAGER="${ANDROID_SDK_ROOT}/cmdline-tools/latest/bin/sdkmanager"
if [ -x "$SDKMANAGER" ]; then
	echo "Accepting Android SDK licenses and installing platforms..."
	yes | "$SDKMANAGER" --sdk_root="${ANDROID_SDK_ROOT}" --licenses || true
	"$SDKMANAGER" --sdk_root="${ANDROID_SDK_ROOT}" "platform-tools" "platforms;android-33" "build-tools;33.0.0"
else
	echo "sdkmanager not found; ensure Android command-line tools installed correctly."
fi

# Install Flutter by cloning stable channel (idempotent)
FLUTTER_DIR="${HOME}/flutter"
if [ ! -d "$FLUTTER_DIR" ]; then
	echo "Cloning Flutter (stable)..."
	git clone https://github.com/flutter/flutter.git -b stable "$FLUTTER_DIR"
else
	echo "Flutter already installed at $FLUTTER_DIR — pulling latest stable..."
	git -C "$FLUTTER_DIR" pull origin stable || true
fi
export PATH="${FLUTTER_DIR}/bin:${PATH}"

# Persist PATH and Android variables to shell profile
SHELL_PROFILE="${HOME}/.bashrc"
if [ -n "${ZSH_VERSION-}" ]; then
	SHELL_PROFILE="${HOME}/.zshrc"
fi
if ! grep -q '## flutter and android sdk' "$SHELL_PROFILE" 2>/dev/null; then
	cat >> "$SHELL_PROFILE" <<'EOF'
## flutter and android sdk
export ANDROID_SDK_ROOT="$HOME/Android/Sdk"
export PATH="$HOME/flutter/bin:$ANDROID_SDK_ROOT/cmdline-tools/latest/bin:$ANDROID_SDK_ROOT/platform-tools:$PATH"
EOF
	echo "Updated $SHELL_PROFILE with Flutter and Android SDK paths."
fi

# Run quick flutter checks (non-fatal if they fail inside CI/container)
echo "Running 'flutter --version' and 'flutter doctor' (these may download artifacts)..."
"${FLUTTER_DIR}/bin/flutter" --version || true
"${FLUTTER_DIR}/bin/flutter" doctor || true

echo "Install script finished. Restart your shell or run: source $SHELL_PROFILE"


