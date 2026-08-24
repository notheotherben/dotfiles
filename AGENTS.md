# Dotfiles for MacOS and CachyOS
This repository contains dotfiles which are managed via [chezmoi](https://www.chezmoi.io/)
to configure my personal environment on both MacOS and CachyOS.

## Change Process
1. Make changes to the local dotfiles on the system and validate their behaviour.
2. Make those same changes to the dotfiles in this repository.
3. Commit the changes to the repository and push them to the `main` branch.
4. Run `chezmoi update` on the system to apply the changes from the repository to the local dotfiles (this will also update the `~/.local/share/chezmoi` repo state).

NEVER MAKE CHANGES DIRECTLY TO `~/.local/share/chezmoi`.