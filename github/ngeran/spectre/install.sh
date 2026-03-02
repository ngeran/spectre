#!/bin/bash

# Configuration
DOT_DIR="$HOME/.spectre_repo"
README_FILE="$HOME/SPECTRE_README.md"
ALIAS_LINE="alias spectre='/usr/bin/git --git-dir=$DOT_DIR/ --work-tree=$HOME'"
LAZYGIT_ALIAS_LINE="alias lazygit-spectre='GIT_DIR=$DOT_DIR GIT_WORK_TREE=\$HOME lazygit'"

echo "👻 Initializing SPECTRE..."

# 1. Create the bare repo
if [ ! -d "$DOT_DIR" ]; then
    git init --bare "$DOT_DIR"
    echo "✅ Bare repository created at $DOT_DIR"
else
    echo "ℹ️  Spectre repository already exists at $DOT_DIR"
fi

# 2. Setup the internal config
/usr/bin/git --git-dir="$DOT_DIR/" --work-tree="$HOME" config --local status.showUntrackedFiles no

# 3. Add alias to shell configs
SHELL_CONFIGS=("$HOME/.bashrc" "$HOME/.zshrc")
for CONFIG in "${SHELL_CONFIGS[@]}"; do
    if [ -f "$CONFIG" ]; then
        if ! grep -q "alias spectre=" "$CONFIG"; then
            echo -e "\n# Spectre Dotfile Manager\n$ALIAS_LINE\n$LAZYGIT_ALIAS_LINE" >> "$CONFIG"
            echo "✅ Alias added to $CONFIG"
        fi
    fi
done

# 4. Generate the instruction file in $HOME
cat << EOF > "$README_FILE"
# 👻 SPECTRE MANAGEMENT GUIDE

## 📂 Tracking New Files
To start tracking a file (e.g., your .bashrc):
\`spectre add .bashrc\`

## 📁 Tracking New Folders
To track an entire configuration folder (e.g., nvim or bspwm):
\`spectre add .config/nvim\`
*Note: This will recursively add all files within that directory.*

## 💾 Saving Changes
1. **Check what changed:** \`spectre status\`
2. **Commit:** \`spectre commit -m "Added nvim configs"\`
3. **Push:** \`spectre push\` (after setting up a remote)

## ❌ Stop Tracking
If you want to stop tracking a file but **keep the local file** on your disk:
\`spectre rm --cached .filename\`

## 🎨 Lazygit Integration
If you have lazygit installed, use \`lazygit-spectre\` for a TUI interface:
\`lazygit-spectre\`
EOF

echo "📝 Management guide created at $README_FILE"
echo "🚀 Setup complete! Run 'source ~/.bashrc' or restart your terminal."
