# try.sh — fzf-powered lightweight experiment manager

![Shell](https://img.shields.io/badge/shell-bash-blue?logo=gnu-bash)
![License](https://img.shields.io/badge/license-MIT-green)
![fzf](https://img.shields.io/badge/dependency-fzf-orange)
![git](https://img.shields.io/badge/dependency-git-lightgrey)

*Your experiments deserve a home.* 🏠

> A minimalist Bash reimplementation of [tobi/try](https://github.com/tobi/try), using `fzf` for navigation.  
> Designed for developers who like to spin up quick, disposable projects and keep them somewhat organized.

---

## ✨ What It Does

Tired of directories like `test`, `test2`, `new-test`, or `tmp-stuff` scattered everywhere?

**try.sh** creates and manages timestamped folders for your experiments:
- **Instant fuzzy search** via [`fzf`](https://github.com/junegunn/fzf)
- **Smart age display** (days, weeks, months)
- **Auto-dated directories** (`2025-11-10-my-experiment`)
- **Quick project cloning** via Git
- **Simple Bash script — no dependencies beyond fzf and git**

---

## 🚀 Quick Start

```bash
curl -sL https://raw.githubusercontent.com/c4software/try.sh/main/try.sh -o ~/.local/bin/try
chmod +x ~/.local/bin/try

echo "source ~/.local/bin/try" >> ~/.bashrc  # or ~/.zshrc
````

### Dependencies

* `fzf` (for interactive selection)
* `git` (for cloning repositories)
* [`gum`](https://github.com/charmbracelet/gum) (for deletion confirmation prompts)

---

## 🧠 Usage

```bash
try                     # Browse and open experiments interactively
try <query>             # Search for a matching directory or create it
try clone <uri> [name]  # Clone a git repository into TRY_PATH
try list                # List all projects with size and last modified date
try --help              # Show help
```

Examples:

```bash
try redis
try clone https://github.com/tobi/try.git
try list
```

---

## 🧭 Example session

```bash
$ try redis
→ 2025-11-09-redis-cache         1d, 22.3 MB
  2025-10-30-redis-test          2w, 18.5 MB
  ➕ Create new
```

Press <kbd>Enter</kbd> to open, or create a new project if none exists.

---

## 🛠️ Features

### 🔍 Fuzzy Project Search

* Real-time search powered by `fzf`
* Displays project age and size
* Delete projects with <kbd>Ctrl-D</kbd>
* Automatically creates new directories if no match is found

### 🕓 Smart Date Prefixes

* Automatically prefixes new projects with today’s date:

  ```
  2025-11-10-laravel-playground
  ```

### 🧰 Git Integration

Clone repositories directly:

```bash
try clone https://github.com/user/repo.git
# → ~/src/tries/2025-11-10-user-repo
```

### 🗑️ Safe Deletion

Delete projects directly from the TUI with <kbd>Ctrl-D</kbd> (confirmation required).

---

## ⚙️ Configuration

Change the default storage path:

```bash
export TRY_PATH=~/code/experiments
```

Default: `~/src/tries`

---

## 🧩 Keyboard Shortcuts

| Key / Combo     | Action                          |
| --------------- | ------------------------------- |
| ↑ / ↓, Ctrl+J/K | Navigate                        |
| Enter           | Open or create a project        |
| Ctrl+D          | Delete a project (confirmation) |
| Esc / Ctrl+C    | Cancel / quit                   |

---

## 💡 Philosophy

You have ideas. You try things. You forget where you put them.
**try.sh** brings order to creative chaos — every experiment gets a name, a date, and a home.

---

## 📝 License

MIT — do whatever you want with it.

---

### Credits

* Original concept and design: [tobi/try](https://github.com/tobi/try) (Ruby version)
* Bash reimplementation by [@c4software](https://github.com/c4software)
