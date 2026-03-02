# Spectre 👻

A minimalist, no-dependency dotfile manager using a Bare Git Repository.

---

## 🛠 Installation

### Step 1: Make the installer executable
```bash
cd /path/to/spectre
chmod +x install.sh
```

### Step 2: Run the installer
```bash
./install.sh
```

This will:
- Create a bare Git repository at `~/.spectre_repo`
- Add the `spectre` alias to your shell config (`.bashrc` and/or `.zshrc`)
- Add the `lazygit-spectre` alias (if you use lazygit)
- Create a quick reference guide at `~/SPECTRE_README.md`

### Step 3: Reload your shell
```bash
source ~/.bashrc
# or
source ~/.zshrc
```

Or simply restart your terminal.

### Step 4: Verify installation
```bash
spectre status
```

You should see "No commits yet" or similar output.

---

## 📖 How to Manage Your System

Spectre lives in your `$HOME` directory. To track something, simply use the relative path from Home.

### Adding Files/Folders

**Single File:**
```bash
spectre add .zshrc
```

**Entire Folder:**
```bash
spectre add .config/htop
```

### The Workflow

Once you've added files, treat it like any other Git project:

```bash
spectre status                         # See what's changed
spectre commit -m "update shortcuts"   # Save changes locally
spectre push                           # Upload to your private cloud
```

### Stopping Tracking

To stop tracking a file but **keep the local file** on your disk:

```bash
spectre rm --cached .filename
```

### Setting Up a Remote

To sync your dotfiles across machines:

```bash
spectre remote add origin git@github.com:username/dotfiles.git
spectre branch -M main
spectre push -u origin main
```

---

## 🎨 Lazygit Integration

If you have [lazygit](https://github.com/jesseduffield/lazygit) installed, Spectre includes a convenient alias:

```bash
lazygit-spectre
```

This opens lazygit with your Spectre repository, giving you a terminal UI to:
- Stage/unstage files
- View diffs
- Commit changes
- Push/pull from remotes

Your regular `lazygit` command is unaffected and works normally in other Git repositories.

---

## 📂 How It Works

Spectre uses a clever Git alias that points to a bare repository in `~/.spectre_repo` while treating your home directory as the working tree:

```bash
alias spectre='/usr/bin/git --git-dir=$HOME/.spectre_repo/ --work-tree=$HOME'
```

This means:
- Your dotfiles stay exactly where they belong
- No symlinks or file copying needed
- Full Git power for version control

The `.gitignore` file ensures sensitive data (SSH keys, browser data, history files) is never tracked.
