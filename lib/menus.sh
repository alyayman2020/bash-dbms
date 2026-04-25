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
        gum style \
            --foreground 212 --border-foreground 212 --border normal \
            --align center --width 50 --margin "1 2" --padding "1 2" \
            "Bash DBMS — Main Menu" "Choose an operation:"
        
        choice=$(gum choose --cursor="> " --item.foreground="255" --cursor.foreground="212" \
            "Create Database" \
            "List Databases" \
            "Connect to Database" \
            "Drop Database" \
            "Backup Database" \
            "Restore Database" \
            "Exit")

        case $choice in
            "Create Database") create_db ;;
            "List Databases") list_db ;;
            "Connect to Database") connect_db ;;
            "Drop Database") drop_db ;;
            "Backup Database") backup_db ;;
            "Restore Database") restore_db ;;
            "Exit") exit 0 ;;
        esac
        
        gum input --placeholder "Press Enter to continue..." --value "" >/dev/null 2>&1
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
        gum style \
            --foreground 117 --border-foreground 117 --border normal \
            --align center --width 50 --margin "1 2" --padding "1 2" \
            "Database: $CURRENT_DB" "Choose a table operation:"
        
        choice=$(gum choose --cursor="> " --item.foreground="255" --cursor.foreground="117" \
            "Create Table" \
            "List Tables" \
            "Drop Table" \
            "Insert Into Table" \
            "Select From Table" \
            "Delete From Table" \
            "Update Table" \
            "Export Table to SQL" \
            "Export Table to CSV" \
            "Back to Main Menu")

        case $choice in
            "Create Table") create_table ;;
            "List Tables") list_tables ;;
            "Drop Table") drop_table ;;
            "Insert Into Table") insert_into_table ;;
            "Select From Table") select_from_table ;;
            "Delete From Table") delete_from_table ;;
            "Update Table") update_table ;;
            "Export Table to SQL") export_to_sql ;;
            "Export Table to CSV") export_to_csv ;;
            "Back to Main Menu") return ;;
        esac
        
        gum input --placeholder "Press Enter to continue..." --value "" >/dev/null 2>&1
    done
}
