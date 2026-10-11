#!/bin/sh
set -eu

APP_ID="daymark"
CONFIG_HOME=${XDG_CONFIG_HOME:-"$HOME/.config"}
DATA_HOME=${XDG_DATA_HOME:-"$HOME/.local/share"}
CONFIG_DIR="$CONFIG_HOME/quickshell/$APP_ID"
DESKTOP_FILE="$DATA_HOME/applications/daymark.desktop"

if [ -f "$CONFIG_DIR/.daymark-install" ]; then
    if command -v qs >/dev/null 2>&1; then
        qs kill --config "$APP_ID" >/dev/null 2>&1 || true
    fi

    rm -f "$CONFIG_DIR/shell.qml" \
        "$CONFIG_DIR/Calendar.qml" \
        "$CONFIG_DIR/DepthButton.qml" \
        "$CONFIG_DIR/CornerFrame.qml" \
        "$CONFIG_DIR/.daymark-install"
    rmdir "$CONFIG_DIR" 2>/dev/null || true
else
    printf 'No Daymark installation marker found at %s\n' "$CONFIG_DIR"
fi

rm -f "$DESKTOP_FILE"
printf 'Daymark has been uninstalled. Other Quickshell configs were left untouched.\n'