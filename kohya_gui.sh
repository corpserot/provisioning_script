#!/bin/bash
# This file will be sourced in init.sh
# Namespace functions with provisioning_

# Modified from
# https://github.com/ai-dock/kohya_ss/blob/aa3b4c7aa2bdb753894ae0f6d0f31d30228e9900/config/provisioning/default.sh

# Quick overrides:
# PROVISIONING_SCRIPT: https://raw.githubusercontent.com/corpserot/provisioning_script/main/kohya_gui.sh
# PROVISIONING_ANIMAGINE: 1
# PROVISIONING_PDXL: 1

### Edit the following arrays to suit your workflow - values must be quoted and separated by newlines or spaces.

DISK_GB_REQUIRED=30

PIP_PACKAGES=(
    #"package==version"
  )

CHECKPOINT_MODELS=(
    #"https://huggingface.co/runwayml/stable-diffusion-v1-5/resolve/main/v1-5-pruned-emaonly.ckpt"
    #"https://huggingface.co/stabilityai/stable-diffusion-2-1/resolve/main/v2-1_768-ema-pruned.ckpt"
    "https://huggingface.co/stabilityai/stable-diffusion-xl-base-1.0/resolve/main/sd_xl_base_1.0.safetensors"
    #"https://huggingface.co/stabilityai/stable-diffusion-xl-refiner-1.0/resolve/main/sd_xl_refiner_1.0.safetensors"
)
if [[ -n "$PROVISIONING_ANIMAGINE" ]]; then
    CHECKPOINT_MODELS+=(
        "https://civitai.com/api/download/models/293564"
    )
fi
if [[ -n "$PROVISIONING_PDXL" ]]; then
    CHECKPOINT_MODELS+=(
        "https://civitai.com/api/download/models/290640"
    )
fi


### DO NOT EDIT BELOW HERE UNLESS YOU KNOW WHAT YOU ARE DOING ###

function provisioning_start() {
    source /opt/ai-dock/etc/environment.sh
    source /opt/ai-dock/bin/venv-set.sh kohya

    sudo apt-get update
    sudo apt -y install -qq aria2
    "$WEBUI_VENV_PIP" install --no-cache-dir gdown
    #wget https://mega.nz/linux/repo/xUbuntu_24.04/amd64/megacmd-xUbuntu_24.04_amd64.deb && sudo apt install "$PWD/megacmd-xUbuntu_24.04_amd64.deb"
    #rm -rf "$PWD/megacmd-xUbuntu_24.04_amd64.deb"
    (
        mkdir -p /workspace/storage
        cd /workspace/storage
        git clone https://github.com/ltsdw/gofile-downloader.git
        cd gofile-downloader
        "$WEBUI_VENV_PIP" install --no-cache-dir -r requirements.txt
        sudo chmod a+x gofile-downloader.py
        sudo ln -s gofile-downloader.py /bin/gofile-dl
    )

    DISK_GB_AVAILABLE=$(($(df --output=avail -m "${WORKSPACE}" | tail -n1) / 1000))
    DISK_GB_USED=$(($(df --output=used -m "${WORKSPACE}" | tail -n1) / 1000))
    DISK_GB_ALLOCATED=$(($DISK_GB_AVAILABLE + $DISK_GB_USED))
    provisioning_print_header
    provisioning_get_mamba_packages
    provisioning_get_pip_packages
    provisioning_get_models \
        "${WORKSPACE}/storage/stable_diffusion/models/ckpt" \
        "${CHECKPOINT_MODELS[@]}"

    provisioning_download "https://raw.githubusercontent.com/corpserot/provisioning_script/main/upload.sh" "${WORKSPACE/storage/}"
    sudo chmod a+x "${WORKSPACE/storage/upload.sh}"
    provisioning_download "https://raw.githubusercontent.com/corpserot/provisioning_script/main/download.sh" "${WORKSPACE/storage/}"
    sudo chmod a+x "${WORKSPACE/storage/download.sh}"

    provisioning_print_end
}

function provisioning_get_pip_packages() {
    if [[ -n $PIP_PACKAGES ]]; then
        "$KOHYA_VENV_PIP" install --no-cache-dir ${PIP_PACKAGES[@]}
    fi
}

function provisioning_get_models() {
    if [[ -z $2 ]]; then return 1; fi
    dir="$1"
    mkdir -p "$dir"
    shift
    if [[ $DISK_GB_ALLOCATED -ge $DISK_GB_REQUIRED ]]; then
        arr=("$@")
    else
        printf "WARNING: Low disk space allocation - Only the first model will be downloaded!\n"
        arr=("$1")
    fi

    printf "Downloading %s model(s) to %s...\n" "${#arr[@]}" "$dir"
    for url in "${arr[@]}"; do
        printf "Downloading: %s\n" "${url}"
        provisioning_download "${url}" "${dir}"
        printf "\n"
    done
}

function provisioning_print_header() {
    printf "\n##############################################\n#                                            #\n#          Provisioning container            #\n#                                            #\n#         This will take some time           #\n#                                            #\n# Your container will be ready on completion #\n#                                            #\n##############################################\n\n"
    if [[ $DISK_GB_ALLOCATED -lt $DISK_GB_REQUIRED ]]; then
        printf "WARNING: Your allocated disk size (%sGB) is below the recommended %sGB - Some models will not be downloaded\n" "$DISK_GB_ALLOCATED" "$DISK_GB_REQUIRED"
    fi
}

function provisioning_print_end() {
    printf "\nProvisioning complete:  Web UI will start now\n\n"
}

# Download from $1 URL to $2 file path
function provisioning_download() {
    if [[ -n "PROVISIONING_WGET" ]]; then
        wget -qnc --content-disposition --show-progress -e dotbytes="${3:-4M}" -P "$2" "$1"
    else
        aria2c --console-log-level=error --optimize-concurrent-downloads -c -x 16 -s 16 -k 1M -d "$2" "$1"
    fi
}

provisioning_start
