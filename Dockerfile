# Build stage: compile DuoLint against a pinned Swift toolchain.
FROM swift:6.4-noble AS build

WORKDIR /src

# Resolve dependencies first so this layer caches independently of source edits.
COPY Package.swift Package.resolved ./
RUN swift package resolve

COPY Sources ./Sources
RUN swift build -c release --product DuoLint

# Runtime stage: Swift runtime libraries only, no compiler.
FROM swift:6.4-noble-slim

COPY --from=build /src/.build/release/DuoLint /usr/local/bin/DuoLint
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
