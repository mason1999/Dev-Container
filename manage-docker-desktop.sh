#! /usr/bin/bash

getopts ':cd' option

case $option in
  (c)
    # Add Dockers official GPG key:
    sudo apt-get update
    sudo apt-get install ca-certificates curl gnupg
    sudo install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    sudo chmod a+r /etc/apt/keyrings/docker.gpg

    # Add the repository to Apt sources:
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
      $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
      sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt-get update

    # Download the docker desktop debian package
    curl -L -o ~/Downloads/docker-desktop.deb "https://desktop.docker.com/linux/main/amd64/docker-desktop-4.26.1-amd64.deb?utm_source=docker&utm_medium=webreferral&utm_campaign=docs-driven-download-linux-amd64&_gl=1*19qoncv*_ga*MTc3MTcxNTEzNC4xNzAyMzM5OTU0*_ga_XJWPQMJYHQ*MTcwMzAzODUxMS42LjEuMTcwMzAzOTU1Ni42MC4wLjA."

    # Update and install
    sudo apt-get update
    sudo apt-get install ~/Downloads/docker-desktop.deb
  ;;
  (d)
    sudo apt remove docker-desktop
    sudo rm -rf $HOME/.docker/desktop
    sudo rm /usr/local/bin/com.docker.cli
    sudo apt purge docker-desktop
    sudo rm -rf $HOME/.docker/config.json
  ;;
  (?)
  ;;
esac
