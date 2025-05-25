#!/bin/bash
set -e  # Exit on error

# ============================================
# Eden Build Script
# ============================================
# This script:
# - Clones or updates the official Eden repository
# - Checks out a specific version (default: master)
# - Builds Eden using CMake and Ninja
# - Creates an AppImage package using appimagetool-x86_64.AppImage
# - Saves the output to OUTPUT_DIR
# ============================================
# # ============================================

# Set the Eden version (default to 'master' if not provided)
EDEN_VERSION=${EDEN_VERSION:-master}
EDEN_BUILD_MODE=${EDEN_BUILD_MODE:-steamdeck}  # Default to SteamDeck build
OUTPUT_LINUX_BINARIES=${OUTPUT_LINUX_BINARIES:-false}  # Default to not output binaries
USE_CACHE=${USE_CACHE:-false}  # Default to not using cache

# Set output and working directories
OUTPUT_DIR=${OUTPUT_DIR:-"/output"}
mkdir -p "${OUTPUT_DIR}"
WORKING_DIR=${WORKING_DIR:-"/root"}

# Define build configurations
case "$EDEN_BUILD_MODE" in
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
    echo "❌ Error: Unknown build mode '$EDEN_BUILD_MODE'. Use 'release', 'steamdeck', 'compatibility', or 'debug'."
    exit 1
    ;;
esac

BUILD_TYPE=${BUILD_TYPE:-Release}  # Default to Release mode

echo "🛠️ Building Eden (Version: ${EDEN_VERSION}, Mode: ${EDEN_BUILD_MODE}, Build: ${BUILD_TYPE})"

# Check if EDEN_VERSION exists on the remote repository
EDEN_REPO="https://git.eden-emu.dev/eden-emu/eden.git"

# Check if EDEN_VERSION is a commit hash
if [[ "${EDEN_VERSION}" =~ ^[0-9a-f]{7,40}$ ]]; then
    echo "🔍 Commit hash detected: ${EDEN_VERSION}"
    COMMIT_HASH="${EDEN_VERSION}"
    # Reset EDEN_VERSION to 'master' to later attempt to checkout the commit hash
    EDEN_VERSION="master"
    echo "🔍 Resetting Eden Version to 'master' to later checkout commit hash '${COMMIT_HASH}'"
fi

# Preparing the eden repository
# This section checks if the specified Eden version exists in the remote repository.
# If it doesn't exist, it attempts to use a cached repository if available.
# If the version exists, it clones or updates the repository accordingly.
echo "🔎 Checking if version '${EDEN_VERSION}' exists in the remote repository..."

CACHE_FILENAME="eden.tar.zst"
CACHE_FILE="${OUTPUT_DIR}/${CACHE_FILENAME}"
CLONE_DIR="${WORKING_DIR}/Eden"

# Check if the specified version exists in the remote repository and is accessible
if ! git ls-remote --exit-code --refs "$EDEN_REPO" "refs/heads/${EDEN_VERSION}" > /dev/null && ! git ls-remote --exit-code --refs "$EDEN_REPO" "refs/tags/${EDEN_VERSION}" > /dev/null; then
    echo "⚠️ Warning: The specified version or branch '${EDEN_VERSION}' does not exist in the remote repository or the repository is not accessible."
    
    # Check if the cache file exists and use it if available
    if [ "$USE_CACHE" = "true" ] && [ -f "$CACHE_FILE" ]; then
        echo "📥 Falling back to cached repository ${CACHE_FILENAME}..."
        cp --preserve=all "$CACHE_FILE" "$WORKING_DIR/"
        
        # Extract the cached repository
        tar --use-compress-program=zstd -xf "$CACHE_FILENAME" -C "$WORKING_DIR"

        cd "$CLONE_DIR"
        git config --global --add safe.directory "$CLONE_DIR"
        
        # Try to checkout the cached repository with the specified version
        if ! git checkout "${EDEN_VERSION}" && ! git checkout "tags/${EDEN_VERSION}"; then
            echo "❌ Error: Failed to checkout the cached repository with version '${EDEN_VERSION}'. Please verify the cache is a valid eden repository and try again."
            exit 1
        fi
    else
        echo "❌ Error: Cache option not available."
        echo "🔎 Please verify that ${CACHE_FILENAME} exists in the current directory and is a valid eden repository, enable the use cache option then try again."
        exit 1
    fi
else
    echo "✅ Version '${EDEN_VERSION}' exists in the remote repository."

    cd "$WORKING_DIR"

    # Clone or use existing cached repository
    if [ "$USE_CACHE" = "true" ] && [ -f "$CACHE_FILE" ]; then
        echo "📥 Using cached repository ${CACHE_FILENAME}..."
        cp --preserve=all "$CACHE_FILE" "$WORKING_DIR/"
        
        # Extract the cached repository
        tar --use-compress-program=zstd -xf "$CACHE_FILENAME" -C "$WORKING_DIR"

        cd "$CLONE_DIR"
        git config --global --add safe.directory "$CLONE_DIR"
        
        # Update the repository to the latest commit of the given version, if remote connection fails now, fallback to cached repository
        echo "🔄 Updating the repository to the latest commit of ${EDEN_VERSION}..."
        if ! git fetch --all --tags --prune; then
            echo "⚠️ Warning: Failed to fetch the latest changes from the remote repository. Falling back to the cached repository..."
            cd "$WORKING_DIR"
            if ! git checkout "${EDEN_VERSION}" && ! git checkout "tags/${EDEN_VERSION}"; then
                echo "❌ Error: Failed to checkout the cached repository with version '${EDEN_VERSION}'. Please verify the cache is a valid eden repository and try again."
                exit 1
            fi
        else
            git submodule update --init --recursive # Update submodules
            if ! git reset --hard "origin/${EDEN_VERSION}"; then
                echo "⚠️ Warning: Failed to reset to origin/${EDEN_VERSION}, trying tags/${EDEN_VERSION}..."
                git checkout "tags/${EDEN_VERSION}"
            fi
        fi
    else
        echo "📥 Cloning Eden repository..."
        if ! git clone --recursive "$EDEN_REPO" "$CLONE_DIR"; then
            echo "❌ Error: Failed to clone the Eden repository."
            exit 1
        fi

        cd "$CLONE_DIR"
        git checkout "${EDEN_VERSION}" || git checkout "tags/${EDEN_VERSION}"

        # Cache the repository for future builds if USE_CACHE=true
        cd "$WORKING_DIR"
        if [ "$USE_CACHE" = "true" ]; then
            echo "💾 Caching repository to file ${CACHE_FILENAME}..."
            tar --use-compress-program=zstd -cf "$CACHE_FILE" -C "$WORKING_DIR" Eden
        fi
    fi
fi

# Try to checkout COMMIT_HASH if it was set
if [ -n "$COMMIT_HASH" ]; then
    echo "🔍 Checking out commit hash '${COMMIT_HASH}'..."
    cd "$CLONE_DIR"
    if ! git checkout "$COMMIT_HASH"; then
        echo "❌ Error: Failed to checkout commit hash '${COMMIT_HASH}'."
        exit 1
    fi
fi

echo "✅ Repository is ready at ${CLONE_DIR}"

# Get the short hash of the current commit
cd "$CLONE_DIR"
GIT_COMMIT_HASH=$(git rev-parse --short HEAD)
TIMESTAMP=$(date +"%Y%m%d-%H%M%S")

# Build Eden
mkdir -p ${WORKING_DIR}/Eden/build
cd ${WORKING_DIR}/Eden/build

cmake .. -GNinja \
  -DYUZU_ENABLE_LTO=ON \
  -DYUZU_USE_BUNDLED_VCPKG=ON \
  -DYUZU_TESTS=OFF \
  -DYUZU_USE_LLVM_DEMANGLE=OFF \
  -DCMAKE_INSTALL_PREFIX=/usr \
  -DCMAKE_CXX_FLAGS="$CXX_FLAGS" \
  -DCMAKE_C_FLAGS="$C_FLAGS" \
  -DUSE_DISCORD_PRESENCE=OFF \
  -DBUNDLE_SPEEX=ON \
  -DCMAKE_BUILD_TYPE=$BUILD_TYPE

ninja
ninja install

# Set output file name
if [[ "$EDEN_VERSION" == "master" ]]; then
    OUTPUT_NAME="eden-nightly-${EDEN_BUILD_MODE}-${TIMESTAMP}-${GIT_COMMIT_HASH}"
else
    OUTPUT_NAME="eden-${EDEN_VERSION}-${EDEN_BUILD_MODE}"
fi

# Copy Linux binaries if enabled
if [ "$OUTPUT_LINUX_BINARIES" = "true" ]; then
    mkdir -p ${OUTPUT_DIR}/linux-binaries-${OUTPUT_NAME}
    cp -r ${WORKING_DIR}/Eden/build/bin/* ${OUTPUT_DIR}/linux-binaries-${OUTPUT_NAME}/
    echo "✅ Linux binaries copied to ${OUTPUT_DIR}/linux-binaries-${OUTPUT_NAME}"
fi

# Build the AppImage
cd ${WORKING_DIR}/Eden
${WORKING_DIR}/Eden/.ci/linux/package.sh

# Prepare AppImage deployment
#cd ${WORKING_DIR}/Eden/build/deploy-linux
#cp /usr/lib/libSDL3.so* ${WORKING_DIR}/Eden/build/deploy-linux/AppDir/usr/lib/
#wget https://github.com/AppImage/appimagetool/releases/download/continuous/appimagetool-x86_64.AppImage
#chmod +x appimagetool-x86_64.AppImage
# Workaround for lack of FUSE support in WSL
#./appimagetool-x86_64.AppImage --appimage-extract
#chmod +x ./squashfs-root/AppRun
#./squashfs-root/AppRun AppDir

# Move the most recently created AppImage to a fresh output folder
APPIMAGE_PATH=$(ls -t ${WORKING_DIR}/Eden/*.AppImage 2>/dev/null | head -n 1)

if [[ -n "$APPIMAGE_PATH" ]]; then
    mv -f "$APPIMAGE_PATH" "${OUTPUT_DIR}/${OUTPUT_NAME}.AppImage"
    echo "✅ Build complete! The AppImage is located in ${OUTPUT_DIR}/${OUTPUT_NAME}.AppImage"
else
    echo "❌ Error: No .AppImage file found in ${WORKING_DIR}/Eden/build/deploy-linux/"
    exit 1
fi
