#!/usr/bin/env bash
set -euo pipefail

# install.java.sh
# Idempotent installer for OpenJDK (suitable for Android build tooling)

if [ "$(uname -s)" != "Linux" ]; then
  echo "This script supports Linux only. Exiting."
  exit 0
fi

JAVA_MIN_MAJOR=${JAVA_MIN_MAJOR:-11}

detect_java_major() {
  if ! command -v java >/dev/null 2>&1; then
    echo "0"
    return
  fi
  ver=$(java -version 2>&1 | awk -F '"' 'NR==1{print $2}')
  major=${ver%%.*}
  echo "$major"
}

current=$(detect_java_major)
if [ "$current" != "0" ] && [ "$current" -ge "$JAVA_MIN_MAJOR" ]; then
  echo "Java detected (major=$current) — skipping install."
  exit 0
fi

echo "Installing OpenJDK (>= ${JAVA_MIN_MAJOR}) and common tooling..."
sudo apt-get update
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
  openjdk-17-jdk curl ca-certificates wget gnupg2 unzip xz-utils git || true

# Try to determine JAVA_HOME
if [ -x "$(command -v java)" ]; then
  JAVA_BIN=$(readlink -f "$(command -v java)")
  JAVA_HOME_CANDIDATE=$(dirname "$(dirname "$JAVA_BIN")")
  export JAVA_HOME="$JAVA_HOME_CANDIDATE"
else
  if [ -d "/usr/lib/jvm/java-17-openjdk-amd64" ]; then
    export JAVA_HOME="/usr/lib/jvm/java-17-openjdk-amd64"
  fi
fi

if [ -n "${JAVA_HOME-}" ]; then
  echo "Configured JAVA_HOME=$JAVA_HOME"
  if ! grep -q "export JAVA_HOME=\"$JAVA_HOME\"" "$HOME/.bashrc" 2>/dev/null; then
    printf "\n# Java home\nexport JAVA_HOME=\"%s\"\nexport PATH=\"%s/bin:$PATH\"\n" "$JAVA_HOME" "$JAVA_HOME" >> "$HOME/.bashrc"
    echo "Appended JAVA_HOME to ~/.bashrc"
  fi
fi

echo "Java install step completed. java -version:";
java -version || true
