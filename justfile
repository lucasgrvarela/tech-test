# Helper/List all the available commands and their description
default:
  just --list

#####       #####
#####       #####
##### TOOLS #####
#####       #####
#####       #####

# Install all the tools you will need to setup the project
deps:
	echo "installing dependencies"
	asdf plugin add kind https://github.com/reegnz/asdf-kind.git && asdf install kind latest && asdf global kind latest
	asdf plugin add vegeta https://github.com/grimoh/asdf-vegeta.git && asdf install vegeta latest && asdf global vegeta latest
	asdf plugin add kubectl && ASDF_KUBECTL_OVERWRITE_ARCH=amd64 asdf install kubectl 1.29.2 && asdf global kubectl 1.29.2
	asdf plugin add helm && asdf install helm latest && asdf global helm latest
	asdf plugin add jq && asdf install jq latest && asdf global jq latest

#####           #####
#####           #####
##### LOCAL K8S #####
#####           #####
#####           #####

# Create local kubernetes cluster with KinD
setup-kind:
	bash kind/kind-with-registry.sh # https://kind.sigs.k8s.io/docs/user/local-registry/

# Set the current kubernetes context to the kind cluster
set-context:
	kubectl config use-context kind-kind

# Configure metallb to have an loadbalancer on the cluster and expose services to the host machine
setup-metallb:
	# https://kind.sigs.k8s.io/docs/user/loadbalancer/
	# https://metallb.universe.tf/installation/ -> Followed this doc to install with Helm
	kubectl create namespace metallb-system
	helm repo add metallb https://metallb.github.io/metallb
	helm repo update
	helm install metallb metallb/metallb -n metallb-system --wait
	kubectl apply -f metallb/metallb-config.yaml # change address based on the command $ docker network inspect kind | jq .[0].IPAM.Config

#####       #####
#####       #####
##### ISTIO #####
#####       #####
#####       #####

# Install istio CRDs and istiod -- control plane
setup-istio:
	kubectl create namespace istio-system
	helm repo add istio https://istio-release.storage.googleapis.com/charts
	helm repo update
	helm install istio-base istio/base -n istio-system --set defaultRevision=default # CRDs prereq to control plane istiod
	helm install istiod istio/istiod -n istio-system --wait

# Install the istio ingress gateway
setup-ingress-gateway:
	kubectl create namespace istio-ingress
	helm install istio-ingress istio/gateway -n istio-ingress --wait

# Configure the traffic split for the applications
setup-traffic-split:
	#kubectl label namespace default istio-injection=enabled

#####            #####
#####            #####
##### MONITORING #####
#####            #####
#####            #####

# Configure Kiali UI Dashboard
setup-kiali:
	# https://kiali.io/docs/installation/installation-guide/install-with-helm/
	# https://istio.io/latest/docs/ops/integrations/kiali/
	helm repo add kiali https://kiali.org/helm-charts
	helm repo update
	helm install --set cr.create=true --set cr.namespace=istio-system --namespace kiali-operator --create-namespace kiali-operator kiali/kiali-operator

# Configure Prometheus monitoring
setup-prometheus:
	kubectl create namespace monitoring
	helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
	helm repo update
	helm install prometheus prometheus-community/prometheus -n monitoring

# Configure Grafana dashboards
setup-grafana:
	helm repo add grafana https://grafana.github.io/helm-charts
	helm repo update
	helm install grafana grafana/grafana --namespace monitoring

#####      #####
#####      #####
##### APPS #####
#####      #####
#####      #####

# Build the Go app
go-build:
	docker build -t go-webserver:v0.0.1 ./go-app/

# Docker tag and push the Go app to the local registry
go-push:
	docker tag go-webserver:v0.0.1 localhost:5001/go-webserver:v0.0.1
	docker push localhost:5001/go-webserver:v0.0.1

# Build the Java app
java-build:
	docker build -t java-webserver:v0.0.1 ./java-app/

# Docker tag and push the Java app to the local registry
java-push:
	docker tag java-webserver:v0.0.1 localhost:5001/java-webserver:v0.0.1
	docker push localhost:5001/java-webserver:v0.0.1

# Install the Go app using Helm
helm-install-go:
	kubectl apply -f go-app/templates/

# Install the Java app using Helm
helm-install-java:
	kubectl apply -f java-app/templates/

# Load test the applications
generate-load:
	jq -ncM '{method: "GET", url: "http://localhost:8080" }' | vegeta attack -format=json -rate=10 -duration=10s

#####      #####
#####      #####
##### MAIN #####
#####      #####
#####      #####

# Spinup all the infrastructure from local k8s to monitoring
setup-all-infra: deps setup-kind set-context setup-metallb setup-istio setup-ingress-gateway setup-traffic-split setup-kiali setup-prometheus setup-grafana

# Spinup all the applications configurations from build, push to helm install
setup-all-apps: go-build java-build go-push java-push helm-install-go helm-install-java