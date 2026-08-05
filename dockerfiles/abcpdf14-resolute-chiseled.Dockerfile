# syntax=docker/dockerfile:1
# Chiseled build for Ubuntu 26.04 (resolute) / .NET 10 only.
#
# Instead of installing a full Ubuntu userland via apt, this cuts just the
# files that ASP.NET Core and ABCpdf's rendering engine actually need, using
# Canonical's Chisel tool against the "ubuntu-26.04" chisel-releases branch:
# https://github.com/canonical/chisel-releases/tree/ubuntu-26.04
#
# This file produces two images from one shared "chisel-common" stage, picked
# with `--target`:
#
#   - final-runtime (default target, ie. plain `docker build` with no
#     --target): the immutable image meant to be shipped. Ends on
#     `USER $APP_UID` and has just the ASP.NET Core runtime.
#   - final-sdk (`--target final-sdk`): meant to be inherited from, not
#     shipped as-is. Has the full dotnet SDK (its slice already
#     essential-chains in the runtime, so nothing is lost), plus a minimal
#     shell (dash's /bin/sh, used as the default RUN shell), bash
#     (/usr/bin/bash, for scripts/tooling that specifically need it), `rm`
#     and `chmod`. fontconfig's `fc-cache` is already in chisel-common. This
#     lets an inheriting Dockerfile do things like:
#
#       COPY Rez/fonts/* /usr/local/share/fonts
#       COPY Rez/fonts/linux_specific/* /usr/local/share/fonts
#       RUN cd /usr/local/share/fonts && rm -f restricted.ttf 49038501.ttf *.txt *.bmp *.zip && fc-cache -f -v
#
#     `cd` is a shell builtin so it comes for free with dash. It does NOT end
#     on `USER $APP_UID` - RUN instructions like the one above need to run as
#     root during the inheriting image's build, matching the existing
#     mcr-aspnet-resolute.Dockerfile convention where the consuming
#     Dockerfile (eg. TestApplication/Dockerfile) sets `USER $APP_UID` itself
#     at the end.
#
# libgtk-3-0 and libegl1 (needed by ABCpdf's embedded Chromium engine for
# headless HTML rendering) have no Chisel slice definitions anywhere upstream
# - Canonical has never sliced the GTK/X11 desktop stack, only server-oriented
# libs. Those two are installed normally in the "apt-extra" stage below, and
# only the files dpkg says they (and whatever they newly pull in) actually own
# are copied into the final image, so apt/dpkg itself never ends up there.
ARG DOTNET_VERSION=10.0

# ---- Stage: chisel-common ----------------------------------------------------
# Everything shared between the runtime and SDK variants.
FROM ubuntu:resolute AS chisel-common
ARG DEBIAN_FRONTEND=noninteractive
ARG CHISEL_VERSION=v1.4.2
ARG CHISEL_SHA384=8e5e8df4dc783dcfa827ca9990ba871af350738de67c51706b3c06bfd4725ab0edbddd9ad4110d1047ecfdc586f7dac6
ARG CHISEL_WRAPPER_VERSION=v1.2.0

# Keep apt's downloaded package/index files in a persistent BuildKit cache
# mount instead of the image layer, so a re-run after a network blip (or a
# --no-cache build) doesn't have to re-fetch everything apt already has.
RUN rm -f /etc/apt/apt.conf.d/docker-clean \
    && echo 'Binary::apt::APT::Keep-Downloaded-Packages "true";' > /etc/apt/apt.conf.d/keep-cache

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt/lists,sharing=locked \
    apt-get update \
    && apt-get install --no-install-recommends -y ca-certificates curl file

RUN chisel_url="https://github.com/canonical/chisel/releases/download/${CHISEL_VERSION}/chisel_${CHISEL_VERSION}_linux_amd64.tar.gz" \
    && curl --fail --show-error --location --output chisel.tar.gz "${chisel_url}" \
    && echo "${CHISEL_SHA384}  chisel.tar.gz" | sha384sum -c - \
    && tar --gzip --extract --no-same-owner --file chisel.tar.gz --directory /usr/bin/ \
    && rm chisel.tar.gz \
    && curl --fail --show-error --location --output /usr/bin/chisel-wrapper \
        "https://raw.githubusercontent.com/canonical/rocks-toolbox/${CHISEL_WRAPPER_VERSION}/chisel-wrapper" \
    && chmod 755 /usr/bin/chisel-wrapper

# Non-root "app" user (uid/gid 1654), matching what
# mcr.microsoft.com/dotnet/runtime-deps:*-resolute-chiseled sets up, so
# downstream Dockerfiles (eg. TestApplication/Dockerfile's `USER $APP_UID`)
# keep working unmodified.
RUN groupadd --gid=1654 app \
    && useradd --no-log-init --uid=1654 --gid=1654 --shell /bin/false app \
    && install --directory --mode 0755 --owner 1654 --group 1654 /rootfs/home/app \
    && mkdir -p /rootfs/etc \
    && grep -E '^(root|app):' /etc/passwd > /rootfs/etc/passwd \
    && grep -E '^(root|app):' /etc/group > /rootfs/etc/group

# Chisel's base-files slice doesn't create the /usr/local FHS tree the way a
# full apt install does. Pre-create /usr/local/share/fonts so an inheriting
# Dockerfile's `COPY *.ttf /usr/local/share/fonts` (a well-known fontconfig
# search path) works without it needing to mkdir first. Harmless empty dir
# in the runtime-only image.
RUN install --directory --mode 0755 /rootfs/usr/local/share/fonts

RUN mkdir -p /rootfs/var/lib/dpkg \
    && chisel-wrapper --generate-dpkg-status /rootfs/var/lib/dpkg/status -- \
        --release ubuntu-26.04 --ignore=unstable --root /rootfs \
            base-files_base \
            base-files_chisel \
            base-files_release-info \
            ca-certificates_data \
            libc6_libs \
            libgcc-s1_libs \
            libssl3t64_libs \
            libstdc++6_libs \
            libicu78_libs \
            tzdata_zoneinfo \
            tzdata-legacy_zoneinfo \
            curl_bins \
            libcurl3t64-gnutls_libs \
            fontconfig_bins \
            fonts-noto-core_fonts \
            fonts-noto-core_config \
            fonts-noto-color-emoji_fonts \
            libasound2t64_libs \
            libatk1.0-0t64_libs \
            libatk-bridge2.0-0t64_libs \
            libatspi2.0-0t64_libs \
            libavahi-client3_libs \
            libavahi-common3_libs \
            libbrotli1_libs \
            libbsd0_libs \
            libcairo2_libs \
            libcups2t64_libs \
            libdatrie1_libs \
            libdbus-1-3_libs \
            libdrm2_libs \
            libfreetype6_libs \
            libfribidi0_libs \
            libgbm1_libs \
            libglib2.0-0t64_libs \
            libgraphite2-3_libs \
            libharfbuzz0b_libs \
            libmd0_libs \
            libnspr4_libs \
            libnss3_libs \
            libpango-1.0-0_libs \
            libpixman-1-0_libs \
            libpng16-16t64_libs \
            libthai0_libs \
            libudev1_libs \
            libwayland-server0_libs \
            libx11-6_libs \
            libxau6_libs \
            libxcb1_libs \
            libxcb-render0_libs \
            libxcb-shm0_libs \
            libxcomposite1_libs \
            libxdamage1_libs \
            libxdmcp6_libs \
            libxext6_libs \
            libxfixes3_libs \
            libxi6_libs \
            libxkbcommon0_libs \
            libxrandr2_libs \
            libxrender1_libs

# ---- Stage: chisel-runtime ---------------------------------------------------
# Adds just the ASP.NET Core runtime on top of chisel-common.
FROM chisel-common AS chisel-runtime
ARG DOTNET_VERSION
RUN chisel-wrapper --generate-dpkg-status /rootfs/var/lib/dpkg/status -- \
        --release ubuntu-26.04 --ignore=unstable --root /rootfs \
            aspnetcore-runtime-${DOTNET_VERSION}_standard

# ---- Stage: chisel-sdk --------------------------------------------------------
# Adds the full dotnet SDK plus a minimal shell/rm/chmod on top of
# chisel-common.
FROM chisel-common AS chisel-sdk
ARG DOTNET_VERSION
RUN chisel-wrapper --generate-dpkg-status /rootfs/var/lib/dpkg/status -- \
        --release ubuntu-26.04 --ignore=unstable --root /rootfs \
            dotnet-sdk-${DOTNET_VERSION}_standard \
            dash_bins \
            bash_bins \
            coreutils_rm-bin \
            coreutils_chmod

# ---- Stage: apt-extra --------------------------------------------------------
FROM ubuntu:resolute AS apt-extra
ARG DEBIAN_FRONTEND=noninteractive

RUN dpkg-query -W -f='${Package}\n' | sort > /base-packages.txt

RUN rm -f /etc/apt/apt.conf.d/docker-clean \
    && echo 'Binary::apt::APT::Keep-Downloaded-Packages "true";' > /etc/apt/apt.conf.d/keep-cache

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt/lists,sharing=locked \
    apt-get update \
    && apt-get install --no-install-recommends -y libgtk-3-0 libegl1

# Diff against the pristine base image's package list to find every package
# that installing libgtk-3-0/libegl1 pulled in (transitively), then copy only
# the files those packages actually own - not the whole apt-installed image.
RUN dpkg-query -W -f='${Package}\n' | sort > /all-packages.txt \
    && comm -13 /base-packages.txt /all-packages.txt > /new-packages.txt \
    && mkdir -p /rootfs-extra \
    && : > /file-list.txt \
    && while read -r pkg; do dpkg -L "$pkg" >> /file-list.raw; done < /new-packages.txt \
    && sort -u /file-list.raw > /file-list.sorted \
    && while read -r f; do if [ -f "$f" ]; then printf '%s\n' "$f"; fi; done < /file-list.sorted > /file-list.txt \
    && tar -cf - --files-from=/file-list.txt | tar -xf - -C /rootfs-extra

# ---- Final stage: SDK variant -------------------------------------------------
FROM scratch AS final-sdk

ENV \
    APP_UID=1654 \
    ASPNETCORE_HTTP_PORTS=8080 \
    DOTNET_RUNNING_IN_CONTAINER=true

COPY --from=chisel-sdk /rootfs/ /
COPY --from=apt-extra /rootfs-extra/ /
# Workaround for https://github.com/moby/moby/issues/38710
COPY --from=chisel-sdk --chown=1654:1654 /rootfs/home/app /home/app

# No `USER $APP_UID` here on purpose - see the note at the top of this file.

# ---- Final stage: runtime variant (default `docker build` target) ------------
FROM scratch AS final-runtime

ENV \
    APP_UID=1654 \
    ASPNETCORE_HTTP_PORTS=8080 \
    DOTNET_RUNNING_IN_CONTAINER=true

COPY --from=chisel-runtime /rootfs/ /
COPY --from=apt-extra /rootfs-extra/ /
# Workaround for https://github.com/moby/moby/issues/38710
COPY --from=chisel-runtime --chown=1654:1654 /rootfs/home/app /home/app

USER $APP_UID
