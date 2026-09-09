# ABCpdf Dockerfiles

This repo contains pipelines to build and push the most up-to-date images for our Docker Hub repositories.

These Docker images bundle the ABCpdf .NET library on top of Microsoft's official .NET runtime images, giving you a ready-to-run environment for PDF generation and manipulation.

The current images can be found at [Docker Hub ABCpdf repository](https://hub.docker.com/r/abcpdf/abcpdf).

The current Trivy security scan results can be found [here](https://abcpdf-team.github.io/ABCpdf-Dockerfiles/).

## Quick Start

For ABCpdf 14 you might use this.

```bash
docker pull abcpdf/abcpdf:14
```

Or in a Dockerfile

```dockerfile
FROM abcpdf/abcpdf:14 AS base
USER app
WORKDIR /app
EXPOSE 8080
```

## Performance Optimizations

See [Optimizing Containerization for High-Performance HTML Rendering with ABCpdf .NET](./Optimization.md) for
shared memory, ulimit, and CPU configuration guidance.

## Chiseled Image

The `abcpdf/abcpdf:14-chiseled` variant is built from `scratch` using Canonical's Chisel tool, which slices only the exact files needed by the ABCpdf .NET Core runtime and ABCChrome. The result is a significantly smaller image than the full runtime variant — no shell, no package manager, no unnecessary libraries. This minimal footprint makes it the recommended production image for environments where security, scan results, and deployment size matter.

### Customising the Chiseled Image

See [Chisel-customisation.md](./Chisel-customisation.md) for how to add fonts, libraries, and other packages to `abcpdf/abcpdf:14-chiseled` using the two-stage chisel-extra pattern.

## Advantages of Using the Current Images

- **Latest security patches** – Our weekly builds (every Tuesday morning UTC) include the most recent OS and library fixes, reducing exposure to known vulnerabilities.
- **Recent feature updates** – You get new Linux functionality and improvements as soon as they're available, without waiting for a manual release cycle.
- **Trivy-scanned by default** – Every container is automatically scanned for high-severity issues. Using the current image means you start from a known, audited state.
- **Predictable refresh cadence** – Updates happen on a fixed schedule, so you can plan your own testing and deployment around Tuesday mornings.

## Risks of Pulling from an Automated System

- **Unannounced breaking changes** – Even with scanning, an update may introduce behavioural or API changes that break your application if you haven't tested against the new image.
- **Limited manual testing** – Automated builds only include automated sanity checks. Rare edge-case regressions could reach users before they are noticed.
- **Unexpected dependency churn** – A security fix for one library might upgrade another dependency, altering performance or compatibility.
- **No version pinning by default** – If you always pull the latest, your environment can change without a code deploy.

### Supply Chain Considerations

Automated builds pull from multiple independent systems, each introducing supply chain risk:

- **Compromised base images or packages** – Upstream registries (Docker Hub etc) and third-party repos (apt, NuGet etc) could be hijacked, injecting vulnerabilities before our build runs.
- **Build pipeline tampering** – If our CI system's scripts or secrets are compromised, an attacker could alter the final image without changing our source code.
- **Trivy database poisoning or delay** – The scanner relies on external vulnerability feeds; a stale or corrupted database may miss real threats or flag false negatives.
- **Registry or mirror compromise** – The image you pull could be replaced by a malicious one if the registry or a cache mirror is breached, even if our build was clean.

### Recommendation

- **Use current images in development/staging** to catch issues early.
- **Monitor the weekly build results** (Trivy reports and any build logs) to stay aware of changes.
- **Mirror to your own registry** – Cache the image you test against and push it to a private registry (eg ECR, ACR, Artifactory). Deployments can then point to your mirrored copy, to be updated at times of your choosing.
- **Fork this repository and build your own images** – Consider forking the repo and generating images under your own registry. This eliminates reliance on our automated system while keeping the same foundation.

By combining the freshness of automated builds with careful promotion, pinning, and supply chain awareness, you get both security and stability.

### Pinning to a digest

>**N.B. Digest pinning turns off the benefit of our weekly rebuilds.**
>A pinned image will never pick up an OS or application security update, so a build that passes its vulnerability scan today will start failing as CVEs accumulate against it. Pin deliberately, and pair it with something that moves the pin for you — Renovate and Dependabot both raise pull requests for outdated digest references in Dockerfiles — or mirror tested images into your own registry and promote them on your own schedule.

A tag is a moving pointer. Because we rebuild weekly, `abcpdf/abcpdf:14` will resolve to a different image next Tuesday than it does today. If you need a byte-identical, reproducible build, pin to the image digest instead.

Find the digest of the image you have tested against:

```bash
# Without pulling the image
docker buildx imagetools inspect abcpdf/abcpdf:14

# Or, if you have already pulled it
docker inspect --format='{{index .RepoDigests 0}}' abcpdf/abcpdf:14
```

Then reference it with `@sha256:` in place of, or alongside, the tag:

```bash
docker pull abcpdf/abcpdf@sha256:<digest>
```

```dockerfile
FROM abcpdf/abcpdf:14@sha256:<digest> AS base
USER app
WORKDIR /app
EXPOSE 8080
```

Keeping the tag in front of the digest is good practice. Docker resolves the digest and ignores the tag, but the tag tells a human reader which major version they are looking at.
