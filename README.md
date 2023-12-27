# Overview
This is a repository dedicated to running creating a development environment on an Ubuntu environment.

# Summary of installation
## Step 1: Prerequisites
- Ensure `xclip` is installed (this should be installed on a normal Ubuntu environment by default).
- Download a nerdfond (e.g Hack). [Click here](https://github.com/ryanoasis/nerd-fonts) to see the nerd fonts which are available to be installed.
- Download VScode and ensure that the extension `Dev Containers` is installed.
## Step 2: Docker
- Install: To install Docker via Docker Desktop run the script: `install-docker-desktop.sh`.
- Sign into Docker Desktop (Create an account if you have not already done that).
- Go to `Docker Desktop > Settings > Resources > File Sharing` and add `/tmp` to the list of folders which are allowed to be mounted. After that restart `Docker Desktop`.

# Summary of running docker
- To get help for the usage of the script, run the script `./manage-container -h`. This outputs a short summary of how to use the container.
- To build an image and run the container, run the script `./manage-container.sh -c`. This will automatically make a mounted file system on the host located in `~/Desktop/containers/test_Desktop` (as `test` is the default project name which can be changed by altering the `PROJECT_NAME` variable in the `manage-containers.sh` script).

    - After running this, on any vscode host window go to the command pallete (`ctrl+shift+p`) then type in the command `Dev Containers: Attach to running container` and then select the running container `test_container` (this is the default which can be changed by going into the `manage-containers.sh` script and changing the `PROJECT_NAME` variable).
    - This should open up a new window using the `Dev Containers` extension which connects to the running container.
    - Finally to load the necessary parts of the dev container, follow the `README.md` instructions of the container located in `~/README.md` inside the running container. 
- To delete the built image and delete the container, run the script `./manage-container.sh -d`. This will automatically delete the mounted file system on the host located in `~/Desktop/containers/test_Desktop` (as `test` is the default project name which can be changed by altering the `PROJECT_NAME` variable in the `manage-containers.sh` script).

# Working with VSCode
- Ensure that the following json object is in your `keybindings.json` vscode file:
```
{
    "key": "ctrl+p",
    "command": "-workbench.action.quickOpen"
}
```

# Summary of uninstall
To uninstall Docker run the uninstall script: `uninstall-docker-desktop.sh`.