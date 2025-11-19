#!/usr/bin/env bash
set -euo pipefail

# install.gradle.sh
# Installs Gradle to /opt/gradle and configures PATH. Idempotent and configurable via GRADLE_VERSION.

if [ "$(uname -s)" != "Linux" ]; then
  echo "This script supports Linux only. Exiting."
  exit 0
fi

GRADLE_VERSION=${GRADLE_VERSION:-8.1}
INSTALL_DIR=${INSTALL_DIR:-/opt/gradle}

has_gradle() {
  if ! command -v gradle >/dev/null 2>&1; then
    return 1
  fi
  ver=$(gradle --version 2>/dev/null | awk '/Gradle/{print $2; exit}') || true
  [ -z "$ver" ] && return 1
  # compare major.minor simply by string if needed; assume installed version ok
  return 0
}

if has_gradle; then
  echo "Gradle found: $(gradle --version | awk 'NR==1{print $0}') — skipping install."
  exit 0
fi

echo "Installing Gradle ${GRADLE_VERSION} to ${INSTALL_DIR}..."
sudo apt-get update
sudo apt-get install -y unzip wget || true

TMPZIP="/tmp/gradle-${GRADLE_VERSION}-bin.zip"
if [ ! -f "$TMPZIP" ]; then
  echo "Downloading Gradle ${GRADLE_VERSION}..."
  wget -q "https://services.gradle.org/distributions/gradle-${GRADLE_VERSION}-bin.zip" -O "$TMPZIP"
fi

sudo mkdir -p "$INSTALL_DIR"
sudo unzip -o "$TMPZIP" -d "$INSTALL_DIR"
sudo ln -sfn "$INSTALL_DIR/gradle-${GRADLE_VERSION}" "$INSTALL_DIR/latest"

# Create profile.d so all users get gradle (if possible)
GRADLE_PROFILE=/etc/profile.d/gradle.sh
if sudo test -w /etc/profile.d || sudo test -d /etc/profile.d; then
  sudo bash -c "cat > $GRADLE_PROFILE <<'EOF'
#!/usr/bin/env bash
export GRADLE_HOME=\"${INSTALL_DIR}/latest\"
export PATH=\"$GRADLE_HOME/bin:$PATH\"
EOF"
  sudo chmod +x $GRADLE_PROFILE || true
  echo "Wrote $GRADLE_PROFILE"
else
  # fallback to per-user ~/.bashrc
  if ! grep -q 'gradle/bin' "$HOME/.bashrc" 2>/dev/null; then
    cat >> "$HOME/.bashrc" <<EOF
# Gradle
export GRADLE_HOME="$INSTALL_DIR/latest"
export PATH="\$GRADLE_HOME/bin:\$PATH"
EOF
    echo "Appended Gradle PATH to ~/.bashrc"
  fi
fi

echo "Gradle installation complete. gradle --version:";
gradle --version || true
