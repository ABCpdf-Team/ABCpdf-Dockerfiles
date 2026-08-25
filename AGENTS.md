# AGENTS.md

Dockerfiles + CI for ABCpdf .NET runtime images published to Docker Hub. Each image bundles the ABCpdf PDF library and ABCChrome rendering engine for headless HTML→PDF on top of .NET runtime. A minimal console app (`TestApplication`) smoke-tests every image in CI by rendering `simple.html` → `output.pdf` (exit 0 = pass).

## Layout

| File | Purpose |
|---|---|
| `dockerfiles/abcpdf14.Dockerfile` | Current full image (MCR `aspnet:10.0-resolute`, Ubuntu 26.04, .NET 10) |
| `dockerfiles/abcpdf14-chiseled.Dockerfile` | Current chiseled image (`FROM scratch`, `chisel`, **no shell** in final stages) |
| `dockerfiles/deprecated/` | Legacy `mcr-aspnet-*` images (bookworm-slim, jammy, noble); still built/published |
| `TestApplication/` | Smoke-test app. `Program.cs` = license check → HTML→PDF → exit code; also includes `Dockerfile` for building/running against base images |
| `TestApplication/Directory.Build.props` | MSBuild config: sets `ABCPDF_VERSION` wildcard; conditionally refs `ABCpdf.ABCChrome146.Linux` when version = `14.*` |
| `scripts/run-tests.sh` | Local orchestrator — runs 6 images (4 deprecated + 2 current) |
| `scripts/build-and-test-distro.sh` | Build+test driver: `$1=dockerfile-path, $2=dotnet-major, $3=abcpdf-version(opt)`. Hardcoded RC prefix `abcpdf14-rc:` (local only; CI uses `abcpdf-rc-<name>`) |
| `scripts/build-base-image.sh` | Builds base image: `$1=dockerfile-path, $2=image-tag, $3=dotnet-version` |
| `scripts/run-test-app.sh` | Build+run test app: `$1=base-image-tag, $2=dotnet-major, $3=abcpdf-version` |
| `.github/workflows/build-test-publish-images.yml` | CI pipeline (10 matrix entries, see below) |
| `.github/trivy/html.tpl` | Trivy HTML template for GitHub Pages scan report |
| `.github/dependabot.yml` | Dependabot config |

## CI matrix (10 entries, per workflow)

| Matrix name | Dockerfile | .NET ver. | ABCpdf | Published tags |
|---|---|---|---|---|
| `bookworm-slim-6.0` | `deprecated/mcr-aspnet-bookworm-slim` | 6.0 | 13 | `abcpdf/mcr-aspnet:6.0-bookworm-slim` |
| `bookworm-slim-7.0` | `deprecated/mcr-aspnet-bookworm-slim` | 7.0 | 13 | `abcpdf/mcr-aspnet:7.0-bookworm-slim` |
| `bookworm-slim-8.0` | `deprecated/mcr-aspnet-bookworm-slim` | 8.0 | 13 | `abcpdf/mcr-aspnet:8.0-bookworm-slim` |
| `jammy-6.0` | `deprecated/mcr-aspnet-jammy` | 6.0 | 13 | `abcpdf/mcr-aspnet:6.0-jammy` |
| `jammy-7.0` | `deprecated/mcr-aspnet-jammy` | 7.0 | 13 | `abcpdf/mcr-aspnet:7.0-jammy` |
| `jammy-8.0` | `deprecated/mcr-aspnet-jammy` | 8.0 | 13 | `abcpdf/mcr-aspnet:8.0-jammy` |
| `noble-8.0` | `deprecated/mcr-aspnet-noble` | 8.0 | 13 | `abcpdf/mcr-aspnet:8.0-noble`, `:8.0` |
| `noble-10.0` | `deprecated/mcr-aspnet-noble` | 10.0 | 13 | `abcpdf/mcr-aspnet:10.0-noble`, `:10.0` |
| `abcpdf14` | `abcpdf14` | 10.0 | 14 | `abcpdf/abcpdf:14`, `abcpdf/mcr-aspnet:10.0-resolute` |
| `abcpdf14-chiseled` | `abcpdf14-chiseled` | 10.0 | 14 | `abcpdf/abcpdf:14-chiseled` |

## CI pipeline (per matrix entry)

1. **Build RC image:** `build-base-image.sh` → tag `abcpdf-rc-<matrix-name>`
2. **Test:** `run-test-app.sh` → build+run TestApplication against RC image
3. **Trivy scan:** report-only, HTML → GitHub Pages (if `RUN_PUBLISH_STEPS=true`)
4. **Publish:** tag + push Docker Hub (if `RUN_PUBLISH_STEPS=true`; gated on `main` push / schedule / manual dispatch)

**Naming:** RC = `abcpdf-rc-<name>`, test app = `abcpdf_test_app:<name>`, published = `abcpdf/mcr-aspnet:<ver>-<os>` (deprecated, bare `<ver>` = noble) or `abcpdf/abcpdf:14` / `:14-chiseled` (current).

## Conventions

- **Scripts:** bash, run on Windows via WSL/Git Bash. `.gitattributes` enforces LF (`* text=auto eol=lf`). **Keep it that way.**
- **Secrets:** local runs need `.secrets` (gitignored, create from `.secrets-example` with `ABCPDF_LICENSE_KEY`). CI uses GitHub secrets `ABCPDF14_LICENSE_KEY`, `DOCKER_HUB_USERNAME/PASSWORD`. **Never commit keys.**
- **Chiseled images:** no shell, no `RUN` in final stages; add packages via `chisel-wrapper`/`apt-extra` stages. App user = `app`/UID 1654 (MCR full images use UID 8163).
- **NuGet:** `ABCPDF_VERSION` passed as wildcard (`14.*`); `Directory.Build.props` uses it for both NuGet versions and the `ABCpdf.ABCChrome146.Linux` condition.

## Quick reference

```bash
# Local test (6 images — not the full CI matrix)
./scripts/run-tests.sh all
```

**Prefer CI for real verification:** push to branch triggers the full 10-entry matrix without publishing.


