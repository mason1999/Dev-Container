FROM ubuntu:22.04
WORKDIR /
SHELL ["usr/bin/bash", "-c"]

######################################## Dependencies installation ########################################
RUN apt-get update --fix-missing
RUN apt-get update
RUN yes | unminimize -y \
    man \
    manpages-posix

RUN apt-get install -y curl
RUN apt-get install -y git
RUN apt-get install -y zsh
RUN apt-get install -y tmux
RUN apt-get install -y file
RUN apt-get install -y iproute2
RUN apt-get install -y xclip # For nvim to work
RUN apt-get install -y unzip jq # For ohmyposh
RUN curl -sL https://aka.ms/InstallAzureCLIDeb | bash # For AZ CLI

# For gh cli and it's dependencies
RUN type -p curl >/dev/null || (apt update && apt install curl -y) && \
    curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg && \
    chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | tee /etc/apt/sources.list.d/github-cli.list > /dev/null && \
    apt update && \
    apt install gh -y

# For PowerShell and it's dependencies
RUN apt-get install -y wget apt-transport-https software-properties-common && \
    source /etc/os-release && \
    wget -q https://packages.microsoft.com/config/ubuntu/$VERSION_ID/packages-microsoft-prod.deb && \
    dpkg -i packages-microsoft-prod.deb && \
    rm packages-microsoft-prod.deb && \
    apt-get update && \
    apt-get install -y powershell

# Install Azure Powershell
SHELL ["/usr/bin/pwsh", "-command"]
RUN Install-Module -Name Az -Repository PSGallery -Scope AllUsers -Force

# Rever shell back to bash
SHELL ["/usr/bin/bash", "-c"]

# Install Terraform and it's dependencies
RUN apt-get install -y gnupg software-properties-common && \
    wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor | tee /usr/share/keyrings/hashicorp-archive-keyring.gpg && \
    gpg --no-default-keyring --keyring /usr/share/keyrings/hashicorp-archive-keyring.gpg --fingerprint && \
    echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/hashicorp.list && \
    apt-get update && \
    apt-get install terraform

######################################## Create another user ########################################
RUN apt-get install sudo
RUN useradd testuser1 --create-home --groups sudo --shell /usr/bin/zsh && printf "WeakPassword\nWeakPassword" | passwd testuser1

######################################## Configure zsh ########################################
RUN curl -s https://ohmyposh.dev/install.sh | bash -s -- -d /usr/local/bin
USER testuser1
WORKDIR /home/testuser1

# Create the default configuration (blue-owl)
RUN mkdir -p "${HOME}/oh-my-posh-themes"
RUN curl -L -o "${HOME}/oh-my-posh-themes/blue-owl.json" "https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/blue-owl.omp.json"

# modify the json file to include more leading space between the output of the prompt and the start of the next prompt
RUN space_block=$(echo '{ "alignment": "left", "newline": true, "segments": [ { "foreground": "#ffffff", "foreground_templates": [ "{{ if gt .Code 0 }}#ff0000{{ end }}" ], "properties": { "always_enabled": true }, "style": "plain", "template": "\u0000 ", "type": "status" } ], "type": "prompt" }' | jq '.') && \
    cat "${HOME}/oh-my-posh-themes/blue-owl.json" | jq --argjson obj "${space_block}" '.blocks = [$obj] + .blocks' > temp.json && cat temp.json > "${HOME}/oh-my-posh-themes/blue-owl.json" && rm temp.json

# Configure ~/.zshrc to the default configuration (blue-owl)
RUN cat <<'EOF' > "${HOME}/.zshrc"
theme_name="blue-owl"
EOF

RUN cat <<'EOF' >> "${HOME}/.zshrc"
eval "$(oh-my-posh init zsh --config ${HOME}/oh-my-posh-themes/${theme_name}.json)"

EOF

RUN cat <<'EOF' >> "${HOME}/.zshrc"
if [[ ! -e "${HOME}/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]]; then
    git clone "https://github.com/zsh-users/zsh-syntax-highlighting.git" "${HOME}/zsh-syntax-highlighting"
fi
source "${HOME}/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"

# Aliases
alias ls='ls --color=auto'
alias man='2>/dev/null man'

# Manpager
export MANPAGER="nvim +Man! -"

# Flags
flag_set_foreground_color="38"
flag_set_background_color="38"
flag_set_bold="1"

# Colors
black="0"
white="15"
sky_blue_1="117"
dodger_blue_1="33"
sky_blue_3="74"
spring_green_2="42"
yellow_1="226"

# Tab highlight colors: Colors found at https://www.ditig.com/256-colors-cheat-sheet. The 5 is to use extended xterm color pallete
highlight_preview_colors="ma=${flag_set_foreground_color};5;${black};${flag_set_background_color};5;${sky_blue_1}"

# Tab completion colors
directory_color="di=${flag_set_bold};${flag_set_foreground_color};5;${dodger_blue_1}"
symbolic_link_color="ln=${flag_set_bold};${flag_set_foreground_color};5;${sky_blue_3}"
executable_color="ex=${flag_set_bold};${flag_set_foreground_color};5;${spring_green_2}"
socket_color="so=${flag_set_bold};${flag_set_foreground_color};5;${yellow_1}"
regular_file_color="fi=" # No modifications

# Set Tab completion highlight and colors
zstyle ":completion:*:default" list-colors ${(s.:.)LS_COLORS} "${highlight_preview_colors}:${directory_color}:${symbolic_link_color}:${executable_color}:${regular_file_color}"
zstyle ':completion:*' menu select

# Set LS colors
export LS_COLORS="${directory_color}:${symbolic_link_color}:${executable_color}:${regular_file_color}"

# Enable shift tab to go backwards in highlight searching
zmodload zsh/complist
bindkey -M menuselect '^[[Z' reverse-menu-complete

# Enable auto completion of commands from history with up and down arrow keys (if text is already entered)
autoload -U history-search-end
zle -N history-beginning-search-backward-end history-search-end
zle -N history-beginning-search-forward-end history-search-end
bindkey "^[OA" history-beginning-search-backward-end
bindkey "^[OB" history-beginning-search-forward-end

EOF

RUN exec zsh

# Create a script which helps change the appearance
RUN cat <<'EOF' > ${HOME}/change_oh_my_posh_appearance_zsh.sh
#! /usr/bin/bash

# Exit on error
set -e

# ANSI color codes for some helpful coloured output
BLACK='\033[0;30m'
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
RESET='\033[0m' # Reset color to default

# Create a directory if it does not already exist
mkdir -p "${HOME}/oh-my-posh-themes"

# Be helpful with the themes
echo -e "${BLUE}For some initiall colors, go the the url 'https://ohmyposh.dev/docs/themes' and browse the following links to see what you might like${RESET}"

read -p "Please enter the url of the oh-my-posh theme you want to change to: " url

# Use sed to obtain the theme name and the raw content url file. Basically the following lines of code will:
# 1. Replace everything up until the last "/" with nothing and replace the string ".omp.json" with nothing
# 2. Replace github.com with raw.githubusercontent.com
# 3. Replace blob/ with nothing
theme_name="$(echo ${url} | sed 's/.*\///;s/\.omp\.json//')"
raw_content_url="$(echo ${url} | sed 's/github\.com/raw.githubusercontent.com/')"
raw_content_url="$(echo ${raw_content_url} | sed 's/blob\///')"
echo "theme name: ${theme_name}"
echo "raw_content_url: ${raw_content_url}"

# Now use curl to copy the folder
curl -L -o "${HOME}/oh-my-posh-themes/${theme_name}.json" "${raw_content_url}"

space_block=$(echo '{ "alignment": "left", "newline": true, "segments": [ { "foreground": "#ffffff", "foreground_templates": [ "{{ if gt .Code 0 }}#ff0000{{ end }}" ], "properties": { "always_enabled": true }, "style": "plain", "template": "\u0000 ", "type": "status" } ], "type": "prompt" }' | jq '.') && \
cat "${HOME}/oh-my-posh-themes/${theme_name}.json" | jq --argjson obj "${space_block}" '.blocks = [$obj] + .blocks' > temp.json && cat temp.json > "${HOME}/oh-my-posh-themes/${theme_name}.json" && rm temp.json

# And then place the following code into your .zshrc
cat <<EOL > "${HOME}/.zshrc"
theme_name="${theme_name}"
EOL

cat <<'EOL' >> "${HOME}/.zshrc"
eval "$(oh-my-posh init zsh --config ${HOME}/oh-my-posh-themes/${theme_name}.json)"
EOL

cat <<'EOL' >> "${HOME}/.zshrc"
if [[ ! -e "${HOME}/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]]; then
    git clone "https://github.com/zsh-users/zsh-syntax-highlighting.git" "${HOME}/zsh-syntax-highlighting"
fi
source "${HOME}/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"

# Aliases
alias ls='ls --color=auto'
alias man='2>/dev/null man'

# Manpager
export MANPAGER="nvim +Man! -"

# Flags
flag_set_foreground_color="38"
flag_set_background_color="38"
flag_set_bold="1"

# Colors
black="0"
white="15"
sky_blue_1="117"
dodger_blue_1="33"
sky_blue_3="74"
spring_green_2="42"
yellow_1="226"

# Tab highlight colors: Colors found at https://www.ditig.com/256-colors-cheat-sheet. The 5 is to use extended xterm color pallete
highlight_preview_colors="ma=${flag_set_foreground_color};5;${black};${flag_set_background_color};5;${sky_blue_1}"

# Tab completion colors
directory_color="di=${flag_set_bold};${flag_set_foreground_color};5;${dodger_blue_1}"
symbolic_link_color="ln=${flag_set_bold};${flag_set_foreground_color};5;${sky_blue_3}"
executable_color="ex=${flag_set_bold};${flag_set_foreground_color};5;${spring_green_2}"
socket_color="so=${flag_set_bold};${flag_set_foreground_color};5;${yellow_1}"
regular_file_color="fi=" # No modifications

# Set Tab completion highlight and colors
zstyle ":completion:*:default" list-colors ${(s.:.)LS_COLORS} "${highlight_preview_colors}:${directory_color}:${symbolic_link_color}:${executable_color}:${regular_file_color}"
zstyle ':completion:*' menu select

# Set LS colors
export LS_COLORS="${directory_color}:${symbolic_link_color}:${executable_color}:${regular_file_color}"

# Enable shift tab to go backwards in highlight searching
zmodload zsh/complist
bindkey -M menuselect '^[[Z' reverse-menu-complete

# Enable auto completion of commands from history with up and down arrow keys (if text is already entered)
autoload -U history-search-end
zle -N history-beginning-search-backward-end history-search-end
zle -N history-beginning-search-forward-end history-search-end
bindkey "^[OA" history-beginning-search-backward-end
bindkey "^[OB" history-beginning-search-forward-end

EOL

echo -e "${GREEN}To see the new configuration execute the command 'exec zsh'."
echo -e "${YELLOW}If the fonts do not show up, please ensure that nerd fonts is installed on your host computer.${RESET}"

EOF

RUN chmod u+x ${HOME}/change_oh_my_posh_appearance_zsh.sh

######################################## Configure PowerShell ########################################
USER testuser1
WORKDIR /home/testuser1

# Ensure and obtain the profile information
SHELL ["/usr/bin/pwsh", "-command"]
RUN New-Item -Path $PROFILE -Type File -Force
RUN Add-Content -Path "${HOME}/POWERSHELL_PROFILE.txt" -Value $PROFILE
SHELL ["/bin/bash", "-c"]

# Create the default configuration (blue-owl)
RUN echo "hello world"
RUN mkdir -p "${HOME}/oh-my-posh-themes"
RUN curl -L -o "${HOME}/oh-my-posh-themes/blue-owl.json" "https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/blue-owl.omp.json"

# modify the json file to include more leading space between the output of the prompt and the start of the next prompt
RUN space_block=$(echo '{ "alignment": "left", "newline": true, "segments": [ { "foreground": "#ffffff", "foreground_templates": [ "{{ if gt .Code 0 }}#ff0000{{ end }}" ], "properties": { "always_enabled": true }, "style": "plain", "template": "\u0000 ", "type": "status" } ], "type": "prompt" }' | jq '.') && \
    cat "${HOME}/oh-my-posh-themes/blue-owl.json" | jq --argjson obj "${space_block}" '.blocks = [$obj] + .blocks' > temp.json && cat temp.json > "${HOME}/oh-my-posh-themes/blue-owl.json" && rm temp.json

# Configure $PROFILE to the default configuration (blue-owl)
RUN cat <<'EOF' > "$(cat ${HOME}/POWERSHELL_PROFILE.txt)"
$theme_name="blue-owl"
EOF

RUN cat <<'EOF' >> "$(cat ${HOME}/POWERSHELL_PROFILE.txt)"
oh-my-posh init pwsh --config ${HOME}/oh-my-posh-themes/${theme_name}.json | Invoke-Expression
EOF

# Remove the temporary file
RUN rm "${HOME}/POWERSHELL_PROFILE.txt"

# Create a script which helps change the appearance
RUN cat <<'EOF' > ${HOME}/change_oh_my_posh_appearance_pwsh.sh
#! /usr/bin/bash

# Exit on error
set -e

# ANSI color codes for some helpful coloured output
BLACK='\033[0;30m'
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
RESET='\033[0m' # Reset color to default

# Create a directory if it does not already exist
mkdir -p "${HOME}/oh-my-posh-themes"

# Be helpful with the themes
echo -e "${BLUE}For some initiall colors, go the the url 'https://ohmyposh.dev/docs/themes' and browse the following links to see what you might like${RESET}"

read -p "Please enter the url of the oh-my-posh theme you want to change to: " url

# Use sed to obtain the theme name and the raw content url file. Basically the following lines of code will:
# 1. Replace everything up until the last "/" with nothing and replace the string ".omp.json" with nothing
# 2. Replace github.com with raw.githubusercontent.com
# 3. Replace blob/ with nothing
theme_name="$(echo ${url} | sed 's/.*\///;s/\.omp\.json//')"
raw_content_url="$(echo ${url} | sed 's/github\.com/raw.githubusercontent.com/')"
raw_content_url="$(echo ${raw_content_url} | sed 's/blob\///')"
echo "theme name: ${theme_name}"
echo "raw_content_url: ${raw_content_url}"

# Now use curl to copy the folder
curl -L -o "${HOME}/oh-my-posh-themes/${theme_name}.json" "${raw_content_url}"

space_block=$(echo '{ "alignment": "left", "newline": true, "segments": [ { "foreground": "#ffffff", "foreground_templates": [ "{{ if gt .Code 0 }}#ff0000{{ end }}" ], "properties": { "always_enabled": true }, "style": "plain", "template": "\u0000 ", "type": "status" } ], "type": "prompt" }' | jq '.') && \
cat "${HOME}/oh-my-posh-themes/${theme_name}.json" | jq --argjson obj "${space_block}" '.blocks = [$obj] + .blocks' > temp.json && cat temp.json > "${HOME}/oh-my-posh-themes/${theme_name}.json" && rm temp.json

# And then place the following code into your powershell profile
profile_path=$(pwsh -Command '$PROFILE')

cat <<EOL > "$profile_path"
\$theme_name="${theme_name}"
EOL

cat <<'EOL' >> "$profile_path"
oh-my-posh init pwsh --config ${HOME}/oh-my-posh-themes/${theme_name}.json | Invoke-Expression
EOL

echo -e "${GREEN}To see the new configuration source the powershell profile with '. \$PROFILE'."
echo -e "${YELLOW}If the fonts do not show up, please ensure that nerd fonts is installed on your host computer.${RESET}"

EOF

RUN chmod u+x ${HOME}/change_oh_my_posh_appearance_pwsh.sh

######################################## Nvim Installation ########################################
USER root
WORKDIR /
RUN curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim.appimage && chmod u+x nvim.appimage && ./nvim.appimage --appimage-extract
RUN ln -s /squashfs-root/AppRun /usr/bin/nvim

USER testuser1
WORKDIR /home/testuser1

# Make the folder structure for the nvim configuration
RUN mkdir -p ${HOME}/.config/nvim/lua/testuser1/core && \
    mkdir ${HOME}/.config/nvim/lua/testuser1/plugins && \
    mkdir ${HOME}/.config/nvim/plugin

# Make the core configurations
# Options
RUN cat <<'EOF' > ${HOME}/.config/nvim/lua/testuser1/core/options.lua
local opt = vim.opt -- for conciseness

-- allow mouse
opt.mouse = "a"

-- line numbers
opt.relativenumber = true -- show relative line numbers
opt.number = true -- show absolute line number on cursor line (when relative number is on)

-- tabs & indentation
opt.tabstop = 4 -- Four spaces for tabs (prettier default)
opt.shiftwidth = 4 -- Four spaces for indent width
opt.expandtab = true -- expand tab to spaces
opt.autoindent = true -- copy indent from current line when starting new one

-- line wrapping
opt.wrap = false -- disable line wrapping

-- search settings
opt.ignorecase = true -- ignore case when searching
opt.smartcase = true -- if you include mixed case in your search, assumes you want case-insensitive

-- cursor line
opt.cursorline = true -- highlight the current cursor line

-- appearance
opt.termguicolors = true
opt.background = "dark" -- colorschemes that can be light or datk will be made dark
opt.signcolumn = "yes" -- show sign column so that text does not shift

-- backspace
opt.backspace = "indent,eol,start" -- allow backspace on indent, end of line or insert mode start position

-- clipboard
opt.clipboard:append("unnamedplus") -- use system clipboard as default register

-- split windows
opt.splitright = true -- split vertical window to the right
opt.splitbelow = true -- split horizontal window to the bottom

opt.iskeyword:append("-") -- consider string-string as whole word

EOF

# Colorscheme
RUN cat <<'EOF' > ${HOME}/.config/nvim/lua/testuser1/core/colorscheme.lua
-- set colorscheme to nightfly with protected in case nightfly is not installed
local status, _ = pcall(vim.cmd, "colorscheme nightfly")
if not status then 
    print("Colorscheme not found!")
    return
end

EOF

# Keymaps
RUN cat <<'EOF' > ${HOME}/.config/nvim/lua/testuser1/core/keymaps.lua
vim.g.mapleader = " "

local keymap = vim.keymap -- for conciseness

--------------------
-- General Keymaps
--------------------

-- Clear search highlights
keymap.set("n", "<leader>nh", ":set nohls<CR>")
keymap.set("n", "<leader>hh", ":set hls<CR>")

-- Delete single character without copying into register
keymap.set("n", "x", "_x")

-- window management
keymap.set("n", "<leader>sv", "<C-w>v") -- split windows vertically
keymap.set("n", "<leader>sh", "<C-w>s") -- split windows horizontally
keymap.set("n", "<leader>se", "<C-w>=") -- make split windows equal width & height
keymap.set("n", "<leader>sq", ":close<CR>") -- close current split window

-- Open keybindings for tmux and nvim for window navigation
keymap.set("n", "<C-n>", "<Nop>") -- gonna use this to navigate to previous window
keymap.set("n", "<C-p>", "<Nop>") -- gonna use this to navigate to next window

-- keymap.set("n", "<leader>to", ":tabnew<CR>") -- open new tab
-- keymap.set("n", "<leader>tx", ":tabclose<CR>") -- close current tab
-- keymap.set("n", "<leader>tn", ":tabn<CR>") -- go to next tab
-- keymap.set("n", "<leader>tp", ":tabp<CR>") -- go to previous tab

--------------------
-- Plugin Keybinds
--------------------

-- -- vim-maximizer
-- keymap.set("n", "<leader>sm", ":MaximizerToggle<CR>") -- toggle split window maximization
-- 
-- -- nvim-tree
-- keymap.set("n", "<leader>e", ":NvimTreeToggle<CR>") -- toggle file explorer
-- 
-- -- telescope
-- keymap.set("n", "<leader>ff", "<cmd>Telescope find_files<CR>") -- find files within current working directory, respect .gitignore
-- keymap.set("n", "<leader>fs", "<cmd>Telescope live_grep<CR>") -- find string in current working directory as you type
-- keymap.set("n", "<leader>fc", "<cmd>Telescope grep_string<CR>") -- find string under cursor in current working directory
-- keymap.set("n", "<leader>fb", "<cmd>Telescope buffers<CR>") -- list open buffers in current neovim instance
-- keymap.set("n", "<leader>fh", "<cmd>Telescope help_tags<CR>") -- list available help tags
-- 
-- -- telescope git commands (not on youtube nvim video)
-- keymap.set("n", "<leader>gc", "<cmd>Telescope git_commits<CR>") -- list all git commits (use <CR> to checkout) ["gc" for git commits]
-- keymap.set("n", "<leader>gfc", "<cmd>Telescope git_bcommits<CR>") -- list git commits for current file/buffer (use <CR> to checkout) ["gfc" for git file commits]
-- keymap.set("n", "<leader>gb", "<cmd>Telescope git_branches<CR>") -- list git branches (use <CR> to checkout) ["gb" for git branch]
-- keymap.set("n", "<leader>gs", "<cmd>Telescope git_status<CR>") -- list current changes per file with diff preview ["gs" for git status]
-- 
-- -- restart lsp server (not on youtube nvim video)
-- keymap.set("n", "<leader>rs", ":LspRestart<CR>") -- mapping to restart lsp if necessary
EOF

# Setting up plugins
RUN cat <<'EOF' > ${HOME}/.config/nvim/lua/testuser1/plugins-setup.lua
-- auto install packer if not installed
local ensure_packer = function()
    local fn = vim.fn
    local install_path = fn.stdpath("data") .. "/site/pack/packer/start/packer.nvim"
    if fn.empty(fn.glob(install_path)) > 0 then
        fn.system({ "git", "clone", "--depth", "1", "https://github.com/wbthomason/packer.nvim", install_path})
        vim.cmd([[packadd packer.nvim]])
        return true
    end
    return false
end
local packer_bootstrap = ensure_packer() -- true if packer was just installed

-- autocommand that reloads neovim and installs/updates/removes plugins
-- when file is saved
vim.cmd([[
    augroup packer_user_config
        autocmd!
        autocmd BufWritePost plugins-setup.lua source <afile> | PackerSync
    augroup end
]])

-- import packer safely
local status, packer = pcall(require, "packer")
if not status then 
    return
end

-- add list of plugins to install
return packer.startup(function(use)
    -- packer can manage itself
    use("wbthomason/packer.nvim")
    use("bluz71/vim-nightfly-guicolors") -- preferred coloscheme
    use("christoomey/vim-tmux-navigator") -- tmux & split windows navigation
    use("tpope/vim-surround") -- essential plugin
    use("vim-scripts/ReplaceWithRegister") -- essential plugin
    use("numToStr/Comment.nvim") -- Commenting with gc
    if packer_bootstrap then
        require("packer").sync()
    end
end)
EOF

# Comments plugin
RUN cat <<'EOF' > ${HOME}/.config/nvim/lua/testuser1/plugins/comment.lua
local setup, comment = pcall(require, "Comment")
if not setup then
    return
end

comment.setup()
EOF

# Config
RUN cat <<'EOF' > ${HOME}/.config/nvim/init.lua
require("testuser1.plugins-setup")
require("testuser1.core.options")
require("testuser1.core.colorscheme")
require("testuser1.core.keymaps")
require("testuser1.plugins.comment")
EOF

######################################## Tmux Installation ########################################
RUN git clone https://github.com/tmux-plugins/tpm ${HOME}/.tmux/plugins/tpm
RUN cat <<'EOF' > ${HOME}/.tmux.conf
# Get rid of tmux nvim lag from escaping
set -sg escape-time 0

# Change the prefix
set -g prefix C-a
unbind C-b
bind-key C-a send-prefix

# Use <C-a>n to split terminal vertically
unbind %
bind n split-window -h

# Use <C-a>N to split the terminal horizontally
unbind '"'
bind N split-window -v

# Use <C-a>r to reload the tmux configuration file
unbind r
bind r source-file ~/.tmux.conf

# Use <C-a>[h|j|k|l] to resize the pane by 5 units
# Use <C-a>m to maximise the tmux pane
# Enable the mouse to be able to maximise
bind -r j resize-pane -D 5
bind -r k resize-pane -U 5
bind -r l resize-pane -R 5
bind -r h resize-pane -L 5
bind -r m resize-pane -Z
set -g mouse on

# Use <C-a>t to create a new window
unbind t
bind t new-window

# Use <C-n> and <C-p> to go to the next and previous window
unbind C-h
unbind C-l
bind-key -n C-n previous-window
bind-key -n C-p next-window

# Use <C-a>q to kill the pane
unbind q
bind q kill-pane

# Enable vi mode in tmux and use <C-a>v to enter it
unbind v
bind v copy-mode
set-window-option -g mode-keys vi
bind-key -T copy-mode-vi 'v' send -X begin-selection
bind-key -T copy-mode-vi 'y' send-keys -X copy-pipe 'xclip -in -selection clipboard'
unbind -T copy-mode-vi MouseDragEnd1Pane

# After executing git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
# Tmux plugin manager
set -g @plugin 'tmux-plugins/tpm'

# Naviagating tmux panes
set -g @plugin 'christoomey/vim-tmux-navigator'

# Themes for tmux
set -g @plugin 'jimeh/tmux-themepack'
set -g @themepack 'powerline/default/cyan'

# Initalize TMUX plugin manager (keep this line at the very bootom of the tmux.conf file)
# To reload: <C-a>r
# To install plugins: <C-a>I
run '~/.tmux/plugins/tpm/tpm'
EOF

######################################## VSCode Extension Installation ########################################
# Install vscode (code-server)
RUN cat <<'EOF'  > ${HOME}/install-vscode-extensions.sh
if command -v code; then
    # put installations here (use the extension ID)
    code --install-extension Llam4u.nerdtree
    code --install-extension ms-azuretools.vscode-azureterraform
    code --install-extension hashicorp.terraform
    code --install-extension ms-azuretools.vscode-docker
else
    echo "You don't have code-server installed on this container. Install or attach to vscode server using dev containers."
fi
EOF

RUN chmod u+x ${HOME}/install-vscode-extensions.sh

######################################## README markdown file ########################################
RUN cat <<EOF > ${HOME}/README.md
To initialise the main components in the dev container:
- Make sure that you are attached to the container with VSCode's "Dev Containers" extension.
- Run the script located at "${HOME}/install-vscode-extensions.sh" to install all th extensions you wrote down in the Dockerfile.
- Type the command "nvim". This will insall all the necessary plugins so that in any subsequent call to "nvim" it will be configured.
- Type the command "tmux". Then type "<C-a>I" and then "<C-a>r". This will install the necessary plugins so that in any subsequent call to "tmux" it will be configured.
EOF