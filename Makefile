.PHONY: setup
setup:
	# git
	sudo apt install git -y

	# asdf
	[ -d ~/.asdf ] && echo "asdf exists" || git clone https://github.com/asdf-vm/asdf.git ~/.asdf --branch v0.13.0
	printf "\nsource ~/.asdf/asdf.sh" >> ~/.bashrc

	# just
	asdf plugin add just && asdf install just latest && asdf global just latest