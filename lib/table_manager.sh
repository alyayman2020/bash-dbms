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
    gum style --foreground 212 --border normal --padding "0 1" "Create Table"
    cd "$DB_ROOT/$CURRENT_DB" || return

    TBName=$(gum input --placeholder "Enter table name" --prompt "Table Name: ")
    [[ -z "$TBName" ]] && return

    if [[ $TBName =~ [[:space:]] ]]; then
        gum style --foreground 196 "Error: Table name cannot contain spaces."
        return
    fi

    if [[ -e "$TBName" || -e ".$TBName-metadata" ]]; then
        gum style --foreground 196 "Error: Table '$TBName' already exists."
        return
    fi

    colNum=$(gum input --placeholder "Enter number of columns" --prompt "Columns Count: ")
    [[ -z "$colNum" ]] && return

    if ! [[ $colNum =~ ^[0-9]+$ ]] || [[ $colNum -lt 1 ]]; then
        gum style --foreground 196 "Error: Number of columns must be a positive integer."
        return
    fi

    touch ".$TBName-metadata"
    touch "$TBName"

    for ((i=1; i<=colNum; i++)); do
        colName=$(gum input --placeholder "Name for column $i" --prompt "Col $i Name: ")
        if [[ -z "$colName" ]]; then
            rm -f "$TBName" ".$TBName-metadata"
            return
        fi

        colType=$(gum choose --header "Choose datatype for '$colName':" "int" "str" "float")

        line="$colName:$colType:"

        if [[ $i -eq 1 ]]; then
            if gum confirm "Make '$colName' the primary key?"; then
                line+="pk"
            else
                line+="nopk"
            fi
        else
            line+="nopk"
        fi

        echo "$line" >> ".$TBName-metadata"
    done

    gum style --foreground 46 "✅ Table '$TBName' created successfully."
    log_action "Created Table: $TBName in DB: $CURRENT_DB"
}

# ─────────────────────────────────────────────────────────────────────────────
# list_tables
# ─────────────────────────────────────────────────────────────────────────────
list_tables() {
    gum style --foreground 117 --border normal --padding "0 1" "Tables in '$CURRENT_DB'"
    cd "$DB_ROOT/$CURRENT_DB" || return

    tables=$(ls -p | grep -v / | grep -v '^\.')

    if [[ -z "$tables" ]]; then
        gum style --foreground 226 "No tables found in database '$CURRENT_DB'."
        return
    fi

    echo -e "${BLUE}$tables${NC}"
}

# ─────────────────────────────────────────────────────────────────────────────
# drop_table
# ─────────────────────────────────────────────────────────────────────────────
drop_table() {
    gum style --foreground 117 --border normal --padding "0 1" "Drop Table"
    cd "$DB_ROOT/$CURRENT_DB" || return

    tables=($(ls -p | grep -v / | grep -v '^\.'))

    if [[ ${#tables[@]} -eq 0 ]]; then
        gum style --foreground 226 "No tables found."
        return
    fi

    TBName=$(gum choose --header "Select a table to drop:" "${tables[@]}")
    
    if [[ -n "$TBName" ]]; then
        if gum confirm "⚠️ Are you sure you want to drop table '$TBName'? All data will be lost."; then
            rm -f "$TBName" ".$TBName-metadata"
            gum style --foreground 46 "🗑️ Table '$TBName' has been removed."
            log_action "Dropped Table: $TBName in DB: $CURRENT_DB"
        else
            gum style --foreground 226 "Operation cancelled."
        fi
    fi
}

# ─────────────────────────────────────────────────────────────────────────────
# insert_into_table
# ─────────────────────────────────────────────────────────────────────────────
insert_into_table() {
    gum style --foreground 117 --border normal --padding "0 1" "Insert Into Table"
    cd "$DB_ROOT/$CURRENT_DB" || return

    tables=($(ls -p | grep -v / | grep -v '^\.'))

    if [[ ${#tables[@]} -eq 0 ]]; then
        gum style --foreground 226 "No tables found."
        return
    fi

    TBName=$(gum choose --header "Select a table:" "${tables[@]}")
    if [[ -z "$TBName" ]]; then
        return
    fi

    meta=".$TBName-metadata"
    if [[ ! -f "$meta" ]]; then
        gum style --foreground 196 "Error: Metadata file missing for '$TBName'."
        return
    fi

    line=""
    while IFS=: read -r colName colType colPK; do
        while :; do
            colVal=$(gum input --placeholder "Value for '$colName' ($colType)" --prompt "$colName: ")
            [[ -z "$colVal" ]] && { gum style --foreground 226 "Operation cancelled."; return; }

            case $colType in
                int)
                    if ! [[ $colVal =~ ^[0-9]+$ ]]; then
                        gum style --foreground 196 "Error: '$colName' must be an integer."
                        continue
                    fi
                    ;;
                float)
                    if ! [[ $colVal =~ ^[0-9]+([.][0-9]+)?$ ]]; then
                        gum style --foreground 196 "Error: '$colName' must be a number."
                        continue
                    fi
                    ;;
                str)
                    if [[ $colVal =~ : ]]; then
                        gum style --foreground 196 "Error: Value cannot contain ':'."
                        continue
                    fi
                    ;;
            esac

            if [[ "$colPK" == "pk" ]]; then
                if cut -d: -f1 "$TBName" | grep -qx "$colVal"; then
                    gum style --foreground 196 "Error: Primary key '$colVal' already exists."
                    continue
                fi
            fi
            break
        done
        line+="$colVal:"
    done < "$meta"

    echo "$line" >> "$TBName"
    gum style --foreground 46 "✅ Row inserted successfully."
    log_action "Inserted row into Table: $TBName in DB: $CURRENT_DB"
}

# ─────────────────────────────────────────────────────────────────────────────
# select_from_table
# ─────────────────────────────────────────────────────────────────────────────
select_from_table() {
    gum style --foreground 117 --border normal --padding "0 1" "Select From Table"
    cd "$DB_ROOT/$CURRENT_DB" || return

    tables=($(ls -p | grep -v / | grep -v '^\.'))

    if [[ ${#tables[@]} -eq 0 ]]; then
        gum style --foreground 226 "No tables found."
        return
    fi

    TBName=$(gum choose --header "Select a table:" "${tables[@]}")
    if [[ -z "$TBName" ]]; then
        return
    fi

    meta=".$TBName-metadata"
    
    mode=$(gum choose --header "Choose selection type:" \
        "All rows and columns" \
        "Select one row" \
        "Select one column" \
        "Select many rows" \
        "Select many columns" \
        "Select some rows and some columns" \
        "Select with WHERE condition")
    
    case $mode in
        "All rows and columns")
            columns=$(cut -d: -f1 "$meta" | tr '\n' '  |  ')
            echo -e "\n${BOLD}Columns: $columns${NC}"
            echo -e "${BLUE}$(printf '%.0s─' {1..50})${NC}"
            cat "$TBName" | column -t -s ':'
            ;;
        "Select one row")
            row=$(gum input --placeholder "Enter row number")
            [[ -z "$row" ]] && return
            echo -e "\n${BLUE}$(printf '%.0s─' {1..50})${NC}"
            sed -n "${row}p" "$TBName" | column -t -s ':'
            ;;
        "Select one column")
            col=$(gum input --placeholder "Enter column number")
            [[ -z "$col" ]] && return
            colName=$(sed -n "${col}p" "$meta" | cut -d: -f1)
            echo -e "\n${BOLD}Column: $colName${NC}"
            echo -e "${BLUE}$(printf '%.0s─' {1..30})${NC}"
            cut -d: -f"$col" "$TBName"
            ;;
        "Select many rows")
            rows=$(gum input --placeholder "Enter row numbers (space-separated)")
            [[ -z "$rows" ]] && return
            echo -e "\n${BLUE}$(printf '%.0s─' {1..50})${NC}"
            for r in $rows; do
                sed -n "${r}p" "$TBName" | column -t -s ':'
            done
            ;;
        "Select many columns")
            cols=$(gum input --placeholder "Enter column numbers (space-separated)")
            [[ -z "$cols" ]] && return
            colList=$(echo "$cols" | tr ' ' ',')
            echo -e "\n${BLUE}$(printf '%.0s─' {1..50})${NC}"
            cut -d: -f"$colList" "$TBName" | column -t -s ':'
            ;;
        "Select some rows and some columns")
            rows=$(gum input --placeholder "Enter row numbers (space-separated)")
            [[ -z "$rows" ]] && return
            cols=$(gum input --placeholder "Enter column numbers (space-separated)")
            [[ -z "$cols" ]] && return
            colList=$(echo "$cols" | tr ' ' ',')
            echo -e "\n${BLUE}$(printf '%.0s─' {1..50})${NC}"
            for r in $rows; do
                sed -n "${r}p" "$TBName" | cut -d: -f"$colList" | column -t -s ':'
            done
            ;;
        "Select with WHERE condition")
            pk_value=$(gum input --placeholder "Enter Primary Key value")
            [[ -z "$pk_value" ]] && return
            result=$(grep "^$pk_value:" "$TBName")
            if [[ -z "$result" ]]; then
                gum style --foreground 226 "No row found with PK = '$pk_value'."
            else
                echo -e "\n${BLUE}$(printf '%.0s─' {1..50})${NC}"
                echo "$result" | column -t -s ':'
            fi
            ;;
    esac
}

# ─────────────────────────────────────────────────────────────────────────────
# delete_from_table
# ─────────────────────────────────────────────────────────────────────────────
delete_from_table() {
    gum style --foreground 117 --border normal --padding "0 1" "Delete From Table"
    cd "$DB_ROOT/$CURRENT_DB" || return

    tables=($(ls -p | grep -v / | grep -v '^\.'))

    if [[ ${#tables[@]} -eq 0 ]]; then
        gum style --foreground 226 "No tables found."
        return
    fi

    TBName=$(gum choose --header "Select a table:" "${tables[@]}")
    if [[ -z "$TBName" ]]; then
        return
    fi

    pkVal=$(gum input --placeholder "Enter primary key value to delete")
    [[ -z "$pkVal" ]] && return

    if ! grep -q "^$pkVal:" "$TBName"; then
        gum style --foreground 196 "Error: No row found with primary key '$pkVal'."
        return
    fi

    if gum confirm "⚠️ Delete row with PK = '$pkVal'?"; then
        sed -i "/^$pkVal:/d" "$TBName"
        gum style --foreground 46 "🗑️ Row deleted successfully."
        log_action "Deleted row (PK: $pkVal) from Table: $TBName in DB: $CURRENT_DB"
    else
        gum style --foreground 226 "Operation cancelled."
    fi
}

# ─────────────────────────────────────────────────────────────────────────────
# update_table
# ─────────────────────────────────────────────────────────────────────────────
update_table() {
    gum style --foreground 117 --border normal --padding "0 1" "Update Table"
    cd "$DB_ROOT/$CURRENT_DB" || return

    tables=($(ls -p | grep -v / | grep -v '^\.'))

    if [[ ${#tables[@]} -eq 0 ]]; then
        gum style --foreground 226 "No tables found."
        return
    fi

    TBName=$(gum choose --header "Select a table:" "${tables[@]}")
    if [[ -z "$TBName" ]]; then
        return
    fi

    meta=".$TBName-metadata"
    pkCol=$(head -1 "$meta" | awk -F: '{print $1}')

    pkVal=$(gum input --placeholder "Enter '$pkCol' (primary key) value to update")
    [[ -z "$pkVal" ]] && return

    if ! grep -q "^$pkVal:" "$TBName"; then
        gum style --foreground 196 "Error: No row found with primary key '$pkVal'."
        return
    fi

    newLine=""
    while IFS=: read -r colName colType colPK; do
        if [[ "$colPK" == "pk" ]]; then
            newLine+="$pkVal:"
            continue
        fi

        while :; do
            colVal=$(gum input --placeholder "New value for '$colName' ($colType)" --prompt "$colName: ")
            [[ -z "$colVal" ]] && { gum style --foreground 226 "Operation cancelled."; return; }

            case $colType in
                int)
                    if ! [[ $colVal =~ ^[0-9]+$ ]]; then
                        gum style --foreground 196 "Error: '$colName' must be an integer."
                        continue
                    fi
                    ;;
                float)
                    if ! [[ $colVal =~ ^[0-9]+([.][0-9]+)?$ ]]; then
                        gum style --foreground 196 "Error: '$colName' must be a number."
                        continue
                    fi
                    ;;
                str)
                    if [[ $colVal =~ : ]]; then
                        gum style --foreground 196 "Error: Value cannot contain ':'."
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

    gum style --foreground 46 "✅ Row updated successfully."
    log_action "Updated row (PK: $pkVal) in Table: $TBName in DB: $CURRENT_DB"
}

# ─────────────────────────────────────────────────────────────────────────────
# export_to_sql
# Reads table metadata and data, outputs a .sql file with CREATE and INSERT cmds
# ─────────────────────────────────────────────────────────────────────────────
export_to_sql() {
    gum style --foreground 117 --border normal --padding "0 1" "Export Table to SQL"
    cd "$DB_ROOT/$CURRENT_DB" || return

    tables=($(ls -p | grep -v / | grep -v '^\.'))

    if [[ ${#tables[@]} -eq 0 ]]; then
        gum style --foreground 226 "No tables found."
        return
    fi

    TBName=$(gum choose --header "Select a table to export:" "${tables[@]}")
    if [[ -z "$TBName" ]]; then
        return
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

    gum style --foreground 46 "✅ Table exported to SQL successfully: $sql_file"
    log_action "Exported Table $TBName to SQL"
}

# ─────────────────────────────────────────────────────────────────────────────
# export_to_csv
# Replaces colon separator with comma and adds headers
# ─────────────────────────────────────────────────────────────────────────────
export_to_csv() {
    gum style --foreground 117 --border normal --padding "0 1" "Export Table to CSV"
    cd "$DB_ROOT/$CURRENT_DB" || return

    tables=($(ls -p | grep -v / | grep -v '^\.'))

    if [[ ${#tables[@]} -eq 0 ]]; then
        gum style --foreground 226 "No tables found."
        return
    fi

    TBName=$(gum choose --header "Select a table to export:" "${tables[@]}")
    if [[ -z "$TBName" ]]; then
        return
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

    gum style --foreground 46 "✅ Table exported to CSV successfully: $csv_file"
    log_action "Exported Table $TBName to CSV"
}
