# Use Arch Linux as the base image
FROM archlinux:latest

# Install dependencies
RUN pacman -Syu --needed --noconfirm base-devel boost catch2 cmake ffmpeg fmt git glslang libzip lz4 \
    mbedtls ninja nlohmann-json openssl opus qt5 sdl2 zlib zstd zip unzip qt6-base qt6-tools qt6-svg \
    qt6-declarative qt6-webengine sdl3 qt6-multimedia clang qt6-wayland fuse2 rapidjson wget sdl3 dos2unix \
    xorg-server-xvfb patchelf strace zsync

# Set working directory
WORKDIR /root

# Copy the build script
COPY build-eden.sh /root/build-eden.sh
RUN chmod +x /root/build-eden.sh

# Convert any CRLF line endings to just LF
RUN dos2unix /root/build-eden.sh

# Set output directory as a volume
VOLUME ["/output"]

# Set default entrypoint
ENTRYPOINT ["/root/build-eden.sh"]
