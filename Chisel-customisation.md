# Customising the abcpdf:14-chiseled Image

`abcpdf/abcpdf:14-chiseled` is built `FROM scratch` with no shell, so `RUN` doesn't work in it. `COPY` does. Prepare additions in an `ubuntu:resolute` build stage, then copy them in.

Build stages must use `ubuntu:resolute` (26.04) to match the runtime's glibc and ICU.

---

## Adding Fonts

The base image already creates `/usr/local/share/fonts`. Rebuild the fontconfig cache too — without it fonts are still found, but every process start rescans them.

```dockerfile
# syntax=docker/dockerfile:1

FROM ubuntu:resolute AS fonts
ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update \
    && apt-get install --no-install-recommends -y fontconfig \
    && rm -rf /var/lib/apt/lists/*
COPY fonts/ /usr/local/share/fonts/
RUN fc-cache -f

FROM abcpdf/abcpdf:14-chiseled
COPY --from=fonts /usr/local/share/fonts /usr/local/share/fonts
COPY --from=fonts /var/cache/fontconfig /var/cache/fontconfig
USER $APP_UID
WORKDIR /app
```

*Notes:*

- `COPY fonts/` not `COPY fonts/*.ttf` — a glob matching nothing is a build error.
- For a distribution font package (`fonts-noto-cjk`), copy `/usr/share/fonts` instead.
- Cache files are format-versioned; a fontconfig version mismatch means the cache is silently ignored.

---

## Adding Libraries Using the Apt-Extra Diff Approach

Works for any package, slice or no slice. Example: `libgssapi-krb5-2`, needed by .NET's `HttpClient` for Kerberos/Negotiate auth when rendering from an authenticated intranet server.

```dockerfile
FROM ubuntu:resolute AS apt-extra
ARG DEBIAN_FRONTEND=noninteractive

RUN dpkg-query -W -f='${Package}\n' | sort > /base-packages.txt

RUN apt-get update \
    && apt-get install --no-install-recommends -y libgssapi-krb5-2

RUN dpkg-query -W -f='${Package}\n' | sort > /all-packages.txt \
    && comm -13 /base-packages.txt /all-packages.txt > /new-packages.txt \
    && mkdir -p /rootfs-extra \
    && : > /file-list.raw \
    && while read -r pkg; do dpkg -L "$pkg" >> /file-list.raw; done < /new-packages.txt \
    && sort -u /file-list.raw > /file-list.sorted \
    && while read -r f; do if [ -f "$f" ]; then printf '%s\n' "$f"; fi; done \
        < /file-list.sorted > /file-list.txt \
    && tar -cf - --no-recursion --files-from=/file-list.txt | tar -xf - -C /rootfs-extra

FROM abcpdf/abcpdf:14-chiseled
COPY --from=apt-extra /rootfs-extra/ /
USER $APP_UID
WORKDIR /app
```

*Notes:*
- **The `[ -f ]` filter is required.** `dpkg -L` lists directories; tar recurses into them and archives the whole build stage. Use `if/then/fi`, not `[ -f "$f" ] && ...` — with `&&`, a failing final entry makes the `RUN` fail.
- **The diff is the safety property.** `comm -13` yields only packages not already in `ubuntu:resolute`, so shared libraries like `libc6` can never overwrite the base image's copies.

## Adding Libraries That Have Defined Slices

Use when a slice exists and you want sub-package granularity. Same chisel setup as the base image's `chisel-common` stage, then:

```dockerfile
RUN mkdir -p /rootfs/var/lib/dpkg \
    && chisel-wrapper --generate-dpkg-status /rootfs/var/lib/dpkg/status -- \
        --release ubuntu-26.04 --ignore=unstable --root /rootfs \
            <slice-name>_libs

FROM abcpdf/abcpdf:14-chiseled
COPY --from=chisel-extra /rootfs/usr/lib /usr/lib
```

*Notes:*

- **Verify slice names** against the [ubuntu-26.04 branch](https://github.com/canonical/chisel-releases/tree/ubuntu-26.04/slices) or `chisel find --release ubuntu-26.04 'libxml2*'`.
- **Copy subtrees, not `/rootfs/` to `/`.** Chisel's generated `var/lib/dpkg/status` lists only its own slices. Overwrite the base one and scanners report an inventory of just your additions — a wrong SBOM that looks clean. `apt-extra` doesn't have this problem.
- Adding `bash_bins`/coreutils slices so downstream Dockerfiles can `RUN` makes the image no longer shell-free. That's usually the reason people picked chiseled.

## Gotchas

- **No `RUN` in the final stage.** Shell-free by design.
- **Copying onto `/` can overwrite base libraries.** A different glibc/ICU/OpenSSL build breaks the runtime at run time, not build time. `apt-extra` avoids this; chisel doesn't.
- **No package manager, so no in-place patching.** Pin versions and rebuild on a schedule.
- **Copied files are root-owned.** Readable by `$APP_UID` (1654), which covers fonts and libraries. Anything the app writes needs `COPY --chown=1654:1654`.
- **Directory modes aren't preserved** when extracting a file-only tar list.

Reference: [`abcpdf14-chiseled.Dockerfile`](https://github.com/ABCpdf-Team/ABCpdf-Dockerfiles/blob/main/dockerfiles/abcpdf14-chiseled.Dockerfile).