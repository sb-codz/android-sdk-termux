#!/bin/bash
set -e

# Colors
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'

# URLs
SDK_URL="https://github.com/Keyaru-code/android-sdk-termux/releases/download/35.0.0/android-sdk.7z"
NDK_URL="https://github.com/Keyaru-code/android-sdk-termux/releases/download/35.0.0/android-ndk.7z"

# Directories
TMP_DIR="$TMPDIR/android-sdk-install"
INSTALL_DIR="$PREFIX/opt"
SDK_DIR="$INSTALL_DIR/android-sdk"
NDK_DIR="$INSTALL_DIR/android-ndk"

# Shell configs
BASHRC="$PREFIX/etc/bash.bashrc"
ZSHRC="$HOME/.zshrc"
FISH_CONFIG="$HOME/.config/fish/config.fish"

# Dependencies
DEPS=("gradle" "p7zip" "curl")

# Logging
log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

# Choose JDK version
choose_jdk_version() {
    echo -e "${YELLOW}Choose JDK version to install:${NC}"
    echo "1) OpenJDK 21"
    echo "2) OpenJDK 17"
    read -rp "Enter choice [1 or 2]: " choice

    case "$choice" in
        1) JDK_VERSION="21"; JAVA_HOME_DIR="$PREFIX/lib/jvm/openjdk-21"; DEPS+=("openjdk-21");;
        2) JDK_VERSION="17"; JAVA_HOME_DIR="$PREFIX/lib/jvm/openjdk-17"; DEPS+=("openjdk-17");;
        *) log_error "Invalid choice. Please run the script again.";;
    esac
}

# Check dependencies
check_dependencies() {
    log_info "Checking dependencies..."
    for dep in "${DEPS[@]}"; do
        if pkg list-installed | grep -q "$dep"; then
            log_info "✓ $dep is installed"
        else
            log_warning "$dep not installed, installing..."
            pkg install -y "$dep" || log_error "Failed to install $dep"
        fi
    done
    [ ! -d "$JAVA_HOME_DIR" ] && log_error "Java installation not found at $JAVA_HOME_DIR"
}

# Download & extract
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

# Setup environment
setup_environment() {
    log_info "Setting up environment variables..."
    export ANDROID_HOME="$SDK_DIR"
    export ANDROID_NDK_HOME="$NDK_DIR"
    export ANDROID_NDK_ROOT="$NDK_DIR"
    export JAVA_HOME="$JAVA_HOME_DIR"
    export PATH="$JAVA_HOME/bin:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$ANDROID_NDK_HOME:$PATH"
    detect_shell_and_update
}

detect_shell_and_update() {
    update_shell_config "$BASHRC" "bash"
    [ -f "$ZSHRC" ] && update_shell_config "$ZSHRC" "zsh"
    [ -f "$FISH_CONFIG" ] && update_shell_config "$FISH_CONFIG" "fish"
}

update_shell_config() {
    local config_file="$1"
    local shell_name="$2"
    remove_existing_env "$config_file"

    echo "" >> "$config_file"
    echo "# Android SDK, NDK, and Java paths" >> "$config_file"

    if [ "$shell_name" = "fish" ]; then
        echo "set -x ANDROID_HOME \"$SDK_DIR\"" >> "$config_file"
        echo "set -x ANDROID_NDK_HOME \"$NDK_DIR\"" >> "$config_file"
        echo "set -x ANDROID_NDK_ROOT \"$NDK_DIR\"" >> "$config_file"
        echo "set -x JAVA_HOME \"$JAVA_HOME_DIR\"" >> "$config_file"
        echo "set -Ux PATH \$JAVA_HOME/bin \$ANDROID_HOME/cmdline-tools/latest/bin \$ANDROID_HOME/platform-tools \$ANDROID_NDK_HOME \$PATH" >> "$config_file"
        echo "" >> "$config_file"
        echo "# Function to switch JDK versions" >> "$config_file"
        echo "function switch_jdk" >> "$config_file"
        echo "    switch \$argv[1]" >> "$config_file"
        echo "        case 17" >> "$config_file"
        echo "            set -x JAVA_HOME \"$PREFIX/lib/jvm/openjdk-17\"" >> "$config_file"
        echo "        case 21" >> "$config_file"
        echo "            set -x JAVA_HOME \"$PREFIX/lib/jvm/openjdk-21\"" >> "$config_file"
        echo "        case '*'" >> "$config_file"
        echo "            echo 'Usage: switch_jdk 17|21'" >> "$config_file"
        echo "    end" >> "$config_file"
        echo "    set -Ux PATH \$JAVA_HOME/bin \$PATH" >> "$config_file"
        echo "end" >> "$config_file"
    else
        echo "export ANDROID_HOME=\"$SDK_DIR\"" >> "$config_file"
        echo "export ANDROID_NDK_HOME=\"$NDK_DIR\"" >> "$config_file"
        echo "export ANDROID_NDK_ROOT=\"$NDK_DIR\"" >> "$config_file"
        echo "export JAVA_HOME=\"$JAVA_HOME_DIR\"" >> "$config_file"
        echo "export PATH=\"\$JAVA_HOME/bin:\$ANDROID_HOME/cmdline-tools/latest/bin:\$ANDROID_HOME/platform-tools:\$ANDROID_NDK_HOME:\$PATH\"" >> "$config_file"
        echo "" >> "$config_file"
        echo "# Function to switch JDK versions" >> "$config_file"
        echo "switch_jdk() {" >> "$config_file"
        echo "    case \"\$1\" in" >> "$config_file"
        echo "        17) export JAVA_HOME=\"$PREFIX/lib/jvm/openjdk-17\" ;;" >> "$config_file"
        echo "        21) export JAVA_HOME=\"$PREFIX/lib/jvm/openjdk-21\" ;;" >> "$config_file"
        echo "        *) echo 'Usage: switch_jdk 17|21' ; return 1 ;;" >> "$config_file"
        echo "    esac" >> "$config_file"
        echo "    export PATH=\"\$JAVA_HOME/bin:\$PATH\"" >> "$config_file"
        echo "}" >> "$config_file"
    fi
    log_info "Updated $config_file with Android and Java environment variables"
}

remove_existing_env() {
    local config_file="$1"
    [ ! -f "$config_file" ] && return 0
    grep -v -E "ANDROID_(HOME|NDK_HOME|NDK_ROOT)|JAVA_HOME|Android SDK, NDK, and Java paths|switch_jdk" "$config_file" > "${config_file}.tmp"
    mv "${config_file}.tmp" "$config_file"
}

verify_installation() {
    log_info "Verifying installation..."
    if [ -d "$SDK_DIR" ] && [ -d "$NDK_DIR" ] && [ -d "$JAVA_HOME_DIR" ]; then
        log_success "Android SDK, NDK, and Java installed successfully!"
        echo ""
        echo -e "${GREEN}Installation Summary:${NC}"
        echo "Android SDK: $SDK_DIR"
        echo "Android NDK: $NDK_DIR"
        echo "Java Home: $JAVA_HOME_DIR"
        echo "ANDROID_HOME: $ANDROID_HOME"
        echo "ANDROID_NDK_HOME: $ANDROID_NDK_HOME"
        echo "JAVA_HOME: $JAVA_HOME"
        echo ""
        echo -e "${YELLOW}Restart Termux or run:${NC}"
        echo "source $BASHRC"
        echo ""
        echo "To switch JDK later: switch_jdk 17 or switch_jdk 21"
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
    choose_jdk_version
    mkdir -p "$TMP_DIR"
    check_dependencies
    mkdir -p "$INSTALL_DIR"
    [ -d "$SDK_DIR" ] && { log_warning "Removing existing Android SDK..."; rm -rf "$SDK_DIR"; }
    [ -d "$NDK_DIR" ] && { log_warning "Removing existing Android NDK..."; rm -rf "$NDK_DIR"; }
    download_and_extract "$SDK_URL" "$INSTALL_DIR"
    download_and_extract "$NDK_URL" "$INSTALL_DIR"
    setup_environment
    verify_installation
    cleanup
    log_success "Installation completed successfully!"
}

main "$@"