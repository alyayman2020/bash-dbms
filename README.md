# 🗄️ Bash DBMS — Shell Script Database Management System

<div align="center">

![Bash](https://img.shields.io/badge/Bash-5.x-4EAA25?style=flat-square&logo=gnubash&logoColor=white)
![TUI](https://img.shields.io/badge/UI-ANSI%20TUI-blue?style=flat-square)
![Linux](https://img.shields.io/badge/Platform-Linux-FCC624?style=flat-square&logo=linux&logoColor=black)
![License](https://img.shields.io/badge/License-MIT-green?style=flat-square)
![ITI](https://img.shields.io/badge/ITI-Data%20Science%20Track-red?style=flat-square)

**A fully functional, file-based DBMS built entirely in Bash with a sleek ANSI Terminal User Interface (TUI).**  
Created as part of the ITI Data Science Track — Shell Scripting Module.

</div>

---

## 📌 Overview

This project implements a **Database Management System (DBMS)** from scratch using only
Bash shell scripting. It provides a complete two-level menu system via a modern ANSI-colored Terminal User Interface for managing databases and tables — all stored as plain files on disk.

No SQL engine. No external database. Just the filesystem, `sed`, `grep`, `awk`, and Bash.

---

## ✨ Features

### 🗂️ Database-Level Operations
| Feature | Description |
|---|---|
| **Create Database** | Creates a new named directory as a database |
| **List Databases** | Shows all existing databases |
| **Connect to Database** | Opens the database and enters table management mode |
| **Drop Database** | Deletes a database with confirmation prompt |
| **Backup Database** | Archives a database into a `.tar.gz` backup file |
| **Restore Database** | Restores a database from a previous backup archive |

### 📋 Table-Level Operations
| Feature | Description |
|---|---|
| **Create Table** | Define columns with names, datatypes, and primary key |
| **List Tables** | View all tables in the current database |
| **Drop Table** | Delete a table and its metadata with confirmation |
| **Insert Into Table** | Add rows with full datatype and PK validation |
| **Select From Table** | 7 query modes including WHERE condition filter |
| **Delete From Table** | Remove a row by primary key |
| **Update Table** | Modify a row's values by primary key |
| **Export to SQL** | Generates standard `CREATE TABLE` and `INSERT INTO` statements |
| **Export to CSV** | Converts table data to standard Comma-Separated Values format |

### 🔍 Select Query Modes
1. All rows and columns
2. Select one row (by row number)
3. Select one column (by column number)
4. Select many rows (space-separated row numbers)
5. Select many columns (space-separated column numbers)
6. Select specific rows AND columns (combined)
7. **WHERE condition** — filter by primary key value

### 🛡️ Core Enhancements
- **Audit Logging**: Keeps an automated history of all structural and data-modifying actions inside `dbms.log`.

---

## 🏗️ Architecture

```
bash-dbms/
│
├── dbms.sh                  ← Entry point — bootstraps and launches app
├── dbms.log                 ← Auto-generated audit trail of all operations
│
├── lib/
│   ├── db_manager.sh        ← DB ops (create/list/drop/connect/backup/restore)
│   ├── table_manager.sh     ← Table ops (CRUD + SELECT + EXPORT)
│   └── menus.sh             ← ANSI interactive navigation loops
│
├── Database/                ← Stores all databases
│   └── .gitkeep
│
├── Backups/                 ← Auto-created to store .tar.gz database backups
├── exports/                 ← Auto-created to store exported SQL and CSV files
│
├── .gitignore
├── LICENSE
└── README.md
```

### Storage Format

Each database is a **directory** under `Database/`.  
Each table is **two files** inside its database directory:

```
Database/
└── my_company/
    ├── employees              ← Data file (colon-separated rows)
    └── .employees-metadata    ← Schema file (one column definition per line)
```

**Data file format:**
```
1:John:4500.5:
2:Sarah:5200.0:
3:Ali:3800.0:
```

**Metadata file format:**
```
id:int:pk
name:str:nopk
salary:float:nopk
```

---

## ⚙️ Validation & Constraints

### Database Names
- Cannot be empty
- Cannot start with a digit
- Only letters, numbers, and underscores allowed
- Spaces are automatically converted to underscores

### Column Datatypes
| Type | Validation Rule |
|---|---|
| `int` | Must match `^[0-9]+$` |
| `float` | Must match `^[0-9]+([.][0-9]+)?$` |
| `str` | Cannot contain the `:` delimiter character |

### Primary Key
- Only the first column can be designated as PK
- Insert and Update operations check for uniqueness before writing

---

## 🚀 Getting Started

### Prerequisites

You only need a standard Linux/macOS/Windows shell environment. No external dependencies or GUI components (like Zenity) are required! 

### Run

```bash
# Clone the repository
git clone https://github.com/alyayman2020/bash-dbms.git
cd bash-dbms

# Make executable
chmod +x dbms.sh lib/*.sh

# Launch the Application
./dbms.sh
```

---

## 📖 How to Work With the DBMS

When you launch `./dbms.sh`, you will be greeted by the Main Menu. The interface is driven by numerical selections.

1. **Creating a Database:**
   - From the main menu, type `1` to select **Create Database**.
   - Enter a name (e.g., `company_db`). 

2. **Connecting to a Database:**
   - Type `3` for **Connect to Database**.
   - Select your newly created `company_db` by typing its corresponding number.
   - You will now be inside the **Database Menu**.

3. **Creating a Table:**
   - In the Database Menu, select `1` for **Create Table**.
   - Enter table name (e.g., `users`).
   - Define columns (e.g., Column 1: `id`, Type: `int`, PK: `y`. Column 2: `username`, Type: `str`).

4. **Managing Data:**
   - Use **Insert Into Table** (`4`) to add records. The script will automatically prompt you for each column based on your defined datatypes.
   - Use **Select From Table** (`5`) to query data. The output is cleanly formatted using the `column` command.
   - Use **Update Table** (`7`) to modify records. You'll need the Primary Key of the row you want to update.

5. **Exporting and Backups:**
   - You can export table data to SQL or CSV from the Database Menu (`8` and `9`). Check the `exports/` folder for the files.
   - You can back up your entire database to a zip file from the Main Menu (`5`). Check the `Backups/` folder.

---

## 📸 Application Flow

```text
Launch dbms.sh
     │
     ▼
┌───────────────────────┐
│       Main Menu       │
│  ───────────────────  │
│  1) Create Database   │
│  2) List Databases    │
│  3) Connect to DB ────┼──► ┌─────────────────────────┐
│  4) Drop Database     │    │      Database Menu      │
│  5) Backup Database   │    │  ─────────────────────  │
│  6) Restore Database  │    │  1) Create Table        │
│  7) Exit              │    │  2) List Tables         │
└───────────────────────┘    │  3) Drop Table          │
                             │  4) Insert Into Table   │
                             │  5) Select From Table   │
                             │  6) Delete From Table   │
                             │  7) Update Table        │
                             │  8) Export Table to SQL │
                             │  9) Export Table to CSV │
                             │ 10) Back to Main Menu   │
                             └─────────────────────────┘
```

---

## 🛠️ Tech Stack

| Tool | Purpose |
|---|---|
| `bash` | Core scripting language & colored TUI interactions |
| `sed` | In-place row deletion and update |
| `grep` | Row searching and PK validation |
| `cut` | Column extraction |
| `awk` | Metadata parsing |
| `tar` | Database compression and backup |

---

## 📚 Academic Context

| | |
|---|---|
| **Institution** | Information Technology Institute (ITI) |
| **Program** | Data Science Track — 2025/2026 |
| **Module** | Shell Scripting & Linux Administration |

---

## 📄 License

This project is licensed under the **MIT License** — see [LICENSE](LICENSE) for details.

---

## 👤 Author

**Aly Ayman Ibrahim**

[![LinkedIn](https://img.shields.io/badge/LinkedIn-Aly%20Ayman-0077B5?style=flat-square&logo=linkedin)](https://linkedin.com/in/alyayman)
[![GitHub](https://img.shields.io/badge/GitHub-alyayman2020-181717?style=flat-square&logo=github)](https://github.com/alyayman2020)
[![Kaggle](https://img.shields.io/badge/Kaggle-alyaymanai-20BEFF?style=flat-square&logo=kaggle)](https://www.kaggle.com/alyaymanai)
