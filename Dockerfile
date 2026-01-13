FROM ubuntu:22.04

# =========================
# Base dependencies
# =========================
RUN apt-get update && apt-get install -y \
    curl \
    git \
    unzip \
    xz-utils \
    openjdk-17-jdk \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# =========================
# Flutter SDK
# =========================
RUN git clone https://github.com/flutter/flutter.git -b stable /flutter
ENV PATH="/flutter/bin:$PATH"

# =========================
# Android SDK
# =========================
ENV ANDROID_HOME=/android-sdk
ENV JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
ENV PATH="$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$PATH"

RUN mkdir -p /android-sdk/cmdline-tools \
    && curl -o /tmp/android-sdk.zip https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip \
    && unzip /tmp/android-sdk.zip -d /android-sdk/cmdline-tools \
    && mv /android-sdk/cmdline-tools/cmdline-tools /android-sdk/cmdline-tools/latest \
    && rm /tmp/android-sdk.zip

RUN yes | sdkmanager --licenses
RUN sdkmanager \
    "platform-tools" \
    "platforms;android-34" \
    "build-tools;34.0.0"

# =========================
# CI optimization
# =========================
ENV GRADLE_USER_HOME=/root/.gradle
ENV PUB_CACHE=/root/.pub-cache
ENV GRADLE_OPTS="-Dorg.gradle.jvmargs=-Xmx1536m -Dorg.gradle.daemon=false"
ENV _JAVA_OPTIONS="-Xmx1536m"

# =========================
# Flutter preparation
# =========================
RUN flutter precache

# Hanya Android (penting untuk Windows CI)
RUN flutter config --no-enable-web \
    && flutter config --no-enable-linux-desktop \
    && flutter config --no-enable-macos-desktop \
    && flutter config --no-enable-windows-desktop

# =========================
# Workdir
# =========================
WORKDIR /app

# Cache dependencies
COPY pubspec.* ./
RUN flutter pub get

# Copy source
COPY . .

# Jangan build di Dockerfile
# Build dijalankan saat docker run di Jenkins
