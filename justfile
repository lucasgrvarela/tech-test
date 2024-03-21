# configure deps
deps:
	echo "installing dependencies"

	# go
	asdf plugin add golang && asdf install golang latest && asdf global golang latest
	go install sigs.k8s.io/kind@v0.22.0
	go install github.com/tsenart/vegeta@latest

	# docker
	sudo apt install uidmap -y && curl -fsSL get.docker.com -o get-docker.sh && sh get-docker.sh && rm get-docker.sh && dockerd-rootless-setuptool.sh install --force

	# kubectl
	asdf plugin add kubectl && ASDF_KUBECTL_OVERWRITE_ARCH=amd64 asdf install kubectl 1.29 && asdf global kubectl 1.29

	# helm
	asdf plugin add helm && asdf install helm latest && asdf global helm latest

	# jq
	asdf plugin add jq && asdf install jq latest && asdf global jq latest

	# istio
	asdf plugin add istio https://github.com/solo-io/asdf-istio && asdf install istio latest && asdf global istio latest
	echo -e '\nPATH="$PATH:~/.asdf/installs/istio/$(ls ~/.asdf/installs/istio/)/bin"' >> ~/.bashrc

setup-kind:
	# to do

create-cluster:
	kind create cluster

get-cluster:
	kind get clusters

set-context:
	kubectl config use-context kind-kind

# build go, build java, push registry kind go, push registry kind  java

generate-load:
	jq -ncM '{method: "GET", url: "http://localhost:8080" }' | vegeta attack -format=json -rate=10 -duration=10s