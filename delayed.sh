#!/usr/bin/env bash
set -euo pipefail

system="${1:-x86_64-linux}"

echo "Running post-checks for $system"

# Step 1: Reference the correct system-specific lib (using packages.${system}.lib)
libPath=$(nix eval --raw .#packages.${system}.lib)

# Step 2: Build the 'tests' output from that lib, without linking it to ./result
testDrv=$(nix build --no-link --print-out-paths "$libPath.tests")

# Step 3: Check if the test output has a DELAYED marker file
if [ -f "$testDrv/DELAYED" ]; then
  echo "⚠️  Found DELAYED tests. Attempting to run them..."

  script="$testDrv/run-delayed-tests.sh"

  # Step 4: If the script is executable, run it
  if [ -x "$script" ]; then
    "$script"
  else
    echo "❌ No executable run-delayed-tests.sh found in $testDrv"
    exit 1
  fi
else
  echo "✅ No delayed tests. All handled by nix flake check."
fi
