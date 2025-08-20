# Android SDK & NDK Termux Installer

A one-command installer for Android SDK and NDK on Termux, providing a complete Android development environment.

## Features

- Complete Android SDK installation
- Android NDK (Native Development Kit)
- Automatic dependency management (OpenJDK 21, Gradle, p7zip)
- Multi-shell support (Bash, Zsh, Fish)
- Automatic environment configuration
- Clean installation with verification

## Quick Installation

Run this single command to install:

```bash
curl -sL https://github.com/Keyaru-code/android-sdk-termux/raw/main/android-sdk.sh | bash
```

## Uninstall 
```
curl -sL https://github.com/Keyaru-code/android-sdk-termux/raw/main/uninstall-android-sdk.sh | bash
```

## What Gets Installed

- **Android SDK** (version 35.0.0)
- **Android NDK** 
- **OpenJDK 21**
- **Gradle** build system
- **p7zip** for extraction

## Installation Locations

- SDK: `$PREFIX/opt/android-sdk`
- NDK: `$PREFIX/opt/android-ndk`

## Environment Variables

The script automatically sets up:
- `ANDROID_HOME`: Points to Android SDK
- `ANDROID_NDK_HOME`: Points to Android NDK  
- `ANDROID_NDK_ROOT`: Points to Android NDK
- Updates `PATH` to include SDK tools

## Supported Shells

- Bash (`.bashrc`)
- Zsh (`.zshrc`) 
- Fish (`config.fish`)
- Other shells (manual configuration required)

## Post-Installation

After installation, restart your shell or run:
```bash
source ~/.bashrc  # For bash users
# or
source ~/.zshrc   # For zsh users
```

Verify installation with:
```bash
sdkmanager --list
ndk-build --version
```

## Manual Environment Setup

If the automatic setup fails, add these lines to your shell configuration:

```bash
export ANDROID_HOME="$PREFIX/opt/android-sdk"
export ANDROID_NDK_HOME="$PREFIX/opt/android-ndk"
export ANDROID_NDK_ROOT="$PREFIX/opt/android-ndk"
export PATH="$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$ANDROID_NDK_HOME:$PATH"
```

## Troubleshooting

1. **Installation fails**: Check your internet connection and storage space
2. **Environment variables not set**: Restart your shell or manually add them
3. **Command not found**: Verify the PATH was updated correctly

## Requirements

- Termux app (latest version)
- Internet connection
- Approximately 2GB of free storage

## License

This project is open source and available under the MIT License.

## Disclaimer

This installer downloads pre-built Android SDK and NDK packages from GitHub releases. Use at your own risk for development purposes.

## Support

If you encounter issues:
1. Check the troubleshooting section above
2. Ensure you have enough storage space
3. Verify your Termux installation is up to date
