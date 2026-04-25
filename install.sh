#!/usr/bin/bash
# =============================================================================
# install.sh — Dependency Installer for Bash DBMS
# =============================================================================

echo "=================================================="
echo "      Installing Dependencies for Bash DBMS       "
echo "=================================================="

# Check if gum is already installed
if command -v gum &> /dev/null; then
    echo "✅ Gum is already installed!"
    exit 0
fi

echo "Gum is required for the modern Terminal User Interface."
echo "Detecting package manager..."

if command -v apt-get &> /dev/null; then
    echo "Detected APT (Debian/Ubuntu)..."
    sudo mkdir -p /etc/apt/keyrings
    curl -fsSL https://repo.charm.sh/apt/gpg.key | sudo gpg --dearmor -o /etc/apt/keyrings/charm.gpg
    echo "deb [signed-by=/etc/apt/keyrings/charm.gpg] https://repo.charm.sh/apt/ * *" | sudo tee /etc/apt/sources.list.d/charm.list
    sudo apt update && sudo apt install gum -y
elif command -v brew &> /dev/null; then
    echo "Detected Homebrew (macOS/Linux)..."
    brew install gum
elif command -v pacman &> /dev/null; then
    echo "Detected Pacman (Arch Linux)..."
    sudo pacman -S gum --noconfirm
elif command -v dnf &> /dev/null; then
    echo "Detected DNF (Fedora/RHEL)..."
    echo '[charm]
name=Charm
baseurl=https://repo.charm.sh/yum/
enabled=1
gpgcheck=1
gpgkey=https://repo.charm.sh/yum/gpg.key' | sudo tee /etc/yum.repos.d/charm.repo
    sudo dnf install gum -y
else
    echo "❌ Could not detect a supported package manager."
    echo "Please install Gum manually by following the instructions at:"
    echo "https://github.com/charmbracelet/gum#installation"
    exit 1
fi

if command -v gum &> /dev/null; then
    echo "✅ Installation complete! You can now run the DBMS:"
    echo "   ./dbms.sh"
else
    echo "❌ Installation failed. Please install Gum manually."
fi
