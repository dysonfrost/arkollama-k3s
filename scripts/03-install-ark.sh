#!/usr/bin/env bash

set -e

echo "📥 Checking for Helm..."
if ! command -v helm &> /dev/null; then
    echo "❌ Helm is not installed. Please install it first:"
    echo "   https://helm.sh/docs/intro/install/"
    exit 1
fi
echo "✅ Helm found."

echo "📥 Installing ARK CLI..."
npm install -g @agents-at-scale/ark@latest

echo "🔧 Installing ARK components into the cluster..."
# The install command will also check for other dependencies
ark install

echo "📊 ARK status:"
ark status
