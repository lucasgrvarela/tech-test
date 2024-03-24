# Helper/List all the available commands and their description
default:
  @just --list

#####       #####
##### TOOLS #####
#####       #####

# Install all the tools you will need to setup the project
deps:
	asdf plugin add vegeta https://github.com/grimoh/asdf-vegeta.git && asdf install vegeta latest && asdf global vegeta latest
	asdf plugin add kind https://github.com/reegnz/asdf-kind.git && asdf install kind latest && asdf global kind latest
	asdf plugin add kubectl && ASDF_KUBECTL_OVERWRITE_ARCH=amd64 asdf install kubectl 1.29.2 && asdf global kubectl 1.29.2
	asdf plugin add helm && asdf install helm latest && asdf global helm latest
	asdf plugin add jq && asdf install jq latest && asdf global jq latest

#####           #####
##### LOCAL K8S #####
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
##### ISTIO #####
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
	helm upgrade -i istio-ingressgateway istio/gateway -n istio-system --create-namespace --wait -f istio-ingress-gateway/values.yaml

#####            #####
##### MONITORING #####
#####            #####

# Configure Kiali, Prometheus, Grafana, Tracing (Jaeger)
setup-kiali:
	helm repo add kiali https://kiali.org/helm-charts
	helm repo update
	helm upgrade -i -n kiali-operator --create-namespace kiali-operator kiali/kiali-operator -f kiali/values.yaml
	kubectl apply -f https://raw.githubusercontent.com/istio/istio/release-1.21/samples/addons/prometheus.yaml
	kubectl apply -f https://raw.githubusercontent.com/istio/istio/release-1.21/samples/addons/grafana.yaml
	kubectl apply -f https://raw.githubusercontent.com/istio/istio/release-1.21/samples/addons/jaeger.yaml
	# kubectl -n istio-system create token kiali-service-account
	# kubectl -n istio-system port-forward svc/kiali 20001:20001 # http://localhost:20001/kiali/

#####      #####
##### APPS #####
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
	helm upgrade -i -n go-webserver --create-namespace go-webserver helm-app/ -f go-app/values.yaml

# Install the Java app using Helm
helm-install-java:
	helm upgrade -i -n java-webserver --create-namespace java-webserver helm-app/ -f java-app/values.yaml

# Load test the applications
generate-load:
	jq -ncM '{method: "GET", url: "http://localhost:8080" }' | vegeta attack -format=json -rate=10 -duration=10s

#####      #####
##### MAIN #####
#####      #####

# Spinup all the infrastructure from local k8s to monitoring
setup-all-infra: deps setup-kind set-context setup-metallb setup-istio setup-ingress-gateway setup-kiali

# Spinup all the applications configurations from build, push to helm install
setup-all-apps: go-build java-build go-push java-push helm-install-go helm-install-java

setup-test-go-app:
	curl -H Host:go-webserver.example.com "http://172.19.255.201:80/health"
	@sleep 2
	curl -H Host:go-webserver.example.com "http://172.19.255.201:80/hotels"