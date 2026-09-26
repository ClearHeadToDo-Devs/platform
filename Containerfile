# Toolchain image for sandboxed agent runs (see scripts/agent-run).
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

# Claude Code's postinstall links its native binary. npm blocks dependency
# lifecycle scripts by default, so approve only this package explicitly.
RUN npm install -g --allow-scripts=@anthropic-ai/claude-code @anthropic-ai/claude-code \
    && npm install -g --ignore-scripts @earendil-works/pi-coding-agent@0.85.1 \
    && luarocks --lua-version=5.1 install busted \
    && luarocks --lua-version=5.1 install nlua

# check-jsonschema for scripts/validate-pinned, isolated by uv. Its own layer
# so adding it does not rebuild the pacman layer from a newer Arch.
RUN UV_TOOL_DIR=/opt/uv-tools UV_TOOL_BIN_DIR=/usr/local/bin uv tool install check-jsonschema

# uid 1000 so `podman run --userns=keep-id` maps the agent onto the host user
# and its commits in the mounted clone stay owned by that user.
RUN useradd --create-home --uid 1000 agent \
    && mkdir -p /home/agent/.cargo/registry /home/agent/target /home/agent/.pi/agent \
    && chown -R agent:agent /home/agent/.cargo /home/agent/target /home/agent/.pi

# One build directory shared by every run (the agent-target volume), so a run
# recompiles only what its branch changed.
ENV CARGO_TARGET_DIR=/home/agent/target

USER agent
RUN git config --global user.name "agent" \
    && git config --global user.email "agent@localhost" \
    && git config --global safe.directory '*'

WORKDIR /job/work
