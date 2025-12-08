FROM ghcr.io/actions/actions-runner:latest

# Install Node.js 20 and .NET 8 SDK using distro-agnostic installers
RUN apt-get update && \
    apt-get install -y curl wget && \
    \
    # Install Node.js 20 (NodeSource)
    curl -fsSL https://deb.nodesource.com/setup_20.x | bash - && \
    apt-get install -y nodejs && \
    \
    # Install .NET 8 SDK using Microsoft's official install script
    wget https://dot.net/v1/dotnet-install.sh -O /tmp/dotnet-install.sh && \
    bash /tmp/dotnet-install.sh --channel 8.0 --install-dir /usr/share/dotnet && \
    ln -s /usr/share/dotnet/dotnet /usr/bin/dotnet && \
    rm /tmp/dotnet-install.sh && \
    \
    # Cleanup
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Actions runner entrypoint
ENTRYPOINT ["/home/runner/run.sh"]
