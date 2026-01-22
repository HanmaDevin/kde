#!/usr/bin/env bash

packages=("ark" "dolphin" "dolphin-plugins" "dragon" "elisa" "ffmpegthumbs" "isoimagewriter" "konsole" "okular" "plasma")

for pkg in "${packages[@]}"; do
  sudo pacman -Rns --noconfirm "${pkg}"
done
