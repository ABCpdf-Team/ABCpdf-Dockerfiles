# docker build . --file mcr-aspnet-8.0-jammy.Dockerfile -t abcpdf/dotnet-aspnet:8.0-jammy
FROM mcr.microsoft.com/dotnet/aspnet:8.0-jammy
RUN apt-get update && apt-get install -y \
    ca-certificates \
    libasound2 \
    libatk1.0-0 \
    libatk-bridge2.0-0 \
    libatspi2.0-0 \
    libavahi-client3 \
    libavahi-common3 \
    libbrotli1 \
    libbsd0 \
    libcairo2 \
    libcups2 \
    libdatrie1 \
    libdbus-1-3 \
    libdrm2 \
    libfontconfig1 \
    libfreetype6 \
    libfribidi0 \
    libgbm1 \
    libglib2.0-0 \
    libgraphite2-3 \
    libharfbuzz0b \
    libicu70 \
    libmd0 \
    libnspr4 \
    libnss3 \
    libpango-1.0-0 \
    libpixman-1-0 \
    libpng16-16 \
    libthai0 \
    libwayland-server0 \
    libx11-6 \
    libxau6 \
    libxcb1 \
    libxcb-render0 \
    libxcb-shm0 \
    libxcomposite1 \
    libxdamage1 \
    libxdmcp6 \
    libxext6 \
    libxfixes3 \
    libxi6 \
    libxkbcommon0 \
    libxrandr2 \
    libxrender1 \
    libegl1 \
# Install a reasonable set of fonts
    fonts-noto-core \
    fonts-noto-mono \
    fonts-noto-color-emoji \
    && fc-cache -f -v
