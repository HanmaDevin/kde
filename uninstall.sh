#!/usr/bin/env bash

packages=("ark" "dolphin" "dolphin-plugins" "dragon" "elisa" "ffmpegthumbs" "isoimagewriter" "konsole" "okular" "plasma" "kio-extras")

sudo pacman -Rns --noconfirm "${packages[@]}"

yay -Rns konsave
