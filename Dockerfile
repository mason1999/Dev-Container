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