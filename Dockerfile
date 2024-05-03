# Use an official Ubuntu image as a base
FROM ubuntu:latest

# Install necessary dependencies
RUN apt-get update && \
    apt-get install -y \
    curl \
    git \
    wget \
    unzip \
    xz-utils \
    libglu1-mesa \
    cmake \
    ninja-build \
    build-essential \
    clang \
    pkg-config  # Add pkg-config package here

# Set up environment variables
ENV FLUTTER_HOME=/flutter
ENV PATH=$FLUTTER_HOME/bin:$PATH

# Download and install Flutter SDK
RUN git clone https://github.com/flutter/flutter.git -b stable $FLUTTER_HOME

# Install Flutter dependencies
RUN flutter doctor

# Set the working directory in the container
WORKDIR /app

# Copy the current directory contents into the container at /app
COPY . /app

# Run flutter pub get to install dependencies
RUN flutter pub get

# Set CMake variables
ENV CMAKE_MAKE_PROGRAM=ninja

# Set C++ compiler
ENV CXX=clang++

# Build the Flutter project
RUN flutter build linux
