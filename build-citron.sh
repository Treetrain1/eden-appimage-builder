#!/bin/bash
set -e  # Exit on error

# ============================================
# Citron Build Script for Docker with WSL
# ============================================
# This script:
# - Clones or updates the Citron repository
# - Checks out a specific version (default: master)
# - Builds Citron using CMake and Ninja
# - Creates an AppImage package
# - Saves the output to /output
# ============================================
# # ============================================

# Set the Citron version (default to 'master' if not provided)
CITRON_VERSION=${CITRON_VERSION:-master}
CITRON_BUILD_MODE=${CITRON_BUILD_MODE:-steamdeck}  # Default to SteamDeck build
OUTPUT_LINUX_BINARIES=${OUTPUT_LINUX_BINARIES:-false}  # Default to not output binaries

# Define build configurations
case "$CITRON_BUILD_MODE" in
  release)
    CXX_FLAGS="-march=native -mtune=native -Wno-error"
    C_FLAGS="-march=native -mtune=native"
    ;;
  steamdeck)
    CXX_FLAGS="-march=znver2 -mtune=znver2 -Wno-error"
    C_FLAGS="-march=znver2 -mtune=znver2"
    ;;
  compatibility)
    CXX_FLAGS="-march=core2 -mtune=core2 -Wno-error"
    C_FLAGS="-march=core2 -mtune=core2"
    ;;
  debug)
    CXX_FLAGS="-march=native -mtune=native -Wno-error"
    C_FLAGS="-march=native -mtune=native"
    BUILD_TYPE=Debug
    ;;
  *)
    echo "❌ Error: Unknown build mode '$CITRON_BUILD_MODE'. Use 'release', 'steamdeck', 'compatibility', or 'debug'."
    exit 1
    ;;
esac

BUILD_TYPE=${BUILD_TYPE:-Release}  # Default to Release mode

echo "🛠️ Building Citron (Version: ${CITRON_VERSION}, Mode: ${CITRON_BUILD_MODE}, Build: ${BUILD_TYPE})"

# Clone repository
echo "📥 Cloning Citron repository..."
cd /root
if ! git clone --recursive https://git.citron-emu.org/Citron/Citron.git /root/Citron; then
    echo "❌ Error: Failed to clone the Citron repository."
    echo "🔎 Please check the repository availability or visit the official Discord community for help: https://citron-emu.org/"
    exit 1
fi
cd /root/Citron
git checkout ${CITRON_VERSION} || git checkout tags/${CITRON_VERSION}

# Build Citron
mkdir -p /root/Citron/build
cd /root/Citron/build

cmake .. -GNinja \
  -DCITRON_ENABLE_LTO=ON \
  -DCITRON_USE_BUNDLED_VCPKG=ON \
  -DCITRON_TESTS=OFF \
  -DCITRON_USE_LLVM_DEMANGLE=OFF \
  -DCMAKE_INSTALL_PREFIX=/usr \
  -DCMAKE_CXX_FLAGS="$CXX_FLAGS" \
  -DCMAKE_C_FLAGS="$C_FLAGS" \
  -DUSE_DISCORD_PRESENCE=OFF \
  -DBUNDLE_SPEEX=ON \
  -DCMAKE_BUILD_TYPE=$BUILD_TYPE

ninja
sudo ninja install

# Set output file name
if [[ "$CITRON_VERSION" == "master" ]]; then
    OUTPUT_NAME="citron-nightly-${CITRON_BUILD_MODE}"
else
    OUTPUT_NAME="citron-${CITRON_VERSION}-${CITRON_BUILD_MODE}"
fi

# Copy Linux binaries if enabled
if [ "$OUTPUT_LINUX_BINARIES" = "true" ]; then
    mkdir -p /output/linux-binaries-${OUTPUT_NAME}
    cp -r /root/Citron/build/bin/* /output/linux-binaries-${OUTPUT_NAME}/
    echo "✅ Linux binaries copied to /output/linux-binaries-${OUTPUT_NAME}"
fi

# Build the AppImage
cd /root/Citron
sudo /root/Citron/appimage-builder.sh citron /root/Citron/build

# Prepare AppImage deployment
cd /root/Citron/build/deploy-linux
sudo cp /usr/lib/libSDL3.so* /root/Citron/build/deploy-linux/AppDir/usr/lib/
sudo wget https://github.com/AppImage/appimagetool/releases/download/continuous/appimagetool-x86_64.AppImage
chmod +x appimagetool-x86_64.AppImage
# Workaround for lack of FUSE support in WSL
./appimagetool-x86_64.AppImage --appimage-extract
chmod +x ./squashfs-root/AppRun
./squashfs-root/AppRun AppDir

# Move the most recently created AppImage to a shared output folder
mkdir -p /output
APPIMAGE_PATH=$(ls -t /root/Citron/build/deploy-linux/*.AppImage 2>/dev/null | head -n 1)

if [[ -n "$APPIMAGE_PATH" ]]; then
    mv -f "$APPIMAGE_PATH" "/output/${OUTPUT_NAME}.AppImage"
    echo "✅ Build complete! The AppImage is located in /output/${OUTPUT_NAME}.AppImage"
else
    echo "❌ Error: No .AppImage file found in /root/Citron/build/deploy-linux/"
    exit 1
fi
