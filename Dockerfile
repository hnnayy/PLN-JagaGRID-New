# Use Ubuntu base image
FROM ubuntu:22.04

# Install dependencies
RUN apt-get update && apt-get install -y \
    curl \
    git \
    unzip \
    xz-utils \
    openjdk-17-jdk \
    && rm -rf /var/lib/apt/lists/*

# Download and install Flutter SDK
RUN git clone https://github.com/flutter/flutter.git -b stable /flutter

# Add Flutter to PATH
ENV PATH="/flutter/bin:$PATH"

# Install Android SDK
RUN mkdir -p /android-sdk/cmdline-tools
RUN curl -o android-sdk.zip https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip
RUN unzip android-sdk.zip -d /android-sdk/cmdline-tools
RUN mv /android-sdk/cmdline-tools/cmdline-tools /android-sdk/cmdline-tools/latest
ENV ANDROID_HOME=/android-sdk
ENV PATH="$ANDROID_HOME/cmdline-tools/latest/bin:$PATH:/flutter/bin"
ENV JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
ENV GRADLE_USER_HOME=/home/builder/.gradle
ENV GRADLE_OPTS="-Dorg.gradle.jvmargs=-Xmx1536m -Dorg.gradle.daemon=false"
ENV _JAVA_OPTIONS="-Xmx1536m"
RUN yes | sdkmanager --licenses
RUN sdkmanager "platform-tools" "platforms;android-34" "build-tools;34.0.0"

# Create a non-root user for building, and give ownership of SDKs and workspace
RUN useradd -m -s /bin/bash builder \
    && mkdir -p /home/builder/.gradle /app \
    && chown -R builder:builder /home/builder /flutter /android-sdk /app

USER builder
ENV HOME=/home/builder

# Pre-download Flutter binaries and enable platforms (run as non-root)
RUN flutter precache
RUN flutter config --enable-web
RUN flutter config --enable-linux-desktop
RUN flutter config --enable-macos-desktop
RUN flutter config --enable-windows-desktop

# Set the working directory
WORKDIR /app

# Copy pubspec files first for better caching (set ownership to builder)
COPY --chown=builder:builder pubspec.* ./

# Get Flutter dependencies
RUN flutter pub get

# Copy the rest of the application code (set ownership to builder)
COPY --chown=builder:builder . .

# NOTE: do NOT run `flutter build` during docker build in CI images.
# Builds must run at container runtime in the CI pipeline so artifacts
# are produced in the mounted workspace and caching works correctly.

# Optional: Build for web or other platforms if needed
# RUN flutter build web

# The resulting APK will be in build/app/outputs/flutter-apk/app-release.apk
