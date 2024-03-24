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
	kubectl create namespace metallb-system
	helm repo add metallb https://metallb.github.io/metallb
	helm repo update
	helm install metallb metallb/metallb -n metallb-system --wait -f metallb/values.yaml
	bash metallb.sh
	kubectl apply -f metallb/metallb-config.yaml

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
	helm install istio-base istio/base -n istio-system --set defaultRevision=default -f istio-base/values.yaml # CRDs prereq to control plane istiod
	helm install istiod istio/istiod -n istio-system --wait -f istiod/values.yaml

# Install the istio ingress gateway
setup-ingress-gateway:
	kubectl create namespace istio-ingress
	helm install istio-ingress istio/gateway -n istio-ingress --wait

#####            #####
#####            #####
##### MONITORING #####
#####            #####
#####            #####

# Configure Kiali UI Dashboard
setup-kiali:
	helm repo add kiali https://kiali.org/helm-charts
	helm repo update
	helm upgrade --install --namespace kiali-operator --create-namespace kiali-operator kiali/kiali-operator -f kiali/values.yaml
	# kubectl -n istio-system create token kiali-service-account
	# kubectl -n istio-system port-forward svc/kiali 20001:20001 # http://localhost:20001/kiali/

# Configure Prometheus monitoring
setup-prometheus:
	# https://istio.io/latest/docs/ops/integrations/prometheus/
	# helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
	# helm repo update
	# helm install prometheus prometheus-community/prometheus -n istio-system

# Configure Grafana dashboards
setup-grafana:
	# helm repo add grafana https://grafana.github.io/helm-charts
	# helm repo update
	# helm install grafana grafana/grafana -n istio-system

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
	helm upgrade --install -namespace go-webserver --create-namespace go-webserver -f go-app/values.yaml helm-app/

# Install the Java app using Helm
helm-install-java:
	helm upgrade --install -namespace java-webserver --create-namespace java-webserver -f java-app/values.yaml helm-app/

# Load test the applications
generate-load:
	jq -ncM '{method: "GET", url: "http://localhost:8080" }' | vegeta attack -format=json -rate=10 -duration=10s

#####      #####
#####      #####
##### MAIN #####
#####      #####
#####      #####

# Spinup all the infrastructure from local k8s to monitoring
setup-all-infra: deps setup-kind set-context setup-metallb setup-istio setup-ingress-gateway setup-kiali setup-prometheus setup-grafana

# Spinup all the applications configurations from build, push to helm install
setup-all-apps: go-build java-build go-push java-push helm-install-go helm-install-java