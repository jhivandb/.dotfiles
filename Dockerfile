FROM ubuntu:24.04

# Install dependencies
RUN apt-get update && apt-get install -y \
    curl \
    git \
    xz-utils \
    sudo \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Create a non-root user
ARG USERNAME=jhivandb
ARG USER_UID=1001
ARG USER_GID=1001

RUN groupadd --gid $USER_GID $USERNAME \
    && useradd --uid $USER_UID --gid $USER_GID -m $USERNAME \
    && echo "$USERNAME ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Switch to non-root user
USER $USERNAME
WORKDIR /home/$USERNAME

# Install Nix (single-user installation for simplicity in containers)
RUN curl -L https://nixos.org/nix/install | sh -s -- --no-daemon

# Set up Nix environment
ENV PATH="/home/$USERNAME/.nix-profile/bin:${PATH}"
ENV NIX_PATH="/home/$USERNAME/.nix-defexpr/channels"

# Configure Nix
RUN mkdir -p /home/$USERNAME/.config/nix && \
    echo "experimental-features = nix-command flakes" >> /home/$USERNAME/.config/nix/nix.conf

# Set USER environment variable for home-manager
ENV USER=$USERNAME

# Source nix profile and install home-manager
RUN . /home/$USERNAME/.nix-profile/etc/profile.d/nix.sh && \
    nix-channel --add https://github.com/nix-community/home-manager/archive/master.tar.gz home-manager && \
    nix-channel --update && \
    export USER=$USERNAME && \
    nix-shell '<home-manager>' -A install

# Create config directory
RUN mkdir -p /home/$USERNAME/.config/home-manager

# Set working directory
WORKDIR /home/$USERNAME

# Default command - source nix profile on start
CMD ["/bin/bash", "-c", "source ~/.nix-profile/etc/profile.d/nix.sh && exec /bin/bash"]
