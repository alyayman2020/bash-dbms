# 🗄️ Bash DBMS — Shell Script Database Management System

<div align="center">

![Bash](https://img.shields.io/badge/Bash-5.x-4EAA25?style=flat-square&logo=gnubash&logoColor=white)
![Zenity](https://img.shields.io/badge/GUI-Zenity-blue?style=flat-square)
![Linux](https://img.shields.io/badge/Platform-Linux-FCC624?style=flat-square&logo=linux&logoColor=black)
![License](https://img.shields.io/badge/License-MIT-green?style=flat-square)
![ITI](https://img.shields.io/badge/ITI-Data%20Science%20Track-red?style=flat-square)

**A fully functional, file-based DBMS built entirely in Bash with a Zenity GUI.**  
Created as part of the ITI Data Science Track — Shell Scripting Module.

</div>

---

## 📌 Overview

This project implements a **Database Management System (DBMS)** from scratch using only
Bash shell scripting and the Zenity GUI toolkit. It provides a complete two-level menu
system for managing databases and tables — all stored as plain files on disk.

No SQL engine. No external database. Just the filesystem, `sed`, `grep`, `cut`, and Bash.

---

## ✨ Features

### 🗂️ Database-Level Operations
| Feature | Description |
|---|---|
| **Create Database** | Creates a new named directory as a database |
| **List Databases** | Shows all existing databases in a GUI list |
| **Connect to Database** | Opens the database and enters table management mode |
| **Drop Database** | Deletes a database with confirmation prompt |

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

### 🔍 Select Query Modes
1. All rows and columns
2. Select one row (by row number)
3. Select one column (by column number)
4. Select many rows (space-separated row numbers)
5. Select many columns (space-separated column numbers)
6. Select specific rows AND columns (combined)
7. **WHERE condition** — filter by primary key value

---

## 🏗️ Architecture

```
bash-dbms/
│
├── dbms.sh                  ← Entry point — bootstraps and launches app
│
├── lib/
│   ├── db_manager.sh        ← Database-level operations (create/list/drop/connect)
│   ├── table_manager.sh     ← Table-level operations (CRUD + SELECT)
│   └── menus.sh             ← Main menu & DB menu navigation loops
│
├── Database/                ← Auto-created at runtime (stores all databases)
│   └── .gitkeep
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

```bash
# Ubuntu/Debian
sudo apt install zenity

# Fedora/RHEL
sudo dnf install zenity
```

### Run

```bash
# Clone the repository
git clone https://github.com/alyayman2020/bash-dbms.git
cd bash-dbms

# Make executable
chmod +x dbms.sh lib/*.sh

# Launch
./dbms.sh
```

---

## 📸 Application Flow

```
Launch dbms.sh
     │
     ▼
┌─────────────────────┐
│     Main Menu       │
│  ─────────────────  │
│  Create Database    │
│  List Databases     │
│  Connect to DB  ────┼──► ┌──────────────────────┐
│  Drop Database      │    │   Database Menu       │
│  Exit               │    │  ──────────────────── │
└─────────────────────┘    │  Create Table         │
                           │  List Tables          │
                           │  Drop Table           │
                           │  Insert Into Table    │
                           │  Select From Table    │
                           │  Delete From Table    │
                           │  Update Table         │
                           │  Back to Main Menu    │
                           └──────────────────────┘
```

---

## 🛠️ Tech Stack

| Tool | Purpose |
|---|---|
| `bash` | Core scripting language |
| `zenity` | GUI dialogs (entry, list, question, info, error) |
| `sed` | In-place row deletion and update |
| `grep` | Row searching and PK validation |
| `cut` | Column extraction |
| `awk` | Metadata parsing |

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
