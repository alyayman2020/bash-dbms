#!/usr/bin/bash
# =============================================================================
# dbms.sh — Entry Point
# Bash Shell Script Database Management System (DBMS)
# ANSI TUI Version
# =============================================================================

umask 003

# ── ANSI Colors ──────────────────────────────────────────────────────────────
export RED='\033[0;31m'
export GREEN='\033[0;32m'
export YELLOW='\033[1;33m'
export BLUE='\033[0;34m'
export CYAN='\033[0;36m'
export BOLD='\033[1m'
export NC='\033[0m' # No Color

# ── Paths ────────────────────────────────────────────────────────────────────
export SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export DB_ROOT="$SCRIPT_DIR/Database"
export CURRENT_DB=""
export LOG_FILE="$SCRIPT_DIR/dbms.log"

# ── Logging Function ─────────────────────────────────────────────────────────
log_action() {
    local action="$1"
    local timestamp=$(date "+%Y-%m-%d %H:%M:%S")
    echo "[$timestamp] $action" >> "$LOG_FILE"
}

# ── Load Modules ─────────────────────────────────────────────────────────────
source "$SCRIPT_DIR/lib/db_manager.sh"
source "$SCRIPT_DIR/lib/table_manager.sh"
source "$SCRIPT_DIR/lib/menus.sh"

# ── Bootstrap ────────────────────────────────────────────────────────────────
clear
echo -e "${CYAN}${BOLD}====================================================${NC}"
echo -e "${CYAN}${BOLD}            Welcome to the Bash DBMS 😎            ${NC}"
echo -e "${CYAN}${BOLD}       A File-Based Database Management System     ${NC}"
echo -e "${CYAN}${BOLD}====================================================${NC}"
echo ""

if [[ ! -d "$DB_ROOT" ]]; then
    mkdir "$DB_ROOT"
    echo -e "${GREEN}✅ Database root folder created at:${NC}\n$DB_ROOT"
    log_action "System Bootstrapped: DB_ROOT created"
fi

echo -e "Press Enter to continue..."
read -r

# ── Launch ───────────────────────────────────────────────────────────────────
main_menu
