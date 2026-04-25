#!/usr/bin/bash
# =============================================================================
# lib/table_manager.sh — Table-Level Operations
# Handles: create, list, drop, insert, select, delete, update tables
# Also includes Export to SQL and Export to CSV features.
# =============================================================================

# ─────────────────────────────────────────────────────────────────────────────
# create_table
# ─────────────────────────────────────────────────────────────────────────────
create_table() {
    echo -e "${CYAN}=== Create Table ===${NC}"
    cd "$DB_ROOT/$CURRENT_DB" || return

    read -p "Enter table name: " TBName
    [[ -z "$TBName" ]] && return

    if [[ $TBName =~ [[:space:]] ]]; then
        echo -e "${RED}Error: Table name cannot contain spaces.${NC}"
        return
    fi

    if [[ -e "$TBName" || -e ".$TBName-metadata" ]]; then
        echo -e "${RED}Error: Table '$TBName' already exists.${NC}"
        return
    fi

    read -p "Enter number of columns: " colNum
    [[ -z "$colNum" ]] && return

    if ! [[ $colNum =~ ^[0-9]+$ ]] || [[ $colNum -lt 1 ]]; then
        echo -e "${RED}Error: Number of columns must be a positive integer.${NC}"
        return
    fi

    touch ".$TBName-metadata"
    touch "$TBName"

    for ((i=1; i<=colNum; i++)); do
        read -p "Enter name for column $i: " colName
        if [[ -z "$colName" ]]; then
            rm -f "$TBName" ".$TBName-metadata"
            return
        fi

        echo -e "Choose datatype for '$colName':"
        select colType in "int" "str" "float"; do
            if [[ -n "$colType" ]]; then
                break
            else
                echo -e "${RED}Invalid selection.${NC}"
            fi
        done

        line="$colName:$colType:"

        if [[ $i -eq 1 ]]; then
            read -p "Make '$colName' the primary key? (y/n): " pk_ans
            if [[ "$pk_ans" == "y" || "$pk_ans" == "Y" ]]; then
                line+="pk"
            else
                line+="nopk"
            fi
        else
            line+="nopk"
        fi

        echo "$line" >> ".$TBName-metadata"
    done

    echo -e "${GREEN}✅ Table '$TBName' created successfully.${NC}"
    log_action "Created Table: $TBName in DB: $CURRENT_DB"
}

# ─────────────────────────────────────────────────────────────────────────────
# list_tables
# ─────────────────────────────────────────────────────────────────────────────
list_tables() {
    echo -e "${CYAN}=== Tables in '$CURRENT_DB' ===${NC}"
    cd "$DB_ROOT/$CURRENT_DB" || return

    tables=$(ls -p | grep -v / | grep -v '^\.')

    if [[ -z "$tables" ]]; then
        echo -e "${YELLOW}No tables found in database '$CURRENT_DB'.${NC}"
        return
    fi

    echo -e "${BLUE}$tables${NC}"
}

# ─────────────────────────────────────────────────────────────────────────────
# drop_table
# ─────────────────────────────────────────────────────────────────────────────
drop_table() {
    echo -e "${CYAN}=== Drop Table ===${NC}"
    cd "$DB_ROOT/$CURRENT_DB" || return

    tables=($(ls -p | grep -v / | grep -v '^\.'))

    if [[ ${#tables[@]} -eq 0 ]]; then
        echo -e "${YELLOW}No tables found.${NC}"
        return
    fi

    PS3=$'\n'"${YELLOW}Select a table to drop (1-${#tables[@]}): ${NC}"
    select TBName in "${tables[@]}"; do
        if [[ -n "$TBName" ]]; then
            read -p "⚠️ Are you sure you want to drop table '$TBName'? All data will be lost. (y/n): " confirm
            if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
                rm -f "$TBName" ".$TBName-metadata"
                echo -e "${GREEN}🗑️ Table '$TBName' has been removed.${NC}"
                log_action "Dropped Table: $TBName in DB: $CURRENT_DB"
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
# insert_into_table
# ─────────────────────────────────────────────────────────────────────────────
insert_into_table() {
    echo -e "${CYAN}=== Insert Into Table ===${NC}"
    cd "$DB_ROOT/$CURRENT_DB" || return

    tables=($(ls -p | grep -v / | grep -v '^\.'))

    if [[ ${#tables[@]} -eq 0 ]]; then
        echo -e "${YELLOW}No tables found.${NC}"
        return
    fi

    PS3=$'\n'"${YELLOW}Select a table (1-${#tables[@]}): ${NC}"
    select TBName in "${tables[@]}"; do
        if [[ -z "$TBName" ]]; then
            echo -e "${RED}Invalid selection.${NC}"
            break
        fi

        meta=".$TBName-metadata"
        if [[ ! -f "$meta" ]]; then
            echo -e "${RED}Error: Metadata file missing for '$TBName'.${NC}"
            break
        fi

        line=""
        while IFS=: read -r colName colType colPK; do
            while :; do
                read -p "Enter value for '$colName' ($colType): " colVal
                [[ -z "$colVal" ]] && { echo -e "${YELLOW}Operation cancelled.${NC}"; return; }

                case $colType in
                    int)
                        if ! [[ $colVal =~ ^[0-9]+$ ]]; then
                            echo -e "${RED}Error: '$colName' must be an integer.${NC}"
                            continue
                        fi
                        ;;
                    float)
                        if ! [[ $colVal =~ ^[0-9]+([.][0-9]+)?$ ]]; then
                            echo -e "${RED}Error: '$colName' must be a number.${NC}"
                            continue
                        fi
                        ;;
                    str)
                        if [[ $colVal =~ : ]]; then
                            echo -e "${RED}Error: Value cannot contain ':'.${NC}"
                            continue
                        fi
                        ;;
                esac

                if [[ "$colPK" == "pk" ]]; then
                    if cut -d: -f1 "$TBName" | grep -qx "$colVal"; then
                        echo -e "${RED}Error: Primary key '$colVal' already exists.${NC}"
                        continue
                    fi
                fi
                break
            done
            line+="$colVal:"
        done < "$meta"

        echo "$line" >> "$TBName"
        echo -e "${GREEN}✅ Row inserted successfully.${NC}"
        log_action "Inserted row into Table: $TBName in DB: $CURRENT_DB"
        break
    done
}

# ─────────────────────────────────────────────────────────────────────────────
# select_from_table
# ─────────────────────────────────────────────────────────────────────────────
select_from_table() {
    echo -e "${CYAN}=== Select From Table ===${NC}"
    cd "$DB_ROOT/$CURRENT_DB" || return

    tables=($(ls -p | grep -v / | grep -v '^\.'))

    if [[ ${#tables[@]} -eq 0 ]]; then
        echo -e "${YELLOW}No tables found.${NC}"
        return
    fi

    PS3=$'\n'"${YELLOW}Select a table (1-${#tables[@]}): ${NC}"
    select TBName in "${tables[@]}"; do
        if [[ -z "$TBName" ]]; then
            echo -e "${RED}Invalid selection.${NC}"
            break
        fi

        meta=".$TBName-metadata"
        
        echo -e "\n${CYAN}Choose selection type:${NC}"
        options=(
            "All rows and columns"
            "Select one row"
            "Select one column"
            "Select many rows"
            "Select many columns"
            "Select some rows and some columns"
            "Select with WHERE condition"
        )
        
        PS3=$'\n'"${YELLOW}Select mode (1-${#options[@]}): ${NC}"
        select mode in "${options[@]}"; do
            case $REPLY in
                1)
                    columns=$(cut -d: -f1 "$meta" | tr '\n' '  |  ')
                    echo -e "\n${BOLD}Columns: $columns${NC}"
                    echo -e "${BLUE}$(printf '%.0s─' {1..50})${NC}"
                    cat "$TBName" | column -t -s ':'
                    ;;
                2)
                    read -p "Enter row number: " row
                    [[ -z "$row" ]] && break
                    echo -e "\n${BLUE}$(printf '%.0s─' {1..50})${NC}"
                    sed -n "${row}p" "$TBName" | column -t -s ':'
                    ;;
                3)
                    read -p "Enter column number: " col
                    [[ -z "$col" ]] && break
                    colName=$(sed -n "${col}p" "$meta" | cut -d: -f1)
                    echo -e "\n${BOLD}Column: $colName${NC}"
                    echo -e "${BLUE}$(printf '%.0s─' {1..30})${NC}"
                    cut -d: -f"$col" "$TBName"
                    ;;
                4)
                    read -p "Enter row numbers (space-separated): " rows
                    [[ -z "$rows" ]] && break
                    echo -e "\n${BLUE}$(printf '%.0s─' {1..50})${NC}"
                    for r in $rows; do
                        sed -n "${r}p" "$TBName" | column -t -s ':'
                    done
                    ;;
                5)
                    read -p "Enter column numbers (space-separated): " cols
                    [[ -z "$cols" ]] && break
                    colList=$(echo "$cols" | tr ' ' ',')
                    echo -e "\n${BLUE}$(printf '%.0s─' {1..50})${NC}"
                    cut -d: -f"$colList" "$TBName" | column -t -s ':'
                    ;;
                6)
                    read -p "Enter row numbers (space-separated): " rows
                    [[ -z "$rows" ]] && break
                    read -p "Enter column numbers (space-separated): " cols
                    [[ -z "$cols" ]] && break
                    colList=$(echo "$cols" | tr ' ' ',')
                    echo -e "\n${BLUE}$(printf '%.0s─' {1..50})${NC}"
                    for r in $rows; do
                        sed -n "${r}p" "$TBName" | cut -d: -f"$colList" | column -t -s ':'
                    done
                    ;;
                7)
                    read -p "Enter Primary Key value: " pk_value
                    [[ -z "$pk_value" ]] && break
                    result=$(grep "^$pk_value:" "$TBName")
                    if [[ -z "$result" ]]; then
                        echo -e "${YELLOW}No row found with PK = '$pk_value'.${NC}"
                    else
                        echo -e "\n${BLUE}$(printf '%.0s─' {1..50})${NC}"
                        echo "$result" | column -t -s ':'
                    fi
                    ;;
                *) echo -e "${RED}Invalid mode.${NC}" ;;
            esac
            break
        done
        break
    done
}

# ─────────────────────────────────────────────────────────────────────────────
# delete_from_table
# ─────────────────────────────────────────────────────────────────────────────
delete_from_table() {
    echo -e "${CYAN}=== Delete From Table ===${NC}"
    cd "$DB_ROOT/$CURRENT_DB" || return

    tables=($(ls -p | grep -v / | grep -v '^\.'))

    if [[ ${#tables[@]} -eq 0 ]]; then
        echo -e "${YELLOW}No tables found.${NC}"
        return
    fi

    PS3=$'\n'"${YELLOW}Select a table (1-${#tables[@]}): ${NC}"
    select TBName in "${tables[@]}"; do
        if [[ -z "$TBName" ]]; then
            echo -e "${RED}Invalid selection.${NC}"
            break
        fi

        read -p "Enter primary key value to delete: " pkVal
        [[ -z "$pkVal" ]] && break

        if ! grep -q "^$pkVal:" "$TBName"; then
            echo -e "${RED}Error: No row found with primary key '$pkVal'.${NC}"
            break
        fi

        read -p "⚠️ Delete row with PK = '$pkVal'? (y/n): " confirm
        if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
            sed -i "/^$pkVal:/d" "$TBName"
            echo -e "${GREEN}🗑️ Row deleted successfully.${NC}"
            log_action "Deleted row (PK: $pkVal) from Table: $TBName in DB: $CURRENT_DB"
        else
            echo -e "${YELLOW}Operation cancelled.${NC}"
        fi
        break
    done
}

# ─────────────────────────────────────────────────────────────────────────────
# update_table
# ─────────────────────────────────────────────────────────────────────────────
update_table() {
    echo -e "${CYAN}=== Update Table ===${NC}"
    cd "$DB_ROOT/$CURRENT_DB" || return

    tables=($(ls -p | grep -v / | grep -v '^\.'))

    if [[ ${#tables[@]} -eq 0 ]]; then
        echo -e "${YELLOW}No tables found.${NC}"
        return
    fi

    PS3=$'\n'"${YELLOW}Select a table (1-${#tables[@]}): ${NC}"
    select TBName in "${tables[@]}"; do
        if [[ -z "$TBName" ]]; then
            echo -e "${RED}Invalid selection.${NC}"
            break
        fi

        meta=".$TBName-metadata"
        pkCol=$(head -1 "$meta" | awk -F: '{print $1}')

        read -p "Enter '$pkCol' (primary key) value to update: " pkVal
        [[ -z "$pkVal" ]] && break

        if ! grep -q "^$pkVal:" "$TBName"; then
            echo -e "${RED}Error: No row found with primary key '$pkVal'.${NC}"
            break
        fi

        newLine=""
        while IFS=: read -r colName colType colPK; do
            if [[ "$colPK" == "pk" ]]; then
                newLine+="$pkVal:"
                continue
            fi

            while :; do
                read -p "New value for '$colName' ($colType): " colVal
                [[ -z "$colVal" ]] && { echo -e "${YELLOW}Operation cancelled.${NC}"; return; }

                case $colType in
                    int)
                        if ! [[ $colVal =~ ^[0-9]+$ ]]; then
                            echo -e "${RED}Error: '$colName' must be an integer.${NC}"
                            continue
                        fi
                        ;;
                    float)
                        if ! [[ $colVal =~ ^[0-9]+([.][0-9]+)?$ ]]; then
                            echo -e "${RED}Error: '$colName' must be a number.${NC}"
                            continue
                        fi
                        ;;
                    str)
                        if [[ $colVal =~ : ]]; then
                            echo -e "${RED}Error: Value cannot contain ':'.${NC}"
                            continue
                        fi
                        ;;
                esac
                break
            done
            newLine+="$colVal:"
        done < "$meta"

        escaped_new=$(echo "$newLine" | sed 's/[&/\]/\\&/g')
        sed -i "s/^$pkVal:.*/$escaped_new/" "$TBName"

        echo -e "${GREEN}✅ Row updated successfully.${NC}"
        log_action "Updated row (PK: $pkVal) in Table: $TBName in DB: $CURRENT_DB"
        break
    done
}

# ─────────────────────────────────────────────────────────────────────────────
# export_to_sql
# Reads table metadata and data, outputs a .sql file with CREATE and INSERT cmds
# ─────────────────────────────────────────────────────────────────────────────
export_to_sql() {
    echo -e "${CYAN}=== Export Table to SQL ===${NC}"
    cd "$DB_ROOT/$CURRENT_DB" || return

    tables=($(ls -p | grep -v / | grep -v '^\.'))

    if [[ ${#tables[@]} -eq 0 ]]; then
        echo -e "${YELLOW}No tables found.${NC}"
        return
    fi

    PS3=$'\n'"${YELLOW}Select a table to export (1-${#tables[@]}): ${NC}"
    select TBName in "${tables[@]}"; do
        if [[ -z "$TBName" ]]; then
            echo -e "${RED}Invalid selection.${NC}"
            break
        fi

        meta=".$TBName-metadata"
        export_dir="$SCRIPT_DIR/exports"
        mkdir -p "$export_dir"
        
        sql_file="$export_dir/${CURRENT_DB}_${TBName}.sql"
        
        # Build CREATE TABLE
        echo "CREATE TABLE $TBName (" > "$sql_file"
        cols=()
        types=()
        while IFS=: read -r colName colType colPK; do
            cols+=("$colName")
            sqlType="VARCHAR(255)"
            [[ "$colType" == "int" ]] && sqlType="INT"
            [[ "$colType" == "float" ]] && sqlType="FLOAT"
            
            pkStr=""
            [[ "$colPK" == "pk" ]] && pkStr=" PRIMARY KEY"
            
            echo "    $colName $sqlType$pkStr," >> "$sql_file"
            types+=("$colType")
        done < "$meta"
        # Remove trailing comma
        sed -i '$s/,$/\n);/' "$sql_file"
        
        echo "" >> "$sql_file"
        
        # Build INSERT statements
        while IFS=: read -r -a row_data; do
            # handle empty lines
            [[ ${#row_data[@]} -eq 0 ]] && continue
            
            insert_str="INSERT INTO $TBName ("
            insert_str+=$(IFS=,; echo "${cols[*]}")
            insert_str+=") VALUES ("
            
            val_strs=()
            for (( i=0; i<${#cols[@]}; i++ )); do
                val="${row_data[$i]}"
                # Quote strings
                if [[ "${types[$i]}" == "str" ]]; then
                    val_strs+=("'$val'")
                else
                    val_strs+=("$val")
                fi
            done
            
            insert_str+=$(IFS=,; echo "${val_strs[*]}")
            insert_str+=");"
            
            echo "$insert_str" >> "$sql_file"
        done < "$TBName"

        echo -e "${GREEN}✅ Table exported to SQL successfully: $sql_file${NC}"
        log_action "Exported Table $TBName to SQL"
        break
    done
}

# ─────────────────────────────────────────────────────────────────────────────
# export_to_csv
# Replaces colon separator with comma and adds headers
# ─────────────────────────────────────────────────────────────────────────────
export_to_csv() {
    echo -e "${CYAN}=== Export Table to CSV ===${NC}"
    cd "$DB_ROOT/$CURRENT_DB" || return

    tables=($(ls -p | grep -v / | grep -v '^\.'))

    if [[ ${#tables[@]} -eq 0 ]]; then
        echo -e "${YELLOW}No tables found.${NC}"
        return
    fi

    PS3=$'\n'"${YELLOW}Select a table to export (1-${#tables[@]}): ${NC}"
    select TBName in "${tables[@]}"; do
        if [[ -z "$TBName" ]]; then
            echo -e "${RED}Invalid selection.${NC}"
            break
        fi

        meta=".$TBName-metadata"
        export_dir="$SCRIPT_DIR/exports"
        mkdir -p "$export_dir"
        
        csv_file="$export_dir/${CURRENT_DB}_${TBName}.csv"
        
        # Extract headers
        headers=$(cut -d: -f1 "$meta" | tr '\n' ',')
        # Remove trailing comma
        headers=${headers%,}
        
        echo "$headers" > "$csv_file"
        
        # Extract data
        sed 's/:$//' "$TBName" | tr ':' ',' >> "$csv_file"

        echo -e "${GREEN}✅ Table exported to CSV successfully: $csv_file${NC}"
        log_action "Exported Table $TBName to CSV"
        break
    done
}
