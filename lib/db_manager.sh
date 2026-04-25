#!/usr/bin/bash
# =============================================================================
# lib/db_manager.sh — Database-Level Operations
# Handles: create, list, connect, drop, backup, restore databases
# =============================================================================


# ─────────────────────────────────────────────────────────────────────────────
# create_db
# ─────────────────────────────────────────────────────────────────────────────
create_db() {
    echo -e "${CYAN}=== Create Database ===${NC}"
    read -p "Enter database name: " DBName

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
    echo -e "${CYAN}=== Available Databases ===${NC}"
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
    echo -e "${CYAN}=== Drop Database ===${NC}"
    
    cd "$DB_ROOT" || return
    db_list=($(ls -d */ 2>/dev/null | sed 's:/$::'))

    if [[ ${#db_list[@]} -eq 0 ]]; then
        echo -e "${YELLOW}No databases found.${NC}"
        return
    fi

    PS3=$'\n'"${YELLOW}Select database to drop (1-${#db_list[@]}): ${NC}"
    select DBName in "${db_list[@]}"; do
        if [[ -n "$DBName" ]]; then
            read -p "⚠️ Are you sure you want to delete '$DBName'? (y/n): " confirm
            if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
                rm -rf "$DB_ROOT/$DBName"
                [[ "$CURRENT_DB" == "$DBName" ]] && CURRENT_DB=""
                echo -e "${GREEN}🗑️ Database '$DBName' has been removed.${NC}"
                log_action "Dropped Database: $DBName"
            else
                echo -e "${YELLOW}Operation cancelled.${NC}"
            fi
            break
        else
            echo -e "${RED}Invalid selection.${NC}"
            break
        fi
    done
}


# ─────────────────────────────────────────────────────────────────────────────
# connect_db
# ─────────────────────────────────────────────────────────────────────────────
connect_db() {
    echo -e "${CYAN}=== Connect to Database ===${NC}"
    
    cd "$DB_ROOT" || return
    db_list=($(ls -d */ 2>/dev/null | sed 's:/$::'))

    if [[ ${#db_list[@]} -eq 0 ]]; then
        echo -e "${YELLOW}No databases found. Please create one first.${NC}"
        return
    fi

    PS3=$'\n'"${YELLOW}Select database to connect (1-${#db_list[@]}): ${NC}"
    select DBName in "${db_list[@]}"; do
        if [[ -n "$DBName" ]]; then
            CURRENT_DB="$DBName"
            echo -e "${GREEN}✅ Connected to database: $CURRENT_DB${NC}"
            log_action "Connected to Database: $CURRENT_DB"
            sleep 1
            db_menu
            break
        else
            echo -e "${RED}Invalid selection.${NC}"
            break
        fi
    done
}

# ─────────────────────────────────────────────────────────────────────────────
# backup_db
# ─────────────────────────────────────────────────────────────────────────────
backup_db() {
    echo -e "${CYAN}=== Backup Database ===${NC}"
    
    cd "$DB_ROOT" || return
    db_list=($(ls -d */ 2>/dev/null | sed 's:/$::'))

    if [[ ${#db_list[@]} -eq 0 ]]; then
        echo -e "${YELLOW}No databases found.${NC}"
        return
    fi

    PS3=$'\n'"${YELLOW}Select database to backup (1-${#db_list[@]}): ${NC}"
    select DBName in "${db_list[@]}"; do
        if [[ -n "$DBName" ]]; then
            BACKUP_DIR="$SCRIPT_DIR/Backups"
            mkdir -p "$BACKUP_DIR"
            
            timestamp=$(date "+%Y%m%d_%H%M%S")
            backup_file="$BACKUP_DIR/${DBName}_backup_${timestamp}.tar.gz"
            
            tar -czf "$backup_file" -C "$DB_ROOT" "$DBName"
            echo -e "${GREEN}✅ Backup created successfully at: $backup_file${NC}"
            log_action "Backed up Database: $DBName to $backup_file"
            break
        else
            echo -e "${RED}Invalid selection.${NC}"
            break
        fi
    done
}

# ─────────────────────────────────────────────────────────────────────────────
# restore_db
# ─────────────────────────────────────────────────────────────────────────────
restore_db() {
    echo -e "${CYAN}=== Restore Database ===${NC}"
    
    BACKUP_DIR="$SCRIPT_DIR/Backups"
    if [[ ! -d "$BACKUP_DIR" ]]; then
        echo -e "${YELLOW}No backups folder found.${NC}"
        return
    fi

    cd "$BACKUP_DIR" || return
    backup_list=($(ls *.tar.gz 2>/dev/null))

    if [[ ${#backup_list[@]} -eq 0 ]]; then
        echo -e "${YELLOW}No backup files found.${NC}"
        return
    fi

    PS3=$'\n'"${YELLOW}Select backup to restore (1-${#backup_list[@]}): ${NC}"
    select BackupFile in "${backup_list[@]}"; do
        if [[ -n "$BackupFile" ]]; then
            read -p "⚠️ This will overwrite the existing database if it exists. Continue? (y/n): " confirm
            if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
                tar -xzf "$BackupFile" -C "$DB_ROOT"
                echo -e "${GREEN}✅ Database restored successfully.${NC}"
                log_action "Restored Database from: $BackupFile"
            else
                echo -e "${YELLOW}Operation cancelled.${NC}"
            fi
            break
        else
            echo -e "${RED}Invalid selection.${NC}"
            break
        fi
    done
}
