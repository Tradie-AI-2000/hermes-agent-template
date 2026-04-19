FROM ghcr.io/astral-sh/uv:python3.12-bookworm-slim

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    curl ca-certificates git unzip nodejs npm && \
    rm -rf /var/lib/apt/lists/*

# Install hermes-agent
RUN git clone --depth 1 https://github.com/NousResearch/hermes-agent.git /tmp/hermes-agent && \
    cd /tmp/hermes-agent && \
    uv pip install --system --no-cache -e ".[all]" && \
    rm -rf /tmp/hermes-agent/.git

# Build hermes web UI
RUN cd /tmp/hermes-agent/web 2>/dev/null && \
    npm install && npm run build || true

# Install bun + gbrain
RUN curl -fsSL https://bun.sh/install | bash && \
    export PATH="/root/.bun/bin:$PATH" && \
    git clone --depth 1 https://github.com/garrytan/gbrain.git /opt/gbrain && \
    cd /opt/gbrain && \
    /root/.bun/bin/bun install && \
    /root/.bun/bin/bun link

ENV PATH="/root/.bun/bin:$PATH"

COPY requirements.txt /app/requirements.txt
RUN uv pip install --system --no-cache -r /app/requirements.txt

RUN mkdir -p /data/.hermes

COPY server.py /app/server.py
COPY templates/ /app/templates/
COPY start.sh /app/start.sh
RUN chmod +x /app/start.sh

ENV HOME=/data
ENV HERMES_HOME=/data/.hermes

CMD ["/app/start.sh"]
