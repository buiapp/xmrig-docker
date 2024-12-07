FROM ubuntu:22.04 AS base
RUN apt-get update && apt-get install -y \
    libuv1-dev \
    libssl-dev \
    libhwloc-dev

FROM base AS base-dev
RUN apt-get install -y \
    git \
    build-essential \
    cmake

FROM base-dev AS build-xmrig

RUN git clone https://github.com/xmrig/xmrig.git
RUN mkdir xmrig/build && cd xmrig/build && cmake .. && make -j$(nproc)

FROM base AS xmrig
COPY --from=build-xmrig /xmrig/build/ /xmrig
COPY config.json /xmrig
WORKDIR /xmrig
ENTRYPOINT [ "./xmrig" ]

FROM nvidia/cuda:12.1.1-devel-ubuntu22.04 AS cuda-base
RUN apt-get update && apt-get install -y \
    libuv1-dev \
    libssl-dev \
    libhwloc-dev

FROM cuda-base AS build-cuda-plugin
RUN apt-get update && apt-get install -y \
    git \
    build-essential \
    cmake

RUN git clone https://github.com/xmrig/xmrig-cuda.git
RUN mkdir xmrig-cuda/build && \
    cd xmrig-cuda/build && \
    cmake .. -DCUDA_LIB=/usr/local/cuda/lib64/stubs/libcuda.so -DCUDA_TOOLKIT_ROOT_DIR=/usr/local/cuda && \
    make -j$(nproc)

FROM cuda-base AS xmrig-cuda
RUN apt-get update && apt-get install -y \
    git \
    libuv1-dev \
    libssl-dev \
    libhwloc-dev

COPY --from=build-xmrig /xmrig/build /xmrig
COPY --from=build-cuda-plugin /xmrig-cuda/build/libxmrig-cuda.so /xmrig
COPY config.json /xmrig
WORKDIR /xmrig
ENTRYPOINT [ "./xmrig" ]