deps:
	echo "installing dependencies"

	# go
	asdf plugin add golang && asdf install golang latest && asdf global golang latest
	go install sigs.k8s.io/kind@v0.22.0
	go install github.com/tsenart/vegeta@latest

	# docker
	sudo apt install uidmap -y && curl -fsSL get.docker.com -o get-docker.sh && sh get-docker.sh && rm get-docker.sh && dockerd-rootless-setuptool.sh install --force

	# kubectl
	asdf plugin add kubectl && ASDF_KUBECTL_OVERWRITE_ARCH=amd64 asdf install kubectl 1.29.2 && asdf global kubectl 1.29.2

	# helm
	asdf plugin add helm && asdf install helm latest && asdf global helm latest

	# jq
	asdf plugin add jq && asdf install jq latest && asdf global jq latest

	# istio
	asdf plugin add istio https://github.com/solo-io/asdf-istio && asdf install istio latest && asdf global istio latest
	echo -e '\nPATH="$PATH:~/.asdf/installs/istio/$(ls ~/.asdf/installs/istio/)/bin"' >> ~/.bashrc

go-build:
	docker build -t go-webserver:v0.0.1 -f Dockerfile-go .

go-push:
	# push to local kind registry

java-build:
	docker build -t java-webserver:v0.0.1 -f Dockerfile-java .

java-push:
	# push to local kind registry

setup-kind:
	kind create cluster

get-cluster:
	kind get clusters

set-context:
	kubectl config use-context kind-kind

setup-istio:
	helm repo add istio https://istio-release.storage.googleapis.com/charts
	helm repo update

	# base chart which contains cluster-wide CRDs which must be installed prior to the deployment of the control plane
	helm install istio-base istio/base -n istio-system --set defaultRevision=default

	# discovery chart which deploys the istiod service
	helm install istiod istio/istiod -n istio-system --wait

	# https://istio.io/latest/docs/setup/platform-setup/kind/#setup-metallb-for-kind
	# https://kind.sigs.k8s.io/docs/user/loadbalancer/
	


	# ingress gateway
	kubectl create namespace istio-ingress
	helm install istio-ingress istio/gateway -n istio-ingress --wait

setup-prometheus:
	helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
	helm repo update
	helm install prometheus-community/prometheus --generate-name

setup-all:
	#deps
	#setup-kind
	#setup-istio
	#setup-prometheus

generate-load:
	jq -ncM '{method: "GET", url: "http://localhost:8080" }' | vegeta attack -format=json -rate=10 -duration=10s