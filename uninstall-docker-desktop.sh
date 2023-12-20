#! /usr/bin/bash

sudo apt remove docker-desktop
sudo rm -rf $HOME/.docker/desktop
sudo rm /usr/local/bin/com.docker.cli
sudo apt purge docker-desktop
sudo rm -rf $HOME/.docker/config.json