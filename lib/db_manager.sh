#!/usr/bin/bash
# =============================================================================
# lib/db_manager.sh — Database-Level Operations
# Handles: create, list, connect, drop, backup, restore databases
# =============================================================================


# ─────────────────────────────────────────────────────────────────────────────
# create_db
# ─────────────────────────────────────────────────────────────────────────────
create_db() {
    gum style --foreground 212 --border normal --padding "0 1" "Create Database"
    DBName=$(gum input --placeholder "Enter database name" --prompt "Name: ")

    [[ -z "$DBName" ]] && return

    DBName=$(echo "$DBName" | tr ' ' '_')

    if [[ $DBName =~ ^[0-9] ]]; then
        echo -e "${RED}Error: Name cannot start with a number.${NC}"
        return
    fi

    if [[ $DBName =~ [^A-Za-z0-9_] ]]; then
        echo -e "${RED}Error: Use only letters, numbers, and underscores.${NC}"
        return
    fi

    if [[ -d "$DB_ROOT/$DBName" ]]; then
        echo -e "${RED}Error: Database '$DBName' already exists.${NC}"
        return
    fi

    mkdir "$DB_ROOT/$DBName"
    echo -e "${GREEN}✅ Database '$DBName' created successfully.${NC}"
    log_action "Created Database: $DBName"
}


# ─────────────────────────────────────────────────────────────────────────────
# list_db
# ─────────────────────────────────────────────────────────────────────────────
list_db() {
    gum style --foreground 212 --border normal --padding "0 1" "Available Databases"
    cd "$DB_ROOT" || return

    db_list=$(ls -d */ 2>/dev/null | sed 's:/$::')

    if [[ -z "$db_list" ]]; then
        echo -e "${YELLOW}No databases found.${NC}"
        return
    fi

    echo -e "${BLUE}$db_list${NC}"
}


# ─────────────────────────────────────────────────────────────────────────────
# drop_db
# ─────────────────────────────────────────────────────────────────────────────
drop_db() {
    gum style --foreground 212 --border normal --padding "0 1" "Drop Database"
    
    cd "$DB_ROOT" || return
    db_list=($(ls -d */ 2>/dev/null | sed 's:/$::'))

    if [[ ${#db_list[@]} -eq 0 ]]; then
        gum style --foreground 226 "No databases found."
        return
    fi

    DBName=$(gum choose --header "Select database to drop:" "${db_list[@]}")
    
    if [[ -n "$DBName" ]]; then
        if gum confirm "⚠️ Are you sure you want to delete '$DBName'? All data will be lost."; then
            rm -rf "$DB_ROOT/$DBName"
            [[ "$CURRENT_DB" == "$DBName" ]] && CURRENT_DB=""
            gum style --foreground 46 "🗑️ Database '$DBName' has been removed."
            log_action "Dropped Database: $DBName"
        else
            gum style --foreground 226 "Operation cancelled."
        fi
    fi
}


# ─────────────────────────────────────────────────────────────────────────────
# connect_db
# ─────────────────────────────────────────────────────────────────────────────
connect_db() {
    gum style --foreground 212 --border normal --padding "0 1" "Connect to Database"
    
    cd "$DB_ROOT" || return
    db_list=($(ls -d */ 2>/dev/null | sed 's:/$::'))

    if [[ ${#db_list[@]} -eq 0 ]]; then
        gum style --foreground 226 "No databases found. Please create one first."
        return
    fi

    DBName=$(gum choose --header "Select database to connect:" "${db_list[@]}")
    
    if [[ -n "$DBName" ]]; then
        CURRENT_DB="$DBName"
        gum style --foreground 46 "✅ Connected to database: $CURRENT_DB"
        log_action "Connected to Database: $CURRENT_DB"
        sleep 1
        db_menu
    fi
}

# ─────────────────────────────────────────────────────────────────────────────
# backup_db
# ─────────────────────────────────────────────────────────────────────────────
backup_db() {
    gum style --foreground 212 --border normal --padding "0 1" "Backup Database"
    
    cd "$DB_ROOT" || return
    db_list=($(ls -d */ 2>/dev/null | sed 's:/$::'))

    if [[ ${#db_list[@]} -eq 0 ]]; then
        gum style --foreground 226 "No databases found."
        return
    fi

    DBName=$(gum choose --header "Select database to backup:" "${db_list[@]}")
    
    if [[ -n "$DBName" ]]; then
        BACKUP_DIR="$SCRIPT_DIR/Backups"
        mkdir -p "$BACKUP_DIR"
        
        timestamp=$(date "+%Y%m%d_%H%M%S")
        backup_file="$BACKUP_DIR/${DBName}_backup_${timestamp}.tar.gz"
        
        tar -czf "$backup_file" -C "$DB_ROOT" "$DBName"
        gum style --foreground 46 "✅ Backup created successfully at:" "$backup_file"
        log_action "Backed up Database: $DBName to $backup_file"
    fi
}

# ─────────────────────────────────────────────────────────────────────────────
# restore_db
# ─────────────────────────────────────────────────────────────────────────────
restore_db() {
    gum style --foreground 212 --border normal --padding "0 1" "Restore Database"
    
    BACKUP_DIR="$SCRIPT_DIR/Backups"
    if [[ ! -d "$BACKUP_DIR" ]]; then
        gum style --foreground 226 "No backups folder found."
        return
    fi

    cd "$BACKUP_DIR" || return
    backup_list=($(ls *.tar.gz 2>/dev/null))

    if [[ ${#backup_list[@]} -eq 0 ]]; then
        gum style --foreground 226 "No backup files found."
        return
    fi

    BackupFile=$(gum choose --header "Select backup to restore:" "${backup_list[@]}")
    
    if [[ -n "$BackupFile" ]]; then
        if gum confirm "⚠️ This will overwrite the existing database if it exists. Continue?"; then
            tar -xzf "$BackupFile" -C "$DB_ROOT"
            gum style --foreground 46 "✅ Database restored successfully."
            log_action "Restored Database from: $BackupFile"
        else
            gum style --foreground 226 "Operation cancelled."
        fi
    fi
}
