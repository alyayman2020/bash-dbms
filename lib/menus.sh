#!/usr/bin/bash
# =============================================================================
# lib/menus.sh — Main Menu & Database Menu
# Controls the two-level navigation of the DBMS
# =============================================================================


# ─────────────────────────────────────────────────────────────────────────────
# main_menu
# The top-level application menu. Handles database-level operations.
# ─────────────────────────────────────────────────────────────────────────────
main_menu() {
    while :; do
        choice=$(zenity --list \
            --title="Bash DBMS — Main Menu" \
            --text="Choose an operation:" \
            --column="Action" \
            --width=400 --height=350 \
            "Create Database" \
            "List Databases" \
            "Connect to Database" \
            "Drop Database" \
            "Exit")

        if [[ -z "$choice" ]]; then
            exit 0
        fi

        case $choice in
            "Create Database")     create_db ;;
            "List Databases")      list_db ;;
            "Connect to Database") connect_db ;;
            "Drop Database")       drop_db ;;
            "Exit")                exit 0 ;;
        esac
    done
}


# ─────────────────────────────────────────────────────────────────────────────
# db_menu
# The database-level menu. Only accessible after connecting to a database.
# Shows the current database name in the title bar.
# ─────────────────────────────────────────────────────────────────────────────
db_menu() {
    while :; do
        choice=$(zenity --list \
            --title="Database: $CURRENT_DB" \
            --text="Choose a table operation:" \
            --column="Action" \
            --width=400 --height=420 \
            "Create Table" \
            "List Tables" \
            "Drop Table" \
            "Insert Into Table" \
            "Select From Table" \
            "Delete From Table" \
            "Update Table" \
            "Back to Main Menu")

        if [[ -z "$choice" ]]; then
            return
        fi

        case $choice in
            "Create Table")      create_table ;;
            "List Tables")       list_tables ;;
            "Drop Table")        drop_table ;;
            "Insert Into Table") insert_into_table ;;
            "Select From Table") select_from_table ;;
            "Delete From Table") delete_from_table ;;
            "Update Table")      update_table ;;
            "Back to Main Menu") return ;;
        esac
    done
}
