#!/usr/bin/env bash

set -e

usage() {
    echo "Usage: $0 {apply|delete}"
    echo "  apply  - Deploy all agents (RBAC, agents, example queries)"
    echo "  delete - Remove all agents (RBAC, agents, example queries)"
    exit 1
}

if [ $# -ne 1 ]; then
    usage
fi

ACTION=$1
AGENTS_DIR="agents"
AGENTS=$(find "$AGENTS_DIR" -mindepth 1 -maxdepth 1 -type d | sed 's|.*/||')

case "$ACTION" in
    apply)
        echo "Deploying all agents..."
        for agent in $AGENTS; do
            echo "Deploying $agent..."
            [ -f "$AGENTS_DIR/$agent/rbac.yaml" ] && kubectl apply -f "$AGENTS_DIR/$agent/rbac.yaml"
            [ -f "$AGENTS_DIR/$agent/agent.yaml" ] && kubectl apply -f "$AGENTS_DIR/$agent/agent.yaml"
            if [ -d "$AGENTS_DIR/$agent/queries" ]; then
                for query in "$AGENTS_DIR/$agent/queries"/*.yaml; do
                    [ -f "$query" ] && kubectl apply -f "$query"
                done
            fi
        done
        echo "All agents deployed."
        ;;
    delete)
        echo "Deleting all agents..."
        for agent in $AGENTS; do
            echo "Removing $agent..."
            if [ -d "$AGENTS_DIR/$agent/queries" ]; then
                for query in "$AGENTS_DIR/$agent/queries"/*.yaml; do
                    [ -f "$query" ] && kubectl delete -f "$query" --ignore-not-found=true
                done
            fi
            [ -f "$AGENTS_DIR/$agent/agent.yaml" ] && kubectl delete -f "$AGENTS_DIR/$agent/agent.yaml" --ignore-not-found=true
            [ -f "$AGENTS_DIR/$agent/rbac.yaml" ] && kubectl delete -f "$AGENTS_DIR/$agent/rbac.yaml" --ignore-not-found=true
        done
        echo "All agents removed."
        ;;
    *)
        usage
        ;;
esac
