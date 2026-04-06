# Misc Linux config

## Change caps key
gsettings set org.gnome.desktop.input-sources xkb-options "['caps:ctrl_modifier']"

## To add special chars to keyboard

Sourced from: https://lars.ingebrigtsen.no/2024/04/28/the-simplest-thing-in-the-world-modifing-keymaps-in-wayland/

Editing: ~/.config/xkb/symbols/us

```
partial alphanumeric_keys
xkb_symbols "deadtilde" {
    name[Group1]= "Dead Tilde (US)";
    include "us(basic)"
    key <TLDE> { [ grave, dead_tilde ] };
    key <RCTL> { [ dead_acute, dead_diaeresis ] };
};
```

then ran:

gsettings set org.gnome.desktop.input-sources sources "[('xkb', 'us')]"

Then restart

## To change caps lock to ctrl key

Caps lock is pointless, use a more ergonomic ctrl key.

gsettings set org.gnome.desktop.input-sources xkb-options "['caps:ctrl_modifier']"

## Keyboard mappings on hedless tty

On a headless setup, running debian 12 I did the following modifications on /etc/default/keyboard, it's just enough to be able to write basic words in spanish. Font in terminal and terminal also had to b modified via: sudo /usr/sbin/dpkg-reconfigure console-setup


These changes need a restart.

```
# KEYBOARD CONFIGURATION FILE

# Consult the keyboard(5) manual page.

XKBMODEL="pc105"
XKBLAYOUT="us"
XKBVARIANT=""
XKBOPTIONS="ctrl:nocaps, compose:rctrl"

BACKSPACE="guess"
```
