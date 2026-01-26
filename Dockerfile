# ---------------------------------------------------------------------------- #
#                         Stage 1: Download the models                         #
# ---------------------------------------------------------------------------- #
FROM alpine/git:2.43.0 as download

# NOTE: CivitAI usually requires an API token, so you need to add it in the header
#       of the wget command if you're using a model from CivitAI.
RUN apk add --no-cache wget && \
    wget -q -O /model.safetensors \
    https://huggingface.co/webui/stable-diffusion-inpainting/resolve/main/sd-v1-5-inpainting.safetensors && \
    wget -q -O /cyberrealictic.safetensors \
    https://civitai.com/api/download/models/1478064?token=16f594f820ca3086e72e070165deebbd && \
    wget -q -O /Rawfully_Stylish_v0-2.safetensors \
    https://civitai.com/api/download/models/466475?token=16f594f820ca3086e72e070165deebbd && \
    wget -q -O /igbaddie-PN.safetensors \
    https://civitai.com/api/download/models/556208?token=16f594f820ca3086e72e070165deebbd && \
    wget -q -O /AmateurStyle_v1_PONY_REALISM.safetensors \
    https://civitai.com/api/download/models/534756?token=16f594f820ca3086e72e070165deebbd && \
    wget -q -O /CyberRealistic_Negative_PONY-neg.safetensors \
    https://civitai.com/api/download/models/1690589?token=16f594f820ca3086e72e070165deebbd && \
    wget -q -O /sdxl_vae.safetensors \
    https://huggingface.co/stabilityai/sdxl-vae/resolve/main/sdxl_vae.safetensors 


# ---------------------------------------------------------------------------- #
#                        Stage 2: Build the final image                        #
# ---------------------------------------------------------------------------- #
FROM python:3.10.14-slim as build_final_image

ARG A1111_RELEASE=v1.9.3

ENV DEBIAN_FRONTEND=noninteractive \
    PIP_PREFER_BINARY=1 \
    ROOT=/stable-diffusion-webui \
    PYTHONUNBUFFERED=1

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN apt-get update && \
    apt install -y \
    fonts-dejavu-core rsync git jq moreutils aria2 wget libgoogle-perftools-dev libtcmalloc-minimal4 procps libgl1 libglib2.0-0 && \
    apt-get autoremove -y && rm -rf /var/lib/apt/lists/* && apt-get clean -y

ENV STABLE_DIFFUSION_REPO=https://github.com/w-e-w/stablediffusion.git


RUN --mount=type=cache,target=/root/.cache/pip \
    git clone https://github.com/AUTOMATIC1111/stable-diffusion-webui && \
    cd stable-diffusion-webui && \
    git reset --hard ${A1111_RELEASE} && \
    pip install xformers && \
    pip install -r requirements_versions.txt && \
    python -c "from launch import prepare_environment; prepare_environment()" --skip-torch-cuda-test

COPY --from=download /model.safetensors /model.safetensors
COPY --from=download /cyberrealictic.safetensors /cyberrealictic.safetensors
COPY --from=download /Rawfully_Stylish_v0-2.safetensors /stable-diffusion-webui/models/Lora/Rawfully_Stylish_v0-2.safetensors
COPY --from=download /igbaddie-PN.safetensors /stable-diffusion-webui/models/Lora/igbaddie-PN.safetensors
COPY --from=download /AmateurStyle_v1_PONY_REALISM.safetensors /stable-diffusion-webui/models/Lora/AmateurStyle_v1_PONY_REALISM.safetensors
COPY --from=download /CyberRealistic_Negative_PONY-neg.safetensors /stable-diffusion-webui/embeddings/CyberRealistic_Negative_PONY-neg.safetensors
COPY --from=download /sdxl_vae.safetensors /stable-diffusion-webui/models/VAE/sdxl_vae.safetensors

# install dependencies
COPY requirements.txt .
RUN --mount=type=cache,target=/root/.cache/pip \
    pip install --no-cache-dir -r requirements.txt

COPY test_input.json .

ADD src .

RUN chmod +x /start.sh
CMD /start.sh
