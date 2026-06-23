#!/usr/bin/env bash
# git-operations.sh — a SAFE, self-contained Git drill for CompTIA Linux+ (XK0-006)
#
# Builds a throwaway repo in a temp folder, walks the full lifecycle, quizzes you,
# and cleans up. Nothing here touches your real repos, your SSH keys, or your
# global git config. Push/pull are practiced against a LOCAL simulated remote,
# so no GitHub account or authentication is needed.
#
# Usage:
#   bash git-operations.sh          # guided, pauses between steps
#   FAST=1 bash git-operations.sh   # run straight through, no pauses
#
# Built for Marty Emale's Linux-Lab.

set -o pipefail

# ---------- presentation helpers ----------
if [ -t 1 ]; then
  BOLD=$'\033[1m'; CYAN=$'\033[1;36m'; GREEN=$'\033[1;32m'
  YELLOW=$'\033[1;33m'; DIM=$'\033[2m'; RESET=$'\033[0m'
else
  BOLD=; CYAN=; GREEN=; YELLOW=; DIM=; RESET=
fi

INTERACTIVE=1
[ -t 0 ] || INTERACTIVE=0
[ "${FAST:-0}" = "1" ] && INTERACTIVE=0

pause(){ [ "$INTERACTIVE" = "1" ] || return 0; printf "%s" "${DIM}   (press Enter to continue)${RESET}"; read -r _; }
say(){ printf "\n%s\n" "${BOLD}=== $* ===${RESET}"; }
note(){ printf "   %s\n" "${DIM}$*${RESET}"; }
linuxplus(){ printf "   %sLinux+:%s %s\n" "${YELLOW}" "${RESET}" "$*"; }
run(){ printf "\n%s\n" "${CYAN}\$ $1${RESET}"; eval "$1"; }

# ---------- safe scratch workspace ----------
LAB="$(mktemp -d "${TMPDIR:-/tmp}/gitdrill.XXXXXX")"
cleanup(){ [ -n "${LAB:-}" ] && rm -rf "$LAB"; }
trap 'printf "\n"; cleanup; exit 130' INT TERM
cfg(){ git config user.name "Linux Lab"; git config user.email "lab@example.com"; }

say "Git Operations Drill"
note "Scratch repo: $LAB"
note "Safe sandbox — your real repos and ~/.ssh are untouched."
pause

# ---------- 1) init ----------
say "1) Create a repository (git init)"
run "mkdir -p '$LAB/shop' && cd '$LAB/shop' && git init -b main"
cd "$LAB/shop"; cfg
run "ls -la"
linuxplus "the hidden .git directory IS the repository; 'ls -a' reveals dotfiles."
pause

# ---------- 2) the three trees ----------
say "2) Working directory -> staging -> repository"
run "echo '# Shoppers Choice' > README.md"
run "printf '<h1>Home</h1>\n' > index.html"
run "git status"
linuxplus "brand-new files are UNTRACKED until you add them."
pause
run "git add README.md index.html"
run "git status"
linuxplus "'git add' moves changes into the STAGING area (the index)."
pause
run "git commit -m 'Initial prototype'"
run "git log --oneline"
linuxplus "'git commit' writes a permanent snapshot identified by a unique hash."
pause

# ---------- 3) modify + diff ----------
say "3) Change a file and inspect the diff"
run "printf '<h1>Home</h1>\n<nav>Home | Insights | Owed</nav>\n' > index.html"
run "git status"
run "git diff"
linuxplus "'git diff' shows working-directory changes not yet staged (+added / -removed)."
pause
run "git add index.html && git commit -m 'Add Insights nav'"
run "git log --oneline"
pause

# ---------- 4) .gitignore ----------
say "4) Keep secrets/artifacts out of version control (.gitignore)"
run "printf 'secrets.env\n*.log\n' > .gitignore"
run "echo 'API_KEY=do-not-commit' > secrets.env"
run "echo 'startup noise' > app.log"
run "git status"
note "Notice: secrets.env and app.log do NOT appear — they are ignored."
linuxplus "ignoring keys and logs is a Security-domain habit; never commit credentials."
run "git add .gitignore && git commit -m 'Add gitignore'"
pause

# ---------- 5) branch + merge ----------
say "5) Branch, switch, commit, merge"
run "git switch -c feature-owed"
linuxplus "'git switch -c' creates AND moves to a branch (older syntax: 'git checkout -b')."
run "printf '<h1>Home</h1>\n<nav>Home | Insights | Owed</nav>\n<section>Owed list</section>\n' > index.html"
run "git commit -am 'Build Owed screen'"
note "'git commit -am' = stage tracked changes + commit in one step."
run "git switch main"
run "cat index.html"
note "Back on main, the Owed section is gone — branches are isolated."
pause
run "git merge feature-owed -m 'Merge Owed screen'"
run "cat index.html"
run "git log --oneline --graph --all"
linuxplus "'git merge' integrates a branch's commits back into main."
pause

# ---------- 6) undo safely ----------
say "6) Undoing changes (restore / unstage)"
run "echo 'oops, bad edit' >> index.html"
run "git status"
run "git restore index.html"
note "Discarded the unstaged edit — file is back to its last commit."
pause
run "echo 'staged but unwanted' >> README.md && git add README.md"
run "git restore --staged README.md"
linuxplus "'git restore --staged' unstages a file without losing the edit."
run "git restore README.md"
note "Then restore the working copy too — README is clean again."
pause

# ---------- 7) remotes, simulated locally (no GitHub, no auth) ----------
say "7) Remotes: push & pull, simulated locally (no GitHub, no keys)"
run "git init --bare -b main '$LAB/origin.git' >/dev/null 2>&1 && echo 'created bare repo (stand-in for GitHub)'"
linuxplus "a BARE repo holds history with no working files — what a server/GitHub stores."
run "git remote add origin '$LAB/origin.git'"
run "git push -u origin main"
note "This 'push' is exactly the step the GitHub upload button hid from you."
pause
run "git clone '$LAB/origin.git' '$LAB/teammate' >/dev/null 2>&1 && echo 'a teammate cloned the repo'"
( cd "$LAB/teammate" && cfg && printf 'teammate line\n' >> index.html && git commit -am 'teammate edit' >/dev/null 2>&1 && git push >/dev/null 2>&1 )
note "The teammate pushed a change up to origin..."
run "git pull"
note "'git pull' fetched + merged their commit into your repo."
run "git log --oneline"
pause

# ---------- 8) self-check ----------
say "8) Self-check (XK0-006 style)"
quiz(){ printf "\n%sQ: %s%s\n" "${BOLD}" "$1" "${RESET}"; pause; printf "%sA: %s%s\n" "${GREEN}" "$2" "${RESET}"; }
quiz "Move a modified file into the staging area?" "git add <file>"
quiz "Where does 'git commit' write, and what identifies the snapshot?" "the repository/history; a unique commit hash"
quiz "See unstaged changes line-by-line?" "git diff"
quiz "Create and switch to a new branch in one command?" "git switch -c <name>   (or git checkout -b <name>)"
quiz "Discard an unwanted, unstaged edit to a tracked file?" "git restore <file>"
quiz "Send local commits up to a remote?" "git push <remote> <branch>"
quiz "Required permission on a private SSH key, or SSH refuses it?" "600  (and ~/.ssh must be 700)"

# ---------- teardown ----------
say "Drill complete"
if [ "$INTERACTIVE" = "1" ]; then
  printf "Delete the scratch folder %s ? [Y/n] " "$LAB"; read -r ans
  case "$ans" in
    [Nn]*) printf "Kept at: %s\n" "$LAB" ;;
    *)     cleanup; echo "Cleaned up." ;;
  esac
else
  cleanup; echo "Cleaned up scratch folder."
fi
