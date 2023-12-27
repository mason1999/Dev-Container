# Overview
This is a repository dedicated to running creating a development environment on an Ubuntu environment.

# Summary of installation
## Step 1: Prerequisites
- Ensure `xclip` is installed (this should be installed on a normal Ubuntu environment by default)
- Download a nerdfond (e.g Hack). To find the available nerd-fonts
- Download VScode and ensure that `Dev Containers` is installed
## Step 2: Docker
- Install: To install Docker via Docker Desktop run the script: `install-docker-desktop.sh`.
- Sign into Docker Desktop (Create an account if you have not already done that).
- Go to `Docker Desktop > Settings > Resources > File Sharing` and add `/tmp` to the list of folders which are allowed to be mounted. After that restart `Docker Desktop`.

# Summary of running docker
- To get help for the usage of the script, run the script `./manage-container -h`. This outputs a short summary of how to use the container.
- To build an image and run the container, run the script `./manage-container.sh -c`.
- To delete the built image and delete the container, run the script `./manage-container.sh -d`.

# Summary of uninstall
To uninstall Docker run the uninstall script: `uninstall-docker-desktop.sh`.