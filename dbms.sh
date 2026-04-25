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
if ! command -v gum &> /dev/null; then
    echo -e "${RED}Error: Gum is not installed.${NC}"
    echo -e "Please run ${BOLD}./install.sh${NC} to install dependencies."
    exit 1
fi

clear
gum style \
	--foreground 212 --border-foreground 212 --border double \
	--align center --width 54 --margin "1 2" --padding "1 2" \
	"Welcome to the Bash DBMS 😎" "A File-Based Database Management System"

if [[ ! -d "$DB_ROOT" ]]; then
    mkdir "$DB_ROOT"
    gum style --foreground 212 "✅ Database root folder created at:" "$DB_ROOT"
    log_action "System Bootstrapped: DB_ROOT created"
fi

if [[ ! -d "$DB_ROOT/demo_db" ]]; then
    mkdir -p "$DB_ROOT/demo_db"
    
    # Create employees table metadata
    echo -e "id:int:pk\nname:str:nopk\ndepartment:str:nopk\nsalary:float:nopk" > "$DB_ROOT/demo_db/.employees-metadata"
    
    # Create employees table data
    echo -e "1:Alice:Engineering:7500.50:\n2:Bob:Marketing:5200.00:\n3:Charlie:Sales:6100.00:" > "$DB_ROOT/demo_db/employees"
    
    gum style --foreground 46 "🎁 Default database 'demo_db' created for testing!"
    log_action "System Bootstrapped: demo_db created"
fi

gum input --placeholder "Press Enter to continue..." --value "" >/dev/null 2>&1

# ── Launch ───────────────────────────────────────────────────────────────────
main_menu
