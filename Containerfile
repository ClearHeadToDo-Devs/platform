# Toolchain image for sandboxed agent runs (see the agent-sandbox repository's README).
# Built as root; the sandbox builds its own layer over it.
#
# Tools only: no platform code and no gate. Rebuild when a tool changes, not
# when the code does. The package list mirrors what the repositories' gates
# need (scripts/validate-pinned and each submodule's .githooks/pre-push).
FROM docker.io/library/archlinux@sha256:f3691b4dde62ba4c4b6f0ae2c1fbf28e8c0c8c4b9a35c7e06dc1f70e21aa29f6

RUN printf '%s\n' 'Server=https://archive.archlinux.org/repos/2026/09/25/$repo/os/$arch' \
        > /etc/pacman.d/mirrorlist \
    && pacman -Syu --noconfirm --needed \
        base-devel git jq ripgrep \
        rust rust-wasm \
        nodejs npm tree-sitter-cli \
        python python-jsonschema uv \
        neovim lua51 luarocks \
    && pacman -Scc --noconfirm

RUN luarocks --lua-version=5.1 install busted \
    && luarocks --lua-version=5.1 install nlua

# check-jsonschema for scripts/validate-pinned, isolated by uv. Its own layer
# so adding it does not rebuild the pacman layer from a newer Arch.
RUN UV_TOOL_DIR=/opt/uv-tools UV_TOOL_BIN_DIR=/usr/local/bin uv tool install check-jsonschema

# topiary for tree-sitter-actions' formatting tests; not packaged for Arch.
RUN cargo install --locked --root /usr/local topiary-cli@0.7.3 \
    && rm -rf /root/.cargo/registry

# Graphviz for clearhead.nvim's graph-view spec, which is pending without it.
RUN pacman -S --noconfirm --needed graphviz && pacman -Scc --noconfirm

# Java and ROBOT for the ontology's gate (ontology/v5/Makefile) and the graph
# shapes check; ROBOT pinned by checksum, as in the ontology's CI. pyshacl is
# cached for `uv run --with` in scripts/validate-pinned.
RUN pacman -S --noconfirm --needed jre21-openjdk-headless && pacman -Scc --noconfirm \
    && curl -sSfL https://github.com/ontodev/robot/releases/download/v1.9.10/robot.jar -o /usr/local/lib/robot.jar \
    && echo "16a73c074f3df359a7338a84b4e0788785fe06117f931bb9796e9619ea776105  /usr/local/lib/robot.jar" | sha256sum -c - \
    && printf '#!/bin/sh\nexec java -jar /usr/local/lib/robot.jar "$@"\n' > /usr/local/bin/robot \
    && chmod +x /usr/local/bin/robot
ENV UV_CACHE_DIR=/opt/uv-cache
RUN uv run --with pyshacl==0.40.1 python -c "import pyshacl" && chmod -R a+rwX /opt/uv-cache

# Mount points for the cache volumes in .sandbox/volumes. The sandbox's own
# layer (agents/Containerfile in the agent-sandbox repository) adds the harnesses and the agent
# user over this image, and gives that user /home/agent.
RUN mkdir -p /home/agent/.cargo/registry /home/agent/target

# One build directory shared by every workspace (the target volume), so a
# session recompiles only what its branch changed.
ENV CARGO_TARGET_DIR=/home/agent/target
