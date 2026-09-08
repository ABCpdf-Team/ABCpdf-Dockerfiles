# Optimizing Containerization for High-Performance HTML Rendering with ABCpdf.NET

## Introduction

ABCpdf.NET uses the **ABCChrome146 HTML rendering engine** for HTML conversion.

Inside containerised environments (Docker, Podman, or WSL2), achieving reliable, high-speed performance requires specific runtime configuration.

Indeed for other complex PDF conversion operations using ABCpdf.NET you may find these principles to be similarly relevant.

ABCChrome146 is built on **Chromium 146** - a modern, resource-intensive, multi-process browser engine. Correctly configuring your container runtime ensures:

- **Consistent, predictable page load times**
- **Zero timeouts**, even under concurrent load
- **Stable production deployments** without intermittent failures

This definitive guide covers the essential Docker settings for production-grade ABCChrome146 deployments. It is the canonical source for details of Docker settings for HTML conversion using ABCpdf.NET.

## Critical Configuration: Shared Memory (`/dev/shm`)

### Why Shared Memory Matters

Chromium 146's multi-process architecture uses **POSIX shared memory** (mounted at `/dev/shm` on Linux) for high-speed inter-process communication (IPC). This is where the GPU process, renderer processes, and main browser process exchange:

- Rendered pixel buffers
- JavaScript heap snapshots
- GPU textures and compositing frames
- Fast IPC messages

### The Default Limitation

Most container runtimes (Docker, Podman, WSL2) mount `/dev/shm` with a **default size of just 64 MB**. This conservative default was chosen for lightweight microservices, not for browser engines like Chromium 146.

ABCChrome146 typically requires **150–200 MB** of shared memory to operate reliably under load. When the limit is reached, allocation fails — often manifesting as timeouts rather than explicit errors.

### Typical Limit Related Errors

If you do not adjust the limits you may experience one or more of the following:

- "Unable to render HTML. ABCChrome page load timed out." exceptions
- Exceptions containing messages such as `ERR_INSUFFICIENT_RESOURCES (-12)`
- Generally poor HTML rendering performance

Failures may be intermittent: the same document may convert successfully on one attempt and fail on the next. Failure rates typically increase as the number of concurrent conversions increases.

### The Solution: Increase `/dev/shm` Size

Set the shared memory size at container startup using the `--shm-size` flag.

This cannot be set in a Dockerfile. `/dev/shm` is mounted at run time, so the setting must be applied to the run command.

**Docker / Podman / WSL2 run command:**

```bash
docker run --shm-size=1G your-image
podman run --shm-size=1G your-image
wsl run --shm-size=1G your-image
```

**Docker Compose / Podman Compose:**

```yaml
services:
  your-pdf-service:
    image: your-image
    shm_size: 1gb
```

### How Much Is Enough?

ABCChrome146 typically requires **150–200 MB** of shared memory. A setting of **1 GB** provides a generous buffer that comfortably accommodates this requirement.

> **Important:** `tmpfs` (shared memory) is allocated lazily — it only consumes host RAM as it is used. Setting a generous limit costs nothing until the space is actually needed, so **err on the side of over-provisioning**.

### Verification

To confirm the setting has taken effect inside a running container:

```bash
docker exec -it <container-id> df -h /dev/shm
```

Expected output: `1.0G`, `2.0G`, etc. If it shows `64M`, the setting was not applied correctly.

---

## Additional Optimizations for Demanding Environments

Beyond shared memory, the following advanced settings can further improve stability and throughput for high-performance PDF processing.

> **Important:** We have not found these additional settings to be *required* for stable operation of ABCChrome146. They are offered here as optional tuning parameters worth evaluating if you are running particularly demanding or mission-critical workloads.

### 1. Increase File Descriptor Limits (`--ulimit nofile`)

The Chromium process model opens numerous IPC sockets, event file descriptors, and network connections. Under high concurrency, the default Docker limit of 1024 might be exhausted.

```bash
docker run --shm-size=1g --ulimit nofile=65536:65536 your-image
```

### 2. Increase Process Limits (`--ulimit nproc`)

Each Chromium instance spawns multiple child processes (GPU, renderer, network, utility). Running many concurrent conversions might hit the default process limit.

```bash
docker run --shm-size=1g --ulimit nproc=8192:8192 your-image
```

### 3. CPU Allocation (`--cpus`)

For predictable performance and to prevent the container from consuming excessive host CPU resources:

```bash
docker run --shm-size=1g --cpus=6 your-image
```

### 4. Additional Considerations

Depending on your specific workload characteristics, you may also wish to consider:

- **Memory limits** (`--memory`): Setting an upper bound on container memory usage can prevent resource contention with other services.
- **Memory reservation** (`--memory-reservation`): A soft limit that allows the container to use more memory when available but reclaims it under pressure.
- **CPU pinning** (`--cpuset-cpus`): Binding the container to specific CPU cores can improve cache locality and reduce context-switching overhead.

---

## Common Pitfalls to Avoid

| Pitfall | Why It Matters |
| :------ | :------------- |
| Setting `shm_size` in Dockerfile | Doesn't work—`/dev/shm` is a runtime mount, not a build-time filesystem. |
| Using 64 MB default in production | Guarantees intermittent timeouts under load. |
| Ignoring host kernel limits | Host-level `kernel.shmmax` may constrain shared memory; check with `sysctl kernel.shmmax`. |

---

## Further Reading

- [Docker Runtime Constraints Documentation](https://docs.docker.com/engine/containers/resource_constraints/)
- [Chromium Multi-Process Architecture](https://www.chromium.org/developers/design-documents/multi-process-architecture/)
- [POSIX Shared Memory Overview](https://man7.org/linux/man-pages/man7/shm_overview.7.html)

---

*Last updated: August 2026*
