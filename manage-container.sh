#! /usr/bin/bash

OPTERR=0

IMAGE_NAME="test_image"
CONTAINER_NAME="test_container"
MAPPED_FOLDER_NAME="dev_folder_1"
HOST_PORT=2003
CONTAINER_PORT=2003

create() {
    # Create a file system in the containers folder which we build
    mkdir -p "${HOME}/Desktop/containers/${MAPPED_FOLDER_NAME}"
    # Build Docker image
    docker build -t "${IMAGE_NAME}" .
    # Run image as container
    docker run -d -it -p "${HOST_PORT}:${CONTAINER_PORT}" -e DISPLAY \
        -v /tmp/.X11-unix:/tmp/.X11-unix \
        -v "${HOME}/Desktop/containers/${MAPPED_FOLDER_NAME}:/home/testuser1/Desktop/${MAPPED_FOLDER_NAME}" \
        --name "${CONTAINER_NAME}" "${IMAGE_NAME}"
}

delete() {
    # Stop the container
    docker stop "${CONTAINER_NAME}"
    # Remove the container
    docker rm "${CONTAINER_NAME}"
    # Remove the image
    docker rmi "${IMAGE_NAME}"
}

#################### BEGIN SCRIPT ###################
getopts "cdh" option
case $option in
    c)
    create ;;

    d)
    delete ;;

    h)
    ports_in_use=$(ss -tulpn | awk '{print $5}' | awk 'NR > 1' | sed 's/.*://' | sort -un | tr '\n' ',' | sed 's/,$/\n/')
    cat <<EOF
When using this script remember:
- IMAGE_NAME: The name of the image to be built.
- CONTAINER_NAME: The name of the container that will be built.
- MAPPED_FOLDER_NAME: The name of the folder that will be created and mapped from the host to the container. Think of this as your persistent "dev" environment.
- HOST_PORT: The port that will be used from the host side. 
- CONTAINER_PORT: The port that will be used from the container side.

Host ports:
You can usually use any port in the range of 1024-65535
The ports which are currently in use are: ${ports_in_use}

Flags:
The available options are [-c|-d|-h] are:
    -c: Creating and running images and containers
    -d: Stopping and removing images and containers 
    -h: Getting help for the script
EOF
    ;;

    ?)
    cat << 'EOF'
Illegal option entered. The available options [-c|-d|-h] are:
    -c: Creating and running images and containers
    -d: Stopping and removing images and containers
    -h: Getting help for the script

In the script, we don't use getopts in a while loop, so only the first option will be recognized. That is:
    <script name> -cda : -c will be seen as the parameter
    <script name> -dca : -d will be seen as the parameter
    <script name> -acd : -a will be seen as the parameter
EOF
    ;;
esac