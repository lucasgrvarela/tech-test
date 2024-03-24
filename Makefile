SHELL := /bin/bash

export PATH := $(HOME)/.asdf/bin:$(PATH)

.PHONY: setup
setup:
	sudo apt install git curl -y
	[ -d ~/.asdf ] && echo "asdf exists" || git clone https://github.com/asdf-vm/asdf.git ~/.asdf --branch v0.13.0
	printf "\nsource ~/.asdf/asdf.sh" >> ~/.bashrc
	asdf plugin add just && asdf install just latest && asdf global just latest
