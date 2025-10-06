---
title: Music box
topic: "[[index|SteamDeck]]"
---

# Music box

## Project goal

Once I moved to linux, I wanted to replicate the music production environment i had under Windows.
Since I have multiple linux computers (laptops, Steam deck, ...) I wanted to be able to reproduce
the same environment on any of those computers (possibly from a single configuration file, more on
that later).

After doing a bit of digging, I settled on using [distrobox](https://distrobox.it/) as a container
in which I would install my environment.
The distro I choose for it is Arch linux as it's the one I'm the most familiar with.

## Setup

Assuming `distrobox` is already installed on the host system.

### Create the box

```shell
mkdir ~/musicbox
distrobox create --image archlinux:latest --name music-box --home ~/musicbox --unshare-groups
distrobox enter music-box
```

### Installing the packages

Start by installing a text editor (I use `neovim`)

```shell
sudo pacman -S neovim
```

Then add `multilib` sources to pacman (add those 2 lines if they don't exist) by editing
`sudo nvim /etc/pacman.conf`

```plaintext
[multilib]
Include = /etc/pacman.d/mirrorlist
```

And then run `sudo pacman -Syu`

Then install `yay` to get access to `AUR` packages

```shell
git clone https://aur.archlinux.org/yay.git
cd yay
makepkg -si
```

Finally install all the packages

```shell
sudo pacman -S realtime-privileges gtk3 pipewire pipewire-jack wireplumber qpwgraph supercollider yabridge yabridgectl wine-mono wine-staging
sudo pacman -S --needed base-devel git
yay -S bitwig-studio downgrade
```

## Configuration

### Pipewire jack config

Create the configuration file for `pw-jack`

```shell
mkdir -p ~/.config/pipewire/jack.conf.d/
nvim ~/.config/pipewire/jack.conf.d/custom.conf
```

Then paste the following (from the [pipewire documentation](https://docs.pipewire.org/page_man_pipewire-jack_conf_5.html))

```conf
jack.properties = {
    rt.prio             = 95
    node.latency        = 1024/48000
    #node.lock-quantum   = true
    #node.force-quantum  = 0
    #jack.show-monitor   = true
    #jack.merge-monitor  = true
    #jack.show-midi      = true
    #jack.short-name     = false
    #jack.filter-name    = false
    #jack.filter-char    = " "
    #
    # allow:           Don't restrict self connect requests
    # fail-external:   Fail self connect requests to external ports only
    # ignore-external: Ignore self connect requests to external ports only
    # fail-all:        Fail all self connect requests
    # ignore-all:      Ignore all self connect requests
    #jack.self-connect-mode  = allow
    #jack.locked-process     = true
    #jack.default-as-system  = false
    #jack.fix-midi-events    = true
    #jack.global-buffer-size = false
    #jack.passive-links      = false
    #jack.max-client-ports   = 768
    #jack.fill-aliases       = false
    #jack.writable-input     = false
    #jack.flag-midi2         = false
}
```

## Packages details

### List

- `realtime-privileges`
- `gtk3`
- `pipewire`
- `pipewire-jack`
- `wireplumber`
- `qpwgraph`
- `supercollider`
- [VCV rack](https://vcvrack.com/Rack)
- `neovim`
- `yabridge` (needs `multilib` enabled, see below)
- `yabridgectl` (needs `multilib` enabled, see below)
- `wine-staging`
- `wine-mono` (needs `multilib` enabled, see below)
- `downgrade` (from AUR)
- `bitwig-studio` or `bitwig-studio-earlyaccess` (from AUR)

### Qwpgraph

This is the a visual patchbay to use to manage connection between applications and system audio input / output.

> [!NOTE] If sound out from Bitwig (or another piece of software) doesn't work, check connections in qwpgraph

### Supercollider

Inside music-box, just run `pw-jack scide`. The status of pipewire can be checked in another terminal by running `pw-top`.

### Rack installation

Unziped Rack2 folder as ~/.local/share/VCV (and respective vst / clap things according to `INSTALL.txt` inside zip)
Created a launcher in /usr/bin

```bash
#!/bin/bash
cd ~/.local/share/VCV
pw-jack ./Rack
```

### Bitwig

I could not get the flatpak to play nice with distrobox so I installed it from AUR ([bitwig-studio package](https://aur.archlinux.org/packages/bitwig-studio))

```
sudo pacman -S --needed base-devel git
git clone https://aur.archlinux.org/yay.git
cd yay
makepkg -si
yay -S bitwig-studio
```

> [!NOTE] Bitwig needs GTK3 to show dialogs interacting with the file system, make sure the `gtk3` package is installed before running it

An early access version might exist, search with `yay -s bitwig`.
Also note that it is not needed to build when installing since pre-build binaries already exist.

### Yabridge

There may be a need to downgrade `wine-staging` for some plugins to work, follow [this](https://github.com/robbert-vdh/yabridge?tab=readme-ov-file#downgrading-wine) to do so (TLDR run `sudo env DOWNGRADE_FROM_ALA=1 downgrade wine-staging` after installing `downgrade` from AUR).

Also [Wine 9.22 and 10.x don't work with yabridge](https://github.com/robbert-vdh/yabridge?tab=readme-ov-file#troubleshooting-common-issues)

### VSTs / Clap

Use wine to install the plugin

`wine <path-to-exe>`

Add directory to yabridgectl (only once I think)

`yabridgectl add ~/.wine/drive/c/Program\ Files/Common\ Files/VST3` (for VST3)
`yabridgectl add ~/.wine/drive/c/Program\ Files/Common\ Files/Clap` (for Clap)

And then (each time a new plugin is installed)

`yabrigectl sync`

[Source](https://interfacinglinux.com/2024/01/22/windows-audio-plugins-on-linux-with-yabridge/)

## To do

- [x] Install VCV rack and Bitwig in there.
- Create applications that can be started from Steam to run supercollider, Bitwig and VCV rack.
- [x] Test VSTs
- [x] Fix save issue with Bitwig (was looking for libgtk3, fixed by installing gtk3 package)
- [ ] Look into [Cable](https://bbs.archlinux.org/viewtopic.php?id=304116) to manage pipewire configuration
- [ ] Try [optimized](https://wiki.linuxaudio.org/wiki/list_of_jack_frame_period_settings_ideal_for_usb_interface) values

## Troubleshoot

- If `Bitwig` or `Supercollider` can't talk to `pw-jack` anymore, try running `systemctl --user restart pipewire.socket` (also check in `qwpgraph` and `pw-top`)

## Links

- <https://roosnaflak.com/tech-and-research/transitioning-to-pipewire/>
- <https://gist.github.com/fsantand/846fbdd9ed2db5c89838b138a2e48ceb>
- <https://github.com/logon84/Pipewire-sound-sink-switcher/blob/main/sound_sink_switcher.sh>
- <https://github.com/mikeroyal/PipeWire-Guide?tab=readme-ov-file#installing-pipewire-on-arch-linux>
- <https://github.com/scottericpetersen/pro-audio-on-linux?tab=readme-ov-file>
- <https://gitlab.freedesktop.org/pipewire/pipewire/-/wikis/Config-PipeWire#quantum-ranges>
