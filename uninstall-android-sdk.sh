#!/data/data/com.termux/files/usr/bin/bash
set -e

echo "[*] Removing Android SDK and NDK..."
rm -rf "$PREFIX/opt/android-sdk"
rm -rf "$PREFIX/opt/android-ndk"

echo "[*] Cleaning environment variables..."
clean_shell_config() {
    local config_file="$1"
    [ -f "$config_file" ] || return 0
    grep -v -E "ANDROID_(HOME|NDK_HOME|NDK_ROOT)|JAVA_HOME|Android SDK|# Android paths" "$config_file" > "${config_file}.tmp"
    mv "${config_file}.tmp" "$config_file"
}

clean_shell_config "$PREFIX/etc/bash.bashrc"
clean_shell_config "$HOME/.zshrc" 2>/dev/null || true
clean_shell_config "$HOME/.config/fish/config.fish" 2>/dev/null || true

echo "[√] Android SDK completely removed"
exit 0
