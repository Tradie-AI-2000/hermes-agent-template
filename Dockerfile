FROM ghcr.io/astral-sh/uv:python3.12-bookworm-slim

# Install essential system dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    curl ca-certificates git unzip nodejs npm && \
    rm -rf /var/lib/apt/lists/*

# Install Hermes Agent core
# We use a clean install to ensure we have the latest stable binary and tools
RUN git clone --depth 1 https://github.com/NousResearch/hermes-agent.git /tmp/hermes-agent && \
    cd /tmp/hermes-agent && \
    uv pip install --system --no-cache -e ".[all]" && \
    rm -rf /tmp/hermes-agent/.git

# Fix the Web UI: 
# We avoid the 'npm run build' trap that crashes Railway's 1GB limit.
# The agent is configured to use the stable assets.
ENV HERMES_SKIP_WEB_BUILD=1

# Setup gbrain / bun tools
RUN curl -fsSL https://bun.sh/install | bash && \
    git clone --depth 1 https://github.com/garrytan/gbrain.git /opt/gbrain && \
    cd /opt/gbrain && \
    /root/.bun/bin/bun install && \
    /root/.bun/bin/bun link

RUN ln -sf /root/.bun/bin/bun /usr/local/bin/bun && \
    ln -sf /root/.bun/bin/gbrain /usr/local/bin/gbrain

ENV PATH="/root/.bun/bin:$PATH"

# Install app-specific requirements
COPY requirements.txt /app/requirements.txt
RUN uv pip install --system --no-cache -r /app/requirements.txt

# Prepare data directories
RUN mkdir -p /data/.hermes

# Copy admin server files
COPY server.py /app/server.py
COPY templates/ /app/templates/
COPY start.sh /app/start.sh
RUN chmod +x /app/start.sh

# Environment setup
ENV HOME=/data
ENV HERMES_HOME=/data/.hermes

CMD ["/app/start.sh"]
