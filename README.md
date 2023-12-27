# Overview
This is a repository dedicated to running creating a development environment on an Ubuntu environment.

# Summary of installation
## Step 1: Prerequisites
- Ensure `xclip` is installed (this should be installed on a normal Ubuntu environment by default).
- Download a nerdfond (e.g Hack). [Click here](https://github.com/ryanoasis/nerd-fonts) to see the nerd fonts which are available to be installed.

    - For example after you download the Hack Nerd Font Mono, put this in your VSCode `settings.json` file on your host machine:

    ```
     "editor.fontFamily": "Hack Nerd Font Mono"
    ```
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
- Here is a minimalist config available for your `settings.json` vscode file. Only the vim extension was being used here:
```
{
    // --------------------- Have no welcome screen or minimap on startup ---------------------
    "workbench.startupEditor": "none",
    "editor.minimap.autohide": true,

    /**************************************** Vim Extension ****************************************/

    // -------------------- Remove the ctrl+n key from vim because it conflicts with nerdtree and ctrl+k because it conflicts with folding--------------------
    "vim.handleKeys": {
        "<C-n>": false,
        "<C-k>": false
    },
    // -------------------- Use system keyboard --------------------
    "vim.useSystemClipboard": true,

    // -------------------- TESTING --------------------
    "editor.fontFamily": "Hack Nerd Font Mono",
    "vim.foldfix": true
}
```
- Here is a minimalist config available for your `keybindings.json` vscode file:
```
// Place your key bindings in this file to override the defaults
[
    // -------------------- Close current Editor Window --------------------
    {
        "key": "ctrl+w",
        "command": "workbench.action.closeActiveEditor"
    },
    {
        "key": "ctrl+p",
        "command": "-workbench.action.quickOpen"
    },
    // -------------------- VScode Intellisense  --------------------
    {
        "key": "ctrl+j",
        "command": "selectNextSuggestion",
        "when": "suggestWidgetMultipleSuggestions && suggestWidgetVisible && textInputFocus"
    },
    {
        "key": "ctrl+k",
        "command": "selectPrevSuggestion",
        "when": "suggestWidgetMultipleSuggestions && suggestWidgetVisible && textInputFocus"
    },
    // -------------------- VScode Command Pallete  --------------------
    {
        "key": "ctrl+j",
        "command": "workbench.action.quickOpenNavigateNext",
        "when": "!editorTextFocus"
    },
    {
        "key": "ctrl+k",
        "command": "workbench.action.quickOpenNavigatePrevious",
        "when": "!editorTextFocus"
    },
    // -------------------- Toggle terminal --------------------
    {
        "key": "ctrl+t",
        "command": "workbench.action.terminal.toggleTerminal"
    },
    // -------------------- Navigate Tabs in editors and previews/extensions  --------------------
    {
        "key": "ctrl+]",
        "command": "workbench.action.nextEditorInGroup",
        "when": "!terminalFocus"
    },
    {
        "key": "ctrl+[",
        "command": "workbench.action.previousEditorInGroup",
        "when": "!terminalFocus"
    },
    // -------------------- Navigate between splits in editor (and to terminal) in vscode vim-like  --------------------
    {
        "key": "ctrl+shift+h",
        "command": "workbench.action.navigateLeft",
        "when": "editorTextFocus && vim.mode == 'Normal'"
    },
    {
        "key": "ctrl+shift+j",
        "command": "workbench.action.navigateDown",
        "when": "editorTextFocus && vim.mode == 'Normal'"
    },
    {
        "key": "ctrl+shift+k",
        "command": "workbench.action.navigateUp",
        "when": "editorTextFocus && vim.mode == 'Normal'"
    },
    {
        "key": "ctrl+shift+l",
        "command": "workbench.action.navigateRight",
        "when": "editorTextFocus && vim.mode == 'Normal'"
    },
    // -------------------- Navigate panes in the terminal and to an editor (terminal at bottom)  --------------------
    {
        "key": "ctrl+shift+n",
        "command": "workbench.action.terminal.split",
        "when": "terminalFocus && terminalProcessSupported || terminalFocus && terminalWebExtensionContributedProfile"
    },
    // -------------------- Navigate panes in the terminal and to an editor (terminal at bottom)  --------------------
    {
        "key": "ctrl+shift+h",
        "command": "workbench.action.terminal.focusPreviousPane",
        "when": "panelPosition == 'bottom' && (terminalFocus && terminalProcessSupported || terminalFocus && terminalWebExtensionContributedProfile)"
    },
    {
        "key": "ctrl+shift+l",
        "command": "workbench.action.terminal.focusNextPane",
        "when": "panelPosition == 'bottom' && (terminalFocus && terminalProcessSupported || terminalFocus && terminalWebExtensionContributedProfile)"
    },
    {
        "key": "ctrl+shift+k",
        "command": "workbench.action.navigateUp",
        "when": "panelPosition == 'bottom' && (terminalFocus && terminalProcessSupported || terminalFocus && terminalWebExtensionContributedProfile)"
    },
    // -------------------- Navigate panes in the terminal and to an editor (terminal at right)  --------------------
    {
        "key": "ctrl+shift+k",
        "command": "workbench.action.terminal.focusPreviousPane",
        "when": "panelPosition == 'right' && (terminalFocus && terminalProcessSupported || terminalFocus && terminalWebExtensionContributedProfile)"
    },
    {
        "key": "ctrl+shift+j",
        "command": "workbench.action.terminal.focusNextPane",
        "when": "panelPosition == 'right' && (terminalFocus && terminalProcessSupported || terminalFocus && terminalWebExtensionContributedProfile)"
    },
    {
        "key": "ctrl+shift+k",
        "command": "workbench.action.navigateLeft",
        "when": "panelPosition == 'right' && (terminalFocus && terminalProcessSupported || terminalFocus && terminalWebExtensionContributedProfile)"
    },
    // -------------------- Create, Rename and Navigate different terminal sessions  --------------------
    {
        "key": "ctrl+shift+,",
        "command": "workbench.action.terminal.rename",
        "when": "terminalFocus"
    },
    {
        "key": "ctrl+shift+t",
        "command": "workbench.action.terminal.new",
        "when": "terminalProcessSupported || terminalWebExtensionContributedProfile"
    },
    {
        "key": "ctrl+shift+[",
        "command": "workbench.action.terminal.focusPrevious",
        "when": "terminalFocus && terminalHasBeenCreated && !terminalEditorFocus || terminalFocus && terminalProcessSupported && !terminalEditorFocus"
    },
    {
        "key": "ctrl+shift+]",
        "command": "workbench.action.terminal.focusNext",
        "when": "terminalFocus && terminalHasBeenCreated && !terminalEditorFocus || terminalFocus && terminalProcessSupported && !terminalEditorFocus"
    },
    // -------------------- Change copy and paste keybinds for terminal --------------------
    // Remove defaults
    {
        "key": "ctrl+v",
        "command": "-workbench.action.terminal.paste",
        "when": "terminalFocus && terminalHasBeenCreated || terminalFocus && terminalProcessSupported"
    },
    {
        "key": "ctrl+c",
        "command": "-workbench.action.terminal.copyAndClearSelection",
        "when": "terminalFocus && terminalHasBeenCreated && terminalTextSelected || terminalFocus && terminalProcessSupported && terminalTextSelected"
    },
    // Replace defaults
    {
        "key": "ctrl+shift+v",
        "command": "workbench.action.terminal.paste",
        "when": "terminalFocus && terminalHasBeenCreated || terminalFocus && terminalProcessSupported"
    },
    {
        "key": "ctrl+shift+c",
        "command": "workbench.action.terminal.copyAndClearSelection",
        "when": "terminalFocus && terminalHasBeenCreated && terminalTextSelected || terminalFocus && terminalProcessSupported && terminalTextSelected"
    },
]
```

# Summary of uninstall
To uninstall Docker run the uninstall script: `uninstall-docker-desktop.sh`.