default:
  just --list

deps:
	echo "installing dependencies"

	# go
	asdf plugin add golang && asdf install golang latest && asdf global golang latest
	go install sigs.k8s.io/kind@v0.22.0
	go install github.com/tsenart/vegeta@latest

	# kubectl
	asdf plugin add kubectl && ASDF_KUBECTL_OVERWRITE_ARCH=amd64 asdf install kubectl 1.29.2 && asdf global kubectl 1.29.2

	# helm
	asdf plugin add helm && asdf install helm latest && asdf global helm latest

	# jq
	asdf plugin add jq && asdf install jq latest && asdf global jq latest

setup-kind:
	# https://kind.sigs.k8s.io/docs/user/local-registry/
	bash kind/kind-with-registry.sh 

set-context:
	kubectl config use-context kind-kind

setup-metallb:
	# https://kind.sigs.k8s.io/docs/user/loadbalancer/
	# https://metallb.universe.tf/installation/ -> Followed this doc to install with Helm
	kubectl create namespace metallb-system
	helm repo add metallb https://metallb.github.io/metallb
	helm repo update
	helm install metallb metallb/metallb -n metallb-system --wait
	kubectl apply -f metallb/metallb-config.yaml # change address based on the command $ docker network inspect kind | jq .[0].IPAM.Config

setup-istio:
	kubectl create namespace istio-system

	helm repo add istio https://istio-release.storage.googleapis.com/charts
	helm repo update

	# base chart which contains cluster-wide CRDs which must be installed prior to the deployment of the control plane
	helm install istio-base istio/base -n istio-system --set defaultRevision=default

	# discovery chart which deploys the istiod service
	helm install istiod istio/istiod -n istio-system --wait

setup-kiali:
	# https://kiali.io/docs/installation/installation-guide/install-with-helm/
	helm repo add kiali https://kiali.org/helm-charts
	helm repo update
	helm install --set cr.create=true --set cr.namespace=istio-system --namespace kiali-operator --create-namespace kiali-operator kiali/kiali-operator

setup-ingress-gateway:
	kubectl create namespace istio-ingress
	helm install istio-ingress istio/gateway -n istio-ingress --wait

setup-prometheus:
	kubectl create namespace monitoring
	helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
	helm repo update
	helm install prometheus prometheus-community/prometheus -n monitoring

setup-grafana:
	helm repo add grafana https://grafana.github.io/helm-charts
	helm repo update
	helm install grafana grafana/grafana --namespace monitoring

#setup-all: deps setup-kind set-context setup-metallb setup-istio setup-kiali setup-ingress-gateway setup-prometheus setup-grafana
setup-all: setup-kind set-context setup-metallb setup-istio setup-kiali setup-ingress-gateway setup-prometheus setup-grafana

go-build:
	docker build -t go-webserver:v0.0.1 -f Dockerfile-go .

go-push:
	docker tag go-webserver:v0.0.1 localhost:5001/go-webserver:v0.0.1
	docker push localhost:5001/go-webserver:v0.0.1

java-build:
	docker build -t java-webserver:v0.0.1 -f Dockerfile-java .

java-push:
	docker tag java-webserver:v0.0.1 localhost:5001/java-webserver:v0.0.1
	docker push localhost:5001/java-webserver:v0.0.1

helm-install-go:
	#

helm-install-java:
	#

build-push-install: go-build java-build go-push java-push  helm-install-go helm-install-java

generate-load:
	jq -ncM '{method: "GET", url: "http://localhost:8080" }' | vegeta attack -format=json -rate=10 -duration=10s