#!/usr/bin/bash
# =============================================================================
# lib/menus.sh — Main Menu & Database Menu
# Controls the two-level navigation of the DBMS (ANSI TUI)
# =============================================================================


# ─────────────────────────────────────────────────────────────────────────────
# main_menu
# The top-level application menu. Handles database-level operations.
# ─────────────────────────────────────────────────────────────────────────────
main_menu() {
    while :; do
        clear
        echo -e "${CYAN}${BOLD}=== Bash DBMS — Main Menu ===${NC}"
        echo -e "Choose an operation:\n"
        
        options=(
            "Create Database"
            "List Databases"
            "Connect to Database"
            "Drop Database"
            "Backup Database"
            "Restore Database"
            "Exit"
        )

        PS3=$'\n'"${YELLOW}Select an option (1-${#options[@]}): ${NC}"
        select opt in "${options[@]}"; do
            case $REPLY in
                1) create_db; break ;;
                2) list_db; break ;;
                3) connect_db; break ;;
                4) drop_db; break ;;
                5) backup_db; break ;;
                6) restore_db; break ;;
                7) exit 0 ;;
                *) echo -e "${RED}Invalid option.${NC}"; sleep 1; break ;;
            esac
        done
        echo -e "\nPress Enter to continue..."
        read -r
    done
}


# ─────────────────────────────────────────────────────────────────────────────
# db_menu
# The database-level menu. Only accessible after connecting to a database.
# Shows the current database name.
# ─────────────────────────────────────────────────────────────────────────────
db_menu() {
    while :; do
        clear
        echo -e "${CYAN}${BOLD}=== Database: ${GREEN}$CURRENT_DB${CYAN} ===${NC}"
        echo -e "Choose a table operation:\n"
        
        options=(
            "Create Table"
            "List Tables"
            "Drop Table"
            "Insert Into Table"
            "Select From Table"
            "Delete From Table"
            "Update Table"
            "Export Table to SQL"
            "Export Table to CSV"
            "Back to Main Menu"
        )

        PS3=$'\n'"${YELLOW}Select an option (1-${#options[@]}): ${NC}"
        select opt in "${options[@]}"; do
            case $REPLY in
                1) create_table; break ;;
                2) list_tables; break ;;
                3) drop_table; break ;;
                4) insert_into_table; break ;;
                5) select_from_table; break ;;
                6) delete_from_table; break ;;
                7) update_table; break ;;
                8) export_to_sql; break ;;
                9) export_to_csv; break ;;
                10) return ;;
                *) echo -e "${RED}Invalid option.${NC}"; sleep 1; break ;;
            esac
        done
        echo -e "\nPress Enter to continue..."
        read -r
    done
}
