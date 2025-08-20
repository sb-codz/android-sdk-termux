#!/bin/bash

# Android SDK and NDK Uninstaller for Termux
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Installation directories
SDK_DIR="$PREFIX/opt/android-sdk"
NDK_DIR="$PREFIX/opt/android-ndk"
INSTALL_DIR="$PREFIX/opt"

# Java Home directory
JAVA_HOME_DIR="/data/data/com.termux/files/usr/lib/jvm/java-21-openjdk"

# Shell configuration files
BASHRC="$PREFIX/etc/bash.bashrc"
ZSHRC="$HOME/.zshrc"
FISH_CONFIG="$HOME/.config/fish/config.fish"

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

remove_android_env() {
    local config_file="$1"
    local shell_name="$2"
    
    if [ ! -f "$config_file" ]; then
        return 0
    fi
    
    # Create temporary file without Android/Java environment variables
    grep -v -E "ANDROID_(HOME|NDK_HOME|NDK_ROOT)|JAVA_HOME|Android SDK and NDK paths|\$ANDROID_(HOME|NDK_HOME)|\$JAVA_HOME" "$config_file" > "${config_file}.tmp"
    
    # Replace original file with cleaned version
    mv "${config_file}.tmp" "$config_file"
    
    log_info "Removed Android and Java environment from $config_file"
}

cleanup_environment() {
    log_info "Cleaning up environment variables..."
    
    # Remove from Termux bashrc
    remove_android_env "$BASHRC" "bash"
    
    # Remove from zsh (if exists)
    if [ -f "$ZSHRC" ]; then
        remove_android_env "$ZSHRC" "zsh"
    fi
    
    # Remove from fish (if exists)
    if [ -f "$FISH_CONFIG" ]; then
        remove_android_env "$FISH_CONFIG" "fish"
    fi
    
    # Also clean up from current session
    unset ANDROID_HOME 2>/dev/null || true
    unset ANDROID_NDK_HOME 2>/dev/null || true
    unset ANDROID_NDK_ROOT 2>/dev/null || true
    unset JAVA_HOME 2>/dev/null || true
    
    # Remove Android and Java paths from current PATH
    export PATH=$(echo $PATH | sed -e "s|$JAVA_HOME_DIR/bin:||g")
    export PATH=$(echo $PATH | sed -e "s|$SDK_DIR/cmdline-tools/latest/bin:||g")
    export PATH=$(echo $PATH | sed -e "s|$SDK_DIR/platform-tools:||g")
    export PATH=$(echo $PATH | sed -e "s|$NDK_DIR:||g")
}

remove_installation() {
    log_info "Removing Android SDK and NDK..."
    
    if [ -d "$SDK_DIR" ]; then
        rm -rf "$SDK_DIR"
        log_success "Removed Android SDK: $SDK_DIR"
    else
        log_warning "Android SDK not found at $SDK_DIR"
    fi
    
    if [ -d "$NDK_DIR" ]; then
        rm -rf "$NDK_DIR"
        log_success "Removed Android NDK: $NDK_DIR"
    else
        log_warning "Android NDK not found at $NDK_DIR"
    fi
    
    # Remove empty opt directory if it exists
    if [ -d "$INSTALL_DIR" ] && [ -z "$(ls -A $INSTALL_DIR)" ]; then
        rmdir "$INSTALL_DIR"
        log_info "Removed empty directory: $INSTALL_DIR"
    fi
}

verify_uninstallation() {
    log_info "Verifying uninstallation..."
    
    if [ ! -d "$SDK_DIR" ] && [ ! -d "$NDK_DIR" ]; then
        log_success "Android SDK and NDK completely removed!"
        return 0
    else
        log_error "Uninstallation may not have completed fully"
        return 1
    fi
}

show_manual_cleanup_instructions() {
    echo -e "${YELLOW}If automatic cleanup failed, manually remove these lines from:${NC}"
    echo ""
    echo "1. $BASHRC"
    echo "2. $ZSHRC (if exists)"
    echo "3. $FISH_CONFIG (if exists)"
    echo ""
    echo "Remove any lines containing:"
    echo "- ANDROID_HOME"
    echo "- ANDROID_NDK_HOME" 
    echo "- ANDROID_NDK_ROOT"
    echo "- JAVA_HOME"
    echo "- Android SDK and NDK paths"
    echo "- References to Android SDK/NDK directories"
    echo "- References to Java paths"
}

main() {
    echo -e "${GREEN}Android SDK and NDK Uninstaller${NC}"
    echo "=========================================="
    
    # Check if anything is installed
    if [ ! -d "$SDK_DIR" ] && [ ! -d "$NDK_DIR" ]; then
        log_warning "No Android SDK or NDK installation found!"
        echo "Nothing to uninstall."
        exit 0
    fi
    
    # Confirm uninstallation
    echo -e "${YELLOW}This will completely remove Android SDK and NDK from your system.${NC}"
    read -p "Are you sure you want to continue? (y/N): " confirm
    
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        echo "Uninstallation cancelled."
        exit 0
    fi
    
    # Remove installation
    remove_installation
    
    # Clean up environment
    cleanup_environment
    
    # Verify uninstallation
    if verify_uninstallation; then
        log_success "Uninstallation completed successfully!"
        
        echo ""
        echo -e "${GREEN}Uninstallation Summary:${NC}"
        echo "✓ Removed Android SDK"
        echo "✓ Removed Android NDK" 
        echo "✓ Cleaned up environment variables"
        echo "✓ Removed PATH modifications"
        echo ""
        echo -e "${YELLOW}Please restart Termux for changes to take full effect.${NC}"
        
    else
        log_error "Uninstallation may have encountered issues"
        show_manual_cleanup_instructions
        exit 1
    fi
}

# Run main function
main "$@"
