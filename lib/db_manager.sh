#!/usr/bin/bash
# =============================================================================
# lib/db_manager.sh — Database-Level Operations
# Handles: create, list, connect, drop databases
# Each database is stored as a directory under $DB_ROOT
# =============================================================================


# ─────────────────────────────────────────────────────────────────────────────
# create_db
# Prompts user for a database name, validates it, and creates a directory.
# Validation rules:
#   - Name cannot be empty
#   - Spaces are converted to underscores
#   - Cannot start with a digit
#   - Only alphanumeric characters and underscores allowed
#   - Must not already exist
# ─────────────────────────────────────────────────────────────────────────────
create_db() {
    DBName=$(zenity --entry \
        --title="Create Database" \
        --text="Enter database name:")

    [[ -z "$DBName" ]] && return

    # Replace spaces with underscores
    DBName=$(echo "$DBName" | tr ' ' '_')

    if [[ $DBName =~ ^[0-9] ]]; then
        zenity --error --text="Name cannot start with a number."
        return
    fi

    if [[ $DBName =~ [^A-Za-z0-9_] ]]; then
        zenity --error --text="Use only letters, numbers, and underscores."
        return
    fi

    if [[ -d "$DB_ROOT/$DBName" ]]; then
        zenity --error --text="Database '$DBName' already exists."
        return
    fi

    mkdir "$DB_ROOT/$DBName"
    zenity --info --text="✅ Database '$DBName' created successfully."
}


# ─────────────────────────────────────────────────────────────────────────────
# list_db
# Lists all databases (directories) inside $DB_ROOT.
# Shows error if none exist.
# ─────────────────────────────────────────────────────────────────────────────
list_db() {
    cd "$DB_ROOT" || return

    db_list=$(ls -d */ 2>/dev/null | sed 's:/$::')

    if [[ -z "$db_list" ]]; then
        zenity --error --text="No databases found."
        return
    fi

    zenity --list \
        --title="Available Databases" \
        --column="Database Name" \
        $db_list
}


# ─────────────────────────────────────────────────────────────────────────────
# drop_db
# Lets user choose a database from a GUI list and delete it after confirmation.
# Resets CURRENT_DB if the dropped DB was active.
# ─────────────────────────────────────────────────────────────────────────────
drop_db() {
    db_list=$(ls -1 "$DB_ROOT" 2>/dev/null | while read -r d; do
        [[ -d "$DB_ROOT/$d" ]] && echo "$d"
    done)

    if [[ -z "$db_list" ]]; then
        zenity --error --text="No databases found."
        return
    fi

    DBName=$(zenity --list \
        --title="Drop Database" \
        --text="Choose a database to drop:" \
        --column="Database Name" \
        $db_list)

    [[ -z "$DBName" ]] && return

    zenity --question \
        --title="Confirm Delete" \
        --text="⚠️  Are you sure you want to delete database '$DBName'?\nThis action cannot be undone."

    [[ $? -ne 0 ]] && return

    rm -rf "$DB_ROOT/$DBName"
    [[ "$CURRENT_DB" == "$DBName" ]] && CURRENT_DB=""

    zenity --info --text="🗑️  Database '$DBName' has been removed."
}


# ─────────────────────────────────────────────────────────────────────────────
# connect_db
# Lets user select a database, sets CURRENT_DB, then opens the DB menu.
# ─────────────────────────────────────────────────────────────────────────────
connect_db() {
    db_list=$(ls -1 "$DB_ROOT" 2>/dev/null | while read -r d; do
        [[ -d "$DB_ROOT/$d" ]] && echo "$d"
    done)

    if [[ -z "$db_list" ]]; then
        zenity --error --text="No databases found. Please create one first."
        return
    fi

    DBName=$(zenity --list \
        --title="Connect to Database" \
        --text="Choose a database to connect to:" \
        --column="Database Name" \
        $db_list)

    [[ -z "$DBName" ]] && return

    CURRENT_DB="$DBName"
    zenity --info --text="✅ Connected to database: $CURRENT_DB"

    db_menu
}
