#!/bin/bash

# This script is used to switch between different Kubernetes contexts by managing the ~/.kube/config file.
# It uses a directory defined by the KUBE_CONFIG_VAULT environment variable to store the context files.
# When the `KUBE_CONFIG_VAULT` variable is not set, it defaults to ~/.local_kube_vault.
# The script also provides a help message for usage instructions.
# Usage: ./kubeswitch.sh COMMAND <CONTEXT_NAME>
# Commands:
#   list: List all available contexts.
#   apply: Apply to a specified context.
#   delete: Delete a specified context.
#   save: save to a new context.
#   help: Show this help message.
# Context names are derived from the directory structure under the KUBE_CONFIG_VAULT directory which is case-insensitive.
# Example:
#   ./kubeswitch.sh list
#   ./kubeswitch.sh apply my-context
#   ./kubeswitch.sh delete my-context
#   ./kubeswitch.sh save my-context
# Logic:
# 1. Check if KUBE_CONFIG_VAULT is set, if not, set it to ~/.local_kube_vault inside the script.
# 2. Check if the directory exists, if not, create it.
# 3. Check if the command is valid (list, apply, delete, save).
# 4. For the list command, list all subdirectories in the KUBE_CONFIG_VAULT directory.
# 5. For the apply command, check if the context exists, if so, copy the config file KUBE_CONFIG_VAULT/<context>/config to ~/.kube/config.
# 6. For the delete command, check if the context exists, if so, delete the directory KUBE_CONFIG_VAULT/<context>.
# 7. For the save command, check if the context exists, if not, create folder KUBE_CONFIG_VAULT/<context> first, then copy the config file ~/.kube/config to KUBE_CONFIG_VAULT/<context>/config.
# 8. If the command is not recognized, show the help message.
# 9. If the context name is not provided, show the help message.
# 10. If the context name is not found, show an error message.
# 11. If operation succeeds, show a success message.

# Set default KUBE_CONFIG_VAULT if not set
KUBE_CONFIG_VAULT=${KUBE_CONFIG_VAULT:-~/.local_kube_vault}

# Ensure the KUBE_CONFIG_VAULT directory exists
if [ ! -d "$KUBE_CONFIG_VAULT" ]; then
  mkdir -p "$KUBE_CONFIG_VAULT"
fi

# Function to show help message
show_help() {
  echo "Usage: $0 COMMAND <CONTEXT_NAME>"
  echo "Commands:"
  echo "  list: List all available contexts."
  echo "  apply: Apply to a specified context."
  echo "  delete: Delete a specified context."
  echo "  save: Save to a new context."
  echo "  help: Show this help message."
}

# Function to list all contexts
list_contexts() {
  echo "Available contexts:"
  ls "$KUBE_CONFIG_VAULT"
}

# Function to apply a context
apply_context() {
  local context=$1
  if [ -d "$KUBE_CONFIG_VAULT/$context" ]; then
    cp "$KUBE_CONFIG_VAULT/$context/config" ~/.kube/config
    echo "Switched to context '$context'."
  else
    echo "Context '$context' not found."
  fi
}

# Function to delete a context
delete_context() {
  local context=$1
  if [ -d "$KUBE_CONFIG_VAULT/$context" ]; then
    rm -rf "${KUBE_CONFIG_VAULT:?}/$context"
    echo "Deleted context '$context'."
  else
    echo "Context '$context' not found."
  fi
}

# Function to save the current context
save_context() {
  local context=$1
  if [ ! -d "$KUBE_CONFIG_VAULT/$context" ]; then
    mkdir -p "$KUBE_CONFIG_VAULT/$context";
  fi
  cp ~/.kube/config "$KUBE_CONFIG_VAULT/$context/config"
  echo "Saved current context as '$context'."
}

# Main script logic
case $1 in
  list)
    list_contexts
    ;;
  apply)
    if [ -z "$2" ]; then
      show_help
    else
      apply_context "$2"
    fi
    ;;
  delete)
    if [ -z "$2" ]; then
      show_help
    else
      delete_context "$2"
    fi
    ;;
  save)
    if [ -z "$2" ]; then
      show_help
    else
      save_context "$2"
    fi
    ;;
  help|*)
    show_help
    ;;
esac

