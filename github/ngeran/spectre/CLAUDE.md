# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Spectre is a minimalist dotfile manager written in Bash. It uses a bare Git repository approach to track configuration files in the user's home directory without symlinks or additional abstraction layers.

## Core Architecture

The entire system consists of a single 56-line Bash script (`install.sh`) that sets up a Git alias pointing to a bare repository stored at `~/.spectre_repo`. The user's home directory (`$HOME`) serves as the Git working tree.

The core alias created:
```bash
alias spectre='/usr/bin/git --git-dir=$HOME/.spectre_repo/ --work-tree=$HOME'
```

This allows users to use standard Git commands (add, commit, push, etc.) through the `spectre` command to manage their dotfiles.

## Installation and Testing

Install:
```bash
chmod +x install.sh
./install.sh
source ~/.bashrc  # or restart terminal
```

There are no automated tests. Validation is manual:
1. Run the installation script
2. Verify the alias works: `spectre status`
3. Verify the guide was created: `~/SPECTRE_README.md`

## Key Files

- **`install.sh`**: The entire implementation. Creates bare repo, configures Git, adds shell alias, generates user guide.
- **`README.md`**: User-facing documentation with installation and basic usage.
- **`.gitignore`**: Security/privacy exclusions for sensitive files (SSH keys, GPG keys, browser data, history files, etc.)
- **`~/SPECTRE_README.md`**: Generated during installation - a quick reference guide placed in the user's home directory.

## Security Considerations

The `.gitignore` file is critical for security. It excludes:
- Credentials: `.ssh/`, `.gnupg/`, `.aws/`, `.netrc`
- Browser data: `.mozilla/`, Chrome/Chromium configs (session cookies, passwords)
- History files: `.bash_history`, `.zsh_history` (may contain typed passwords)
- App secrets: GitHub hosts, Keybase configs

**Before modifying `.gitignore`**: Consider whether tracking a file could expose sensitive data.

## Design Philosophy

1. **Zero dependencies**: Uses only system Git
2. **Convention over configuration**: Standard Git workflow, no custom commands
3. **Minimalism**: Single script, <60 lines
4. **User's home as working tree**: Files appear exactly where they should be, no symlinks

## Common Modifications

When making changes:
1. **Add to shell integration**: Modify the `SHELL_CONFIGS` array in `install.sh:22`
2. **Change repo location**: Modify `DOT_DIR` in `install.sh:4`
3. **Adjust Git behavior**: The `status.showUntrackedFiles no` config at `install.sh:19` hides untracked files by default (prevents clutter)
