#!/usr/bin/env zsh
set -euo pipefail

echo "👉 Bootstrap started"

# --- Check tools ---
echo ""
echo "👉 Checking cli tools"

# Homebrew
if ! command -v brew >/dev/null 2>&1; then
  echo "    Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
else
  echo "    ✔️ Homebrew already installed"
fi

# Ensure brew is available immediately after install
if [[ -x /opt/homebrew/bin/brew ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [[ -x /usr/local/bin/brew ]]; then
  eval "$(/usr/local/bin/brew shellenv)"
fi

# Age
if ! command -v age >/dev/null 2>&1; then
  echo "    Installing Age..."
  brew install age
else
  echo "    ✔️ Age already installed"
fi

# Bitwarden CLI
if ! command -v bw >/dev/null 2>&1; then
  echo "    Installing Bitwarden CLI..."
  brew install bitwarden-cli
else
  echo "    ✔️ Bitwarden CLI already installed"
fi

# jq
if ! command -v jq >/dev/null 2>&1; then
  echo "    Installing jq..."
  brew install jq
else
  echo "    ✔️ jq already installed"
fi

# --- Bitwarden login ---
echo ""
echo "👉 Check Bitwarden status"

bw_status=$(bw status 2>/dev/null | jq -r '.status // "unauthenticated"' 2>/dev/null || echo "unauthenticated")

if [[ "$bw_status" == "unauthenticated" ]]; then
  echo ""
  echo "👉 Logging into Bitwarden"
  bw login

  bw_status=$(bw status | jq -r .status)
fi

# --- Unlock ---
if [[ "$bw_status" != "unlocked" ]]; then
  echo ""
  echo "👉 Unlocking Bitwarden"
  BW_SESSION=$(bw unlock --raw) || {
    echo "    ❌ Failed to unlock Bitwarden"
    exit 1
  }

export BW_SESSION
  
  bw_status=$(bw status | jq -r .status)
fi

# --- Retrieve age private key ---
echo ""
echo "👉 Retrieving age key"

key_path="$HOME/.config/chezmoi/age/key.txt"

# Ensure directory exists
mkdir -p "$(dirname "$key_path")"

# Remove file if it exists
rm -f "$key_path"

key=$(bw get notes chezmoi-age-key 2>/dev/null || true)

if [[ -z "$key" ]]; then
  echo "    ❌ Failed to retrieve age key from Bitwarden"
  exit 1
fi

umask 177
echo "$key" > "$key_path"

echo "    ✔️ Age key recreated"

# --- Setup chezmoi config ---
echo ""
echo "👉 Setting up chezmoi config"

chezmoi_config="$HOME/.config/chezmoi/chezmoi.toml"
pubkey=$(age-keygen -y "$key_path")

mkdir -p "$(dirname "$chezmoi_config")"

cat > "$chezmoi_config" <<EOF
encryption = "age"
[age]
    identity = "$key_path"
    recipients = ["$pubkey"]
EOF

echo "    ✔️ chezmoi config recreated"

# --- Apply chezmoi config ---
echo ""
echo "👉 Applying chezmoi config"

chezmoi apply

echo "✅ Bootstrap complete"
