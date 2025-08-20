#!/bin/bash

# Android SDK and NDK installer script
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# URLs
SDK_URL="https://github.com/Keyaru-code/android-sdk-termux/releases/download/35.0.0/android-sdk.7z"
NDK_URL="https://github.com/Keyaru-code/android-sdk-termux/releases/download/35.0.0/android-ndk.7z"

# Directories
TMP_DIR="$TMPDIR/android-sdk-install"
INSTALL_DIR="$PREFIX/opt"
SDK_DIR="$INSTALL_DIR/android-sdk"
NDK_DIR="$INSTALL_DIR/android-ndk"

# Dependencies
DEPS=("openjdk-21" "gradle" "p7zip")

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
    exit 1
}

check_dependencies() {
    log_info "Checking dependencies..."
    
    for dep in "${DEPS[@]}"; do
        if pkg list-installed | grep -q "$dep"; then
            log_info "✓ $dep is installed"
        else
            log_warning "$dep is not installed, installing..."
            pkg install -y "$dep" || log_error "Failed to install $dep"
        fi
    done
}

download_and_extract() {
    local url="$1"
    local output_dir="$2"
    local filename=$(basename "$url")
    local tmp_file="$TMP_DIR/$filename"
    
    log_info "Downloading $filename..."
    curl -L "$url" -o "$tmp_file" || log_error "Failed to download $filename"
    
    log_info "Extracting $filename to $output_dir..."
    7z x "$tmp_file" -o"$output_dir" -y > /dev/null || log_error "Failed to extract $filename"
    
    rm -f "$tmp_file"
}

setup_environment() {
    log_info "Setting up environment variables..."
    
    # Common environment variables
    export ANDROID_HOME="$SDK_DIR"
    export ANDROID_NDK_HOME="$NDK_DIR"
    export ANDROID_NDK_ROOT="$NDK_DIR"
    export PATH="$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$ANDROID_NDK_HOME:$PATH"
    
    # Detect shell and update configuration files
    detect_shell_and_update
}

detect_shell_and_update() {
    local shell_name=$(basename "$SHELL")
    local config_file=""
    
    case "$shell_name" in
        "bash")
            config_file="$PREFIX/etc/bash.bashrc"
            ;;
        "zsh")
            config_file="$HOME/.zshrc"
            ;;
        "fish")
            config_file="$HOME/.config/fish/config.fish"
            ;;
        *)
            log_warning "Unknown shell: $shell_name. Please add environment variables manually."
            return
            ;;
    esac
    
    if [ -n "$config_file" ]; then
        update_shell_config "$config_file" "$shell_name"
    fi
}

update_shell_config() {
    local config_file="$1"
    local shell_name="$2"
    
    # Backup config file
    cp "$config_file" "$config_file.backup.$(date +%Y%m%d_%H%M%S)" 2>/dev/null || true
    
    # Remove existing Android environment variables
    sed -i '/ANDROID_HOME\|ANDROID_NDK_HOME\|ANDROID_NDK_ROOT/d' "$config_file" 2>/dev/null || true
    
    # Add new environment variables
    echo "" >> "$config_file"
    echo "# Android SDK and NDK paths" >> "$config_file"
    
    if [ "$shell_name" = "fish" ]; then
        echo "set -x ANDROID_HOME \"$SDK_DIR\"" >> "$config_file"
        echo "set -x ANDROID_NDK_HOME \"$NDK_DIR\"" >> "$config_file"
        echo "set -x ANDROID_NDK_ROOT \"$NDK_DIR\"" >> "$config_file"
        echo "set -x PATH \"\$ANDROID_HOME/cmdline-tools/latest/bin\" \$PATH" >> "$config_file"
        echo "set -x PATH \"\$ANDROID_HOME/platform-tools\" \$PATH" >> "$config_file"
        echo "set -x PATH \"\$ANDROID_NDK_HOME\" \$PATH" >> "$config_file"
    else
        echo "export ANDROID_HOME=\"$SDK_DIR\"" >> "$config_file"
        echo "export ANDROID_NDK_HOME=\"$NDK_DIR\"" >> "$config_file"
        echo "export ANDROID_NDK_ROOT=\"$NDK_DIR\"" >> "$config_file"
        echo "export PATH=\"\$ANDROID_HOME/cmdline-tools/latest/bin:\$ANDROID_HOME/platform-tools:\$ANDROID_NDK_HOME:\$PATH\"" >> "$config_file"
    fi
    
    log_info "Updated $config_file with Android environment variables"
}

verify_installation() {
    log_info "Verifying installation..."
    
    if [ -d "$SDK_DIR" ] && [ -d "$NDK_DIR" ]; then
        log_success "Android SDK and NDK installed successfully!"
        
        echo ""
        echo -e "${GREEN}Installation Summary:${NC}"
        echo "Android SDK: $SDK_DIR"
        echo "Android NDK: $NDK_DIR"
        echo "ANDROID_HOME: $ANDROID_HOME"
        echo "ANDROID_NDK_HOME: $ANDROID_NDK_HOME"
        echo ""
        echo -e "${YELLOW}Please restart your shell or run:${NC}"
        echo "source ~/.${SHELL##*/}rc"
        echo ""
        echo -e "${YELLOW}To verify, run:${NC}"
        echo "sdkmanager --list"
        echo "ndk-build --version"
        
    else
        log_error "Installation verification failed"
    fi
}

cleanup() {
    log_info "Cleaning up temporary files..."
    rm -rf "$TMP_DIR"
}

main() {
    echo -e "${GREEN}Android SDK and NDK Installer${NC}"
    echo "======================================"
    
    # Create temporary directory
    mkdir -p "$TMP_DIR"
    
    # Check and install dependencies
    check_dependencies
    
    # Create install directory
    mkdir -p "$INSTALL_DIR"
    
    # Remove existing installations if they exist
    if [ -d "$SDK_DIR" ]; then
        log_warning "Removing existing Android SDK..."
        rm -rf "$SDK_DIR"
    fi
    
    if [ -d "$NDK_DIR" ]; then
        log_warning "Removing existing Android NDK..."
        rm -rf "$NDK_DIR"
    fi
    
    # Download and extract SDK
    download_and_extract "$SDK_URL" "$INSTALL_DIR"
    
    # Download and extract NDK
    download_and_extract "$NDK_URL" "$INSTALL_DIR"
    
    # Setup environment
    setup_environment
    
    # Verify installation
    verify_installation
    
    # Cleanup
    cleanup
    
    log_success "Installation completed successfully!"
}

# Run main function
main "$@"
