FROM ghcr.io/actions/actions-runner:2.330.0

RUN apt-get update && \
    apt-get install -y curl wget && \
    curl -fsSL https://deb.nodesource.com/setup_20.x | bash - && \
    apt-get install -y nodejs && \
    wget https://packages.microsoft.com/config/ubuntu/20.04/packages-microsoft-prod.deb -O packages-microsoft-prod.deb && \
    dpkg -i packages-microsoft-prod.deb && \
    rm packages-microsoft-prod.deb && \
    apt-get update && \
    apt-get install -y dotnet-sdk-8.0 && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# adjust path/script name to whatever you actually have in the image
ENTRYPOINT ["/home/runner/run.sh"]
