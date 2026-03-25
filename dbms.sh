#!/usr/bin/bash
# =============================================================================
# dbms.sh — Entry Point
# Bash Shell Script Database Management System (DBMS)
# GUI-based using Zenity
# =============================================================================

umask 003

# ── Paths ────────────────────────────────────────────────────────────────────
export SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export DB_ROOT="$SCRIPT_DIR/Database"
export CURRENT_DB=""

# ── Load Modules ─────────────────────────────────────────────────────────────
source "$SCRIPT_DIR/lib/db_manager.sh"
source "$SCRIPT_DIR/lib/table_manager.sh"
source "$SCRIPT_DIR/lib/menus.sh"

# ── Bootstrap ────────────────────────────────────────────────────────────────
zenity --info \
    --title="Welcome" \
    --text="Welcome to the Bash DBMS 😎\nA File-Based Database Management System"

if [[ ! -d "$DB_ROOT" ]]; then
    mkdir "$DB_ROOT"
    zenity --info --width=400 --text="Database root folder created at:\n$DB_ROOT"
fi

# ── Launch ───────────────────────────────────────────────────────────────────
main_menu
