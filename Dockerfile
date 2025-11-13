# Use a PyTorch base image from NVIDIA's NGC catalog
FROM nvcr.io/nvidia/pytorch:25.10-py3

# Set up the working directory
WORKDIR /app

# Set environment variables
ENV OMP_NUM_THREADS=1
ENV NANOCHAT_BASE_DIR="/root/.cache/nanochat"
ENV PATH="/root/.cargo/bin:/root/.astral/bin:${PATH}"

# Create the cache directory
RUN mkdir -p ${NANOCHAT_BASE_DIR}

# Install system dependencies, Rust, and uv
RUN apt-get update && apt-get install -y curl git && \
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y && \
    curl -LsSf https://astral.sh/uv/install.sh | sh && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

COPY pyproject.toml .
COPY README.md .
COPY rustbpe ./rustbpe

# Source cargo env and install Python dependencies using uv
RUN . "/root/.cargo/env" && \
    uv venv -p python3 .venv && \
    . .venv/bin/activate && \
    uv sync --extra gpu && \
    maturin develop --release --manifest-path rustbpe/Cargo.toml

# Copy the entire project into the container
COPY . .

# Make the script executable
RUN chmod +x speedrun.sh

# Set the default command to run the training script
CMD ["./speedrun.sh"]

