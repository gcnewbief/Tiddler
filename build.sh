#!/usr/bin/env bash
# Build tiddler (angelfish 23.08.5 fork) for arm64 noble inside qemu-user docker.
# Requires: qemu binfmt registered, image built via Dockerfile in buildenv/.
set -euo pipefail
BUILDDIR="${1:-build2}"   # build2 = no-adblock (Corrosion disabled); build = with adblock

docker build --network host --platform linux/arm64 -t angelfish-builder buildenv
docker run --rm --network host --platform linux/arm64 \
  -v "$PWD/angelfish-src/angelfish-23.08.5:/src" \
  -v "$PWD/build-out:/out" \
  angelfish-builder bash -c "cd /src && cmake -B $BUILDDIR -GNinja -DCMAKE_BUILD_TYPE=Release ${2:-} && cmake --build $BUILDDIR -j\$(nproc)"

echo "Binary: angelfish-src/angelfish-23.08.5/$BUILDDIR/bin/angelfish"
