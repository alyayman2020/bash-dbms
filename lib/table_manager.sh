#!/usr/bin/bash
# =============================================================================
# lib/table_manager.sh — Table-Level Operations
# Handles: create, list, drop, insert, select, delete, update tables
#
# Storage format:
#   Each table → two files inside the database directory:
#     <tablename>           → data file   (rows as colon-separated values)
#     .<tablename>-metadata → schema file (colName:colType:pk|nopk per line)
#
# Example:
#   employees         → 1:John:4500.5:
#   .employees-metadata → id:int:pk
#                         name:str:nopk
#                         salary:float:nopk
# =============================================================================


# ─────────────────────────────────────────────────────────────────────────────
# create_table
# Prompts for table name, number of columns, then for each column:
#   - name, datatype (int/str/float), and whether it's the primary key
# Creates both the data file and the metadata file.
# ─────────────────────────────────────────────────────────────────────────────
create_table() {
    cd "$DB_ROOT/$CURRENT_DB" || return

    TBName=$(zenity --entry \
        --title="Create Table" \
        --text="Enter table name:")
    [[ -z "$TBName" ]] && return

    if [[ $TBName =~ [[:space:]] ]]; then
        zenity --error --text="Table name cannot contain spaces."
        return
    fi

    if [[ -e "$TBName" || -e ".$TBName-metadata" ]]; then
        zenity --error --text="Table '$TBName' already exists."
        return
    fi

    colNum=$(zenity --entry \
        --title="Create Table" \
        --text="Enter number of columns:")
    [[ -z "$colNum" ]] && return

    if ! [[ $colNum =~ ^[0-9]+$ ]] || [[ $colNum -lt 1 ]]; then
        zenity --error --text="Number of columns must be a positive integer."
        return
    fi

    touch ".$TBName-metadata"
    touch "$TBName"

    for ((i=1; i<=colNum; i++)); do
        colName=$(zenity --entry \
            --title="Column $i of $colNum" \
            --text="Enter name for column $i:")
        if [[ -z "$colName" ]]; then
            rm -f "$TBName" ".$TBName-metadata"
            return
        fi

        colType=$(zenity --list \
            --title="Datatype — Column: $colName" \
            --text="Choose datatype for '$colName':" \
            --column="Type" \
            "int" "str" "float")
        if [[ -z "$colType" ]]; then
            rm -f "$TBName" ".$TBName-metadata"
            return
        fi

        line="$colName:$colType:"

        if [[ $i -eq 1 ]]; then
            zenity --question \
                --title="Primary Key" \
                --text="Make '$colName' the primary key?"
            [[ $? -eq 0 ]] && line+="pk" || line+="nopk"
        else
            line+="nopk"
        fi

        echo "$line" >> ".$TBName-metadata"
    done

    zenity --info --text="✅ Table '$TBName' created successfully."
}


# ─────────────────────────────────────────────────────────────────────────────
# list_tables
# Lists all table files in the current database (excludes metadata and dirs).
# ─────────────────────────────────────────────────────────────────────────────
list_tables() {
    cd "$DB_ROOT/$CURRENT_DB" || return

    tables=$(ls -p | grep -v / | grep -v '^\.')

    if [[ -z "$tables" ]]; then
        zenity --error --text="No tables found in database '$CURRENT_DB'."
        return
    fi

    zenity --list \
        --title="Tables in '$CURRENT_DB'" \
        --column="Table Name" \
        $tables
}


# ─────────────────────────────────────────────────────────────────────────────
# drop_table
# Lets user pick a table, confirms deletion, then removes both the data
# file and its corresponding metadata file.
# ─────────────────────────────────────────────────────────────────────────────
drop_table() {
    cd "$DB_ROOT/$CURRENT_DB" || return

    TBName=$(zenity --list \
        --title="Drop Table" \
        --text="Choose a table to drop:" \
        --column="Table" \
        $(ls -p | grep -v / | grep -v '^\.' ))

    [[ -z "$TBName" ]] && return

    zenity --question \
        --title="Confirm Delete" \
        --text="⚠️  Are you sure you want to drop table '$TBName'?\nAll data will be lost."

    [[ $? -ne 0 ]] && return

    rm -f "$TBName" ".$TBName-metadata"
    zenity --info --text="🗑️  Table '$TBName' has been removed."
}


# ─────────────────────────────────────────────────────────────────────────────
# insert_into_table
# Reads column schema from metadata, prompts for each value, validates
# datatype, and enforces primary key uniqueness before appending the row.
# ─────────────────────────────────────────────────────────────────────────────
insert_into_table() {
    cd "$DB_ROOT/$CURRENT_DB" || return

    TBName=$(zenity --list \
        --title="Insert Into Table" \
        --text="Choose a table:" \
        --column="Table" \
        $(ls -p | grep -v / | grep -v '^\.' ))

    [[ -z "$TBName" ]] && return

    meta=".$TBName-metadata"

    if [[ ! -f "$meta" ]]; then
        zenity --error --text="Metadata file is missing for table '$TBName'."
        return
    fi

    line=""

    while IFS=: read -r colName colType colPK; do
        while :; do
            colVal=$(zenity --entry \
                --title="Insert — $TBName" \
                --text="Enter value for '$colName' ($colType):")

            [[ -z "$colVal" ]] && return

            # Datatype validation
            case $colType in
                int)
                    if ! [[ $colVal =~ ^[0-9]+$ ]]; then
                        zenity --error --text="'$colName' must be an integer."
                        continue
                    fi
                    ;;
                float)
                    if ! [[ $colVal =~ ^[0-9]+([.][0-9]+)?$ ]]; then
                        zenity --error --text="'$colName' must be a number (e.g. 12 or 12.5)."
                        continue
                    fi
                    ;;
                str)
                    if [[ $colVal =~ : ]]; then
                        zenity --error --text="Value cannot contain the ':' character."
                        continue
                    fi
                    ;;
            esac

            # Primary key uniqueness check
            if [[ "$colPK" == "pk" ]]; then
                if cut -d: -f1 "$TBName" | grep -qx "$colVal"; then
                    zenity --error --text="Primary key '$colVal' already exists."
                    continue
                fi
            fi

            break
        done

        line+="$colVal:"
    done < "$meta"

    echo "$line" >> "$TBName"
    zenity --info --text="✅ Row inserted successfully."
}


# ─────────────────────────────────────────────────────────────────────────────
# select_from_table
# Offers 7 selection modes:
#   1. All rows and columns
#   2. Select one row (by row number)
#   3. Select one column (by column number)
#   4. Select many rows (space-separated row numbers)
#   5. Select many columns (space-separated column numbers)
#   6. Select rows and columns (combined)
#   7. WHERE condition (filter by primary key value)
# ─────────────────────────────────────────────────────────────────────────────
select_from_table() {
    cd "$DB_ROOT/$CURRENT_DB" || return

    TBName=$(zenity --list \
        --title="Select From Table" \
        --text="Choose a table:" \
        --column="Tables" \
        $(ls -p | grep -v / | grep -v '^\.' ))

    [[ -z "$TBName" ]] && return

    meta=".$TBName-metadata"

    mode=$(zenity --list \
        --title="Select Mode — $TBName" \
        --text="Choose selection type:" \
        --column="Mode" \
        "All rows and columns" \
        "Select one row" \
        "Select one column" \
        "Select many rows" \
        "Select many columns" \
        "Select some rows and some columns" \
        "Select with WHERE condition")

    [[ -z "$mode" ]] && return

    case $mode in

        "All rows and columns")
            columns=$(cut -d: -f1 "$meta" | tr '\n' '  |  ')
            data=$(cat "$TBName")
            tmpfile=$(mktemp)
            echo -e "Columns: $columns\n$(printf '%.0s─' {1..50})\n$data" > "$tmpfile"
            zenity --text-info \
                --title="All Data — $TBName" \
                --width=600 --height=400 \
                --filename="$tmpfile"
            rm -f "$tmpfile"
            ;;

        "Select one row")
            row=$(zenity --entry \
                --title="Select Row" \
                --text="Enter row number:")
            [[ -z "$row" ]] && return
            ROW=$(sed -n "${row}p" "$TBName")
            tmpfile=$(mktemp)
            echo "$ROW" > "$tmpfile"
            zenity --text-info \
                --title="Row $row — $TBName" \
                --width=500 --height=200 \
                --filename="$tmpfile"
            rm -f "$tmpfile"
            ;;

        "Select one column")
            col=$(zenity --entry \
                --title="Select Column" \
                --text="Enter column number:")
            [[ -z "$col" ]] && return
            colName=$(cut -d: -f1 "$meta" | sed -n "${col}p")
            colData=$(cut -d: -f"$col" "$TBName")
            tmpfile=$(mktemp)
            echo -e "Column: $colName\n$(printf '%.0s─' {1..30})\n$colData" > "$tmpfile"
            zenity --text-info \
                --title="Column: $colName" \
                --width=400 --height=300 \
                --filename="$tmpfile"
            rm -f "$tmpfile"
            ;;

        "Select many rows")
            rows=$(zenity --entry \
                --title="Select Rows" \
                --text="Enter row numbers separated by spaces (e.g. 1 3 5):")
            [[ -z "$rows" ]] && return
            output=""
            for r in $rows; do
                output+="$(sed -n "${r}p" "$TBName")\n"
            done
            tmpfile=$(mktemp)
            echo -e "$output" > "$tmpfile"
            zenity --text-info \
                --title="Selected Rows — $TBName" \
                --width=500 --height=400 \
                --filename="$tmpfile"
            rm -f "$tmpfile"
            ;;

        "Select many columns")
            cols=$(zenity --entry \
                --title="Select Columns" \
                --text="Enter column numbers separated by spaces (e.g. 1 2):")
            [[ -z "$cols" ]] && return
            colList=$(echo "$cols" | tr ' ' ',')
            colData=$(cut -d: -f"$colList" "$TBName")
            tmpfile=$(mktemp)
            echo -e "$colData" > "$tmpfile"
            zenity --text-info \
                --title="Selected Columns — $TBName" \
                --width=500 --height=400 \
                --filename="$tmpfile"
            rm -f "$tmpfile"
            ;;

        "Select some rows and some columns")
            rows=$(zenity --entry \
                --title="Rows" \
                --text="Enter row numbers (space-separated):")
            [[ -z "$rows" ]] && return
            cols=$(zenity --entry \
                --title="Columns" \
                --text="Enter column numbers (space-separated):")
            [[ -z "$cols" ]] && return
            colList=$(echo "$cols" | tr ' ' ',')
            output=""
            for r in $rows; do
                line=$(sed -n "${r}p" "$TBName")
                output+="$(printf "%s\n" "$line" | cut -d: -f"$colList")\n"
            done
            tmpfile=$(mktemp)
            echo -e "$output" > "$tmpfile"
            zenity --text-info \
                --title="Selected Rows & Columns — $TBName" \
                --width=500 --height=400 \
                --filename="$tmpfile"
            rm -f "$tmpfile"
            ;;

        "Select with WHERE condition")
            pk_value=$(zenity --entry \
                --title="WHERE Condition" \
                --text="Enter Primary Key value:")
            [[ -z "$pk_value" ]] && return
            result=$(grep "^$pk_value:" "$TBName")
            if [[ -z "$result" ]]; then
                zenity --info --text="No row found with PK = '$pk_value'."
            else
                tmpfile=$(mktemp)
                echo -e "$result" > "$tmpfile"
                zenity --text-info \
                    --title="Result — WHERE PK = $pk_value" \
                    --width=500 --height=200 \
                    --filename="$tmpfile"
                rm -f "$tmpfile"
            fi
            ;;
    esac
}


# ─────────────────────────────────────────────────────────────────────────────
# delete_from_table
# Asks for a primary key value and deletes matching rows using sed.
# ─────────────────────────────────────────────────────────────────────────────
delete_from_table() {
    cd "$DB_ROOT/$CURRENT_DB" || return

    TBName=$(zenity --list \
        --title="Delete From Table" \
        --text="Choose a table:" \
        --column="Table" \
        $(ls -p | grep -v / | grep -v '^\.' ))

    [[ -z "$TBName" ]] && return

    pkVal=$(zenity --entry \
        --title="Delete Row" \
        --text="Enter primary key value to delete:")
    [[ -z "$pkVal" ]] && return

    if ! grep -q "^$pkVal:" "$TBName"; then
        zenity --error --text="No row found with primary key '$pkVal'."
        return
    fi

    zenity --question \
        --title="Confirm Delete" \
        --text="⚠️  Delete row with PK = '$pkVal'?"
    [[ $? -ne 0 ]] && return

    sed -i "/^$pkVal:/d" "$TBName"
    zenity --info --text="🗑️  Row deleted successfully."
}


# ─────────────────────────────────────────────────────────────────────────────
# update_table
# Finds a row by primary key, keeps the PK value, prompts for new values
# for every other column (with datatype validation), then rewrites the row.
# ─────────────────────────────────────────────────────────────────────────────
update_table() {
    cd "$DB_ROOT/$CURRENT_DB" || return

    TBName=$(zenity --list \
        --title="Update Table" \
        --text="Choose a table:" \
        --column="Table" \
        $(ls -p | grep -v / | grep -v '^\.' ))

    [[ -z "$TBName" ]] && return

    meta=".$TBName-metadata"

    pkCol=$(head -1 "$meta" | awk -F: '{print $1}')

    pkVal=$(zenity --entry \
        --title="Update Row" \
        --text="Enter '$pkCol' (primary key) value to update:")
    [[ -z "$pkVal" ]] && return

    if ! grep -q "^$pkVal:" "$TBName"; then
        zenity --error --text="No row found with primary key '$pkVal'."
        return
    fi

    newLine=""

    while IFS=: read -r colName colType colPK; do
        if [[ "$colPK" == "pk" ]]; then
            newLine+="$pkVal:"
            continue
        fi

        while :; do
            colVal=$(zenity --entry \
                --title="Update — $colName" \
                --text="New value for '$colName' ($colType):")
            [[ -z "$colVal" ]] && return

            case $colType in
                int)
                    if ! [[ $colVal =~ ^[0-9]+$ ]]; then
                        zenity --error --text="'$colName' must be an integer."
                        continue
                    fi
                    ;;
                float)
                    if ! [[ $colVal =~ ^[0-9]+([.][0-9]+)?$ ]]; then
                        zenity --error --text="'$colName' must be a number (e.g. 12 or 12.5)."
                        continue
                    fi
                    ;;
                str)
                    if [[ $colVal =~ : ]]; then
                        zenity --error --text="Value cannot contain the ':' character."
                        continue
                    fi
                    ;;
            esac
            break
        done

        newLine+="$colVal:"
    done < "$meta"

    # Escape special characters for sed
    escaped_new=$(echo "$newLine" | sed 's/[&/\]/\\&/g')
    sed -i "s/^$pkVal:.*/$escaped_new/" "$TBName"

    zenity --info --text="✅ Row updated successfully."
}
