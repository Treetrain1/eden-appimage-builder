# Eden AppImage Builder

This repository contains scripts to build [Eden](https://git.eden-emu.org/eden-emu/eden) using an Arch Linux container. It automates the process of setting up a clean environment and generating an Eden AppImage with support for multiple build modes.

## Features

- Uses Docker or Podman to provide a consistent build environment.
- Supports multiple build modes:
  - `release`: Release mode builds Eden with optimizations based on the device that you are building for better performance.
  - `steamdeck`: Steamdeck mode builds Eden with Steam Deck’s CPU (AMD Van Gogh - Zen 2) optimizations for better performance.
  - `compatibility`: Compatibility mode builds Eden with optimizations for older architectures.
  - `debug`: Debug mode includes additional debugging symbols but is slower.
- Included startup scripts for Windows, Steam Deck, Linux, and macOS (`start_build_<OS>...`) that automate the build process with an interactive prompt for all options.
- Outputs an Eden AppImage in the current working directory.
- Option to output Linux binaries.
- Option to cache the Eden Git repository to speed up subsequent builds or as a fallback.

## Requirements

### Windows

- Windows Subsystem for Linux (WSL) installed and enabled.
- [Docker Desktop for Windows](https://docs.docker.com/desktop/setup/install/windows-install/) installed and running on your system.

### Steam Deck

- [Podman](https://podman.io/) should be pre-installed with SteamOS 3.5+. Verify installation by running:
  ```sh
  podman --version
  ```
  If Podman is not installed, you can install it from the SteamOS Software Center.
- Sufficient disk space (\~5GB for the build process).

### Linux / macOS

- [Docker](https://docs.docker.com/get-docker/) installed with Docker Desktop and/or Docker Engine running.

### **Note for users on ARM-based devices (e.g., macOS M1/M2 or similar ARM64 platforms):**
If you encounter issues during the build process, it may be due to architecture incompatibilities with the docker image. Try one of the following solutions:
- Use an ARM64-compatible container image by specifying the platform explicitly:
   ```sh
   docker build --platform=linux/arm64 -t eden-builder .
   docker run --platform=linux/arm64 --rm -v "$(pwd)":/output eden-builder
   ```
- Install Rosetta 2 (for macOS) and run the container in x86\_64 emulation mode:
   ```sh
   softwareupdate --install-rosetta
   docker run --platform=linux/amd64 --rm -v "$(pwd)":/output eden-builder
   ```

Any feedback or contributions to improve the script for ARM-based host builds is welcome.

## Usage

### Windows

1. Clone this repository:

   ```sh
   git clone https://github.com/Treetrain1/eden-appimage-builder.git
   cd eden-appimage-builder
   ```

   Alternatively, download and extract the repository as a ZIP file.

2. Run the batch script:

   ```sh
   start_build_windows_wsl.bat
   ```

3. Follow the on-screen prompts to select your build options.

4. Ensure an active internet connection for downloading dependencies.

5. The Eden AppImage file will be created in the current directory.

6. After the build process, the script will prompt you to perform optional disk cleanup.

### Linux / macOS

1. Clone this repository:

   ```sh
   git clone https://github.com/Treetrain1/eden-appimage-builder.git
   cd eden-appimage-builder
   ```

   Alternatively, download and extract the repository as a ZIP file.

2. Make the start script executable:
   ```sh
   chmod +x start_build_linux_macOS.sh
   ```

3. Run the linux/macOS build script:
   ```sh
   ./start_build_linux_macOS.sh
   ```

4. Follow the on-screen prompts to select your build mode and Eden version.

5. Ensure an active internet connection for downloading dependencies.

6. The Eden AppImage file will be created in the current directory.

7. The script will prompt you about optional disk cleanup.

### Steam Deck (Podman)

1. Switch to [Desktop Mode](https://help.steampowered.com/en/faqs/view/671A-4453-E8D2-323C).

2. Open a terminal (Konsole is the default terminal app).

3. Ensure you are in a writable directory:
   ```sh
   cd ~
   ```

4. Clone this repository:
   ```sh
   git clone https://github.com/Treetrain1/eden-appimage-builder.git
   cd eden-appimage-builder
   ```

5. Make the start script executable:
   ```sh
   chmod +x start_build_steamdeck_podman.sh
   ```

6. Run the Steam Deck build script:
   ```sh
   ./start_build_steamdeck_podman.sh
   ```

7. Follow the on-screen prompts to select your build mode and Eden version.

8. The Steam Deck may enter sleep mode during the build process. To prevent sleep mode, click the battery icon in the system tray and select "Manually block sleep and screen locking."

9. The Eden AppImage file will be created in the current directory.

10. The script will prompt you about optional disk cleanup.

## Advanced Docker Usage

The startup scripts for each OS cover most use cases, but you can manually run the Docker container using the examples below:

- Use the default command for the latest Eden build optimized for Steam Deck:

  ```sh
  docker run --rm -v "$(pwd)":/output eden-builder
  ```

- Specify a version tag, branch name or commit hash if you need a specific release:

  ```sh
  docker run --rm -e EDEN_VERSION=v0.5-canary-refresh -v "$(pwd)":/output eden-builder
  ```

- Choose a different [build mode](https://git.eden-emu.dev/eden-emu/eden/wiki/Building-for-Linux.-#building-eden-in-release-mode-optimized) (`release`, `steamdeck`, `compatibility`, `debug`):
  ```sh
  docker run --rm -e EDEN_BUILD_MODE=compatibility -e EDEN_VERSION=v0.5-canary-refresh -v "$(pwd)":/output eden-builder
  ```

- Enable Linux binary output if you need separate non-AppImage executables:

  ```sh
  docker run --rm -e OUTPUT_LINUX_BINARIES=true -v "$(pwd)":/output eden-builder
  ```

- Use cache options to speed up subsequent builds by preserving Eden's source repository between runs:

  ```sh
  docker run --rm -e USE_CACHE=true -v "$(pwd)":/output eden-builder
  ```

## Output Naming

The [generated AppImage](https://drive.google.com/drive/folders/1OcB-CffpyZ3bVbi751FJdNLCCSE1K-Rf) filename will follow this format:

- **Latest builds:** `eden-nightly-<build_mode>-<timestamp>-<commit_hash>.AppImage`
- **Versioned builds:** `eden-<version>-<build_mode>.AppImage`

For example:

```sh
eden-nightly-steamdeck-20250228-153045-abcdefg.AppImage
eden-v0.5-canary-refresh-release.AppImage
```

## Troubleshooting

- If the build process fails, check your internet connection and verify that the external dependencies are accessible. Check the [Eden Discord](https://discord.gg/sRkuZpq5aJ) community for more information.
- If you are not using cache, check that the [Eden repository](https://git.eden-emu.dev/eden-emu/eden) is available and online.

## Credits

This script was created with the help of the [Eden Wiki](https://git.eden-emu.dev/eden-emu/eden/wiki/?action=_pages) and members of the [Eden Discord](https://discord.gg/sRkuZpq5aJ) community. This project does not make modified versions of [Eden](https://git.eden-emu.dev/eden-emu/eden).

## License

This project is licensed under the GNU GENERAL PUBLIC LICENSE. See the [LICENSE](./LICENSE) file for details.

