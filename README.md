# Daymark

Daymark is a compact calendar widget for Quickshell on Linux. It sits alongside your desktop panels and can expand into a full month view.

## Features

- Month navigation and a six-week calendar grid
- Ten animated color themes
- Adjustable screen corner and X/Y offsets
- Double-click a date to add an event and local 24-hour time
- Desktop notification at the event time and a follow-up five minutes later
- Raised controls and theme-colored frame details

## Requirements

- Linux running a Wayland compositor
- Quickshell 0.3 or later
- `notify-send` from `libnotify` for desktop reminders
- A notification daemon for notifications to appear in the desktop

On Arch Linux, install the runtime dependencies with:

```sh
sudo pacman -S quickshell libnotify
```

On other distributions, install Quickshell and libnotify using that distribution's package manager. Daymark itself installs into your home directory and does not require root access.

## Install

Download and extract the repository archive from GitHub, or clone the repository. From the project directory, run:

```sh
sh install.sh
```

The installer copies the config to `${XDG_CONFIG_HOME:-~/.config}/quickshell/daymark`, installs a desktop-menu launcher, and leaves other Quickshell configurations untouched. It refuses to overwrite an existing directory unless that directory was created by this installer.

Start Daymark from your applications menu, or run:

```sh
qs --no-duplicate --config daymark
```

To update an existing installation, run `sh install.sh` again from the newer project directory.

## Use

- Click the compact date tile or `+` to expand the calendar.
- Use the month arrows to browse. Select **Now** to return to the device's current local month.
- Double-click a date to create or edit its event. Enter the time in 24-hour `HH:MM` format.
- A notification is scheduled for the event time, followed by another five minutes later. Keep Daymark running for reminders.
- Open settings with `S` to choose a theme and adjust the widget's corner and pixel offsets.

The initial calendar includes a few sample events. Events created in the editor are currently held in memory and do not survive closing or restarting Quickshell.

## Uninstall

From the project directory, run:

```sh
sh uninstall.sh
```

This stops the Daymark Quickshell config, removes its installed files and desktop launcher, and does not remove or modify other Quickshell configs.

## License

Daymark is released under the MIT License. See [LICENSE](LICENSE).