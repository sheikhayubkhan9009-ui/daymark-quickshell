#!/bin/sh
set -eu

APP_ID="daymark"
SOURCE_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
CONFIG_HOME=${XDG_CONFIG_HOME:-"$HOME/.config"}
DATA_HOME=${XDG_DATA_HOME:-"$HOME/.local/share"}
CONFIG_DIR="$CONFIG_HOME/quickshell/$APP_ID"
DESKTOP_DIR="$DATA_HOME/applications"

for dependency in qs notify-send; do
    if ! command -v "$dependency" >/dev/null 2>&1; then
        printf 'Missing dependency: %s\n' "$dependency" >&2
        printf 'Install Quickshell and libnotify, then run this installer again.\n' >&2
        exit 1
    fi
done

for file in shell.qml Calendar.qml DepthButton.qml CornerFrame.qml daymark.desktop; do
    if [ ! -f "$SOURCE_DIR/$file" ]; then
        printf 'Required project file is missing: %s\n' "$file" >&2
        exit 1
    fi
done

if [ -e "$CONFIG_DIR" ] && [ ! -f "$CONFIG_DIR/.daymark-install" ]; then
    printf 'Refusing to overwrite an unmarked directory: %s\n' "$CONFIG_DIR" >&2
    printf 'Move it aside or inspect it before installing Daymark.\n' >&2
    exit 1
fi

mkdir -p "$CONFIG_DIR" "$DESKTOP_DIR"
for file in shell.qml Calendar.qml DepthButton.qml CornerFrame.qml; do
    install -m 644 "$SOURCE_DIR/$file" "$CONFIG_DIR/$file"
done
install -m 644 "$SOURCE_DIR/daymark.desktop" "$DESKTOP_DIR/daymark.desktop"
: > "$CONFIG_DIR/.daymark-install"

printf 'Daymark installed to %s\n' "$CONFIG_DIR"
printf 'Launch it with: qs --no-duplicate --config daymark\n'
printf 'A Daymark Calendar launcher is also available in your applications menu.\n'