FROM ghcr.io/blinklabs-io/haskell:9.6.4-3.10.2.0-1 AS cardano-wallet-build
# Install cardano-wallet
ARG WALLET_VERSION=2024.7.7
ENV WALLET_VERSION=${WALLET_VERSION}
ARG WALLET_REF=tags/v2024-07-07
ENV WALLET_REF=${WALLET_REF}
RUN echo "Building ${WALLET_REF}..." \
    && echo ${WALLET_REF} > /CARDANO_BRANCH \
    && git clone https://github.com/cardano-foundation/cardano-wallet.git \
    && cd cardano-wallet \
    && git fetch --all --recurse-submodules --tags \
    && git tag \
    && git checkout ${WALLET_REF} \
    && cabal configure --with-compiler=ghc-${GHC_VERSION} --disable-tests --disable-benchmarks \
    && cabal update \
    && cabal build all -frelease \
    && mkdir -p /root/.local/bin/ \
    && cp -a dist-newstyle/build/$(uname -m)-linux/ghc-${GHC_VERSION}/cardano-wallet-api-${WALLET_VERSION}/x/cardano-wallet/build/cardano-wallet/cardano-wallet /root/.local/bin/ \
    && rm -rf /root/.cabal/packages \
    && rm -rf /usr/local/lib/ghc-${GHC_VERSION}/ /usr/local/share/doc/ghc-${GHC_VERSION}/ \
    && rm -rf /code/cardano-wallet/dist-newstyle/ \
    && rm -rf /root/.cabal/store/ghc-${GHC_VERSION}

FROM ghcr.io/blinklabs-io/cardano-configs:20240515-2 AS cardano-configs

FROM debian:bookworm-slim AS cardano-wallet
ENV LD_LIBRARY_PATH="/usr/local/lib:$LD_LIBRARY_PATH"
ENV PKG_CONFIG_PATH="/usr/local/lib/pkgconfig:$PKG_CONFIG_PATH"
COPY --from=cardano-wallet-build /usr/local/lib/ /usr/local/lib/
COPY --from=cardano-wallet-build /usr/local/include/ /usr/local/include/
COPY --from=cardano-wallet-build /root/.local/bin/cardano-* /usr/local/bin/
COPY --from=cardano-configs /config/ /opt/cardano/config/
RUN apt-get update -y && \
  apt-get install -y \
    bc \
    curl \
    iproute2 \
    jq \
    libgmp10 \
    libncursesw5 \
    libnuma1 \
    libssl3 \
    libtinfo6 \
    llvm-14-runtime \
    netbase \
    pkg-config \
    procps \
    wget \
    zlib1g && \
  rm -rf /var/lib/apt/lists/* && \
  chmod +x /usr/local/bin/*
EXPOSE 8090
ENTRYPOINT ["/usr/local/bin/cardano-wallet"]
