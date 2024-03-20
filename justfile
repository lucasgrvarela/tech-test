# Helper/List all the available commands and their description
default:
  @just --list

#####       #####
##### TOOLS #####
#####       #####

# Install all the tools you will need to setup the project
deps:
	asdf plugin add istio https://github.com/solo-io/asdf-istio && asdf install istio latest && asdf global istio latest
	asdf plugin add kind https://github.com/reegnz/asdf-kind.git && asdf install kind latest && asdf global kind latest
	asdf plugin add kubectl && ASDF_KUBECTL_OVERWRITE_ARCH=amd64 asdf install kubectl 1.29.2 && asdf global kubectl 1.29.2
	asdf plugin add helm && asdf install helm latest && asdf global helm latest
	asdf plugin add hey && asdf install hey latest && asdf global hey latest
	asdf plugin add jq && asdf install jq latest && asdf global jq latest

#####           #####
##### LOCAL K8S #####
#####           #####

# Create local kubernetes cluster with kind
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
	bash metallb/fix-ip.sh
	kubectl apply -f metallb/metallb-config.yaml --wait=true

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
	helm upgrade -i -n kiali-operator --create-namespace kiali-operator kiali/kiali-operator -f kiali/values.yaml --wait
	kubectl apply -f https://raw.githubusercontent.com/istio/istio/release-1.21/samples/addons/prometheus.yaml --wait=true
	kubectl apply -f https://raw.githubusercontent.com/istio/istio/release-1.21/samples/addons/grafana.yaml --wait=true
	kubectl apply -f https://raw.githubusercontent.com/istio/istio/release-1.21/samples/addons/jaeger.yaml --wait=true

# Open all dashs like kiali (token will be printed on terminal), jaeger, prometheus and grafana
open-dashboards: wait-for-kiali
	kubectl -n istio-system create token kiali-service-account
	istioctl dashboard kiali &
	istioctl dashboard jaeger &
	istioctl dashboard prometheus &
	istioctl dashboard grafana &

wait-for-kiali:
	sleep 60

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
	helm upgrade -i -n go-webserver --create-namespace go-webserver helm-app/ -f go-app/values.yaml --wait

# Install the Java app using Helm
helm-install-java:
	helm upgrade -i -n java-webserver --create-namespace java-webserver helm-app/ -f java-app/values.yaml --wait

# Simple curl to test the apps are up and running
test-apps:
	@sh -ec '\
	LB_IP=$(kubectl get svc -n istio-system istio-ingressgateway -ojsonpath="{.status.loadBalancer.ingress[0].ip}"); \
	curl -H Host:go-webserver.example.com "http://${LB_IP}:80/health"; \
	sleep 2; echo; \
	curl -H Host:go-webserver.example.com "http://${LB_IP}:80/hotels"; \
	sleep 2; echo; \
	curl -H Host:java-webserver.example.com "http://${LB_IP}:80/health"; \
	sleep 2; echo; \
	curl -H Host:java-webserver.example.com "http://${LB_IP}:80/hotels"; \
	'

# Load test the individual applications Go and Java
generate-load-to-specific-service:
	@sh -ec '\
	LB_IP=$(kubectl get svc -n istio-system istio-ingressgateway -ojsonpath="{.status.loadBalancer.ingress[0].ip}"); \
	hey -host go-webserver.example.com -m GET http://${LB_IP}:80/hotels; \
	hey -host java-webserver.example.com -m GET http://${LB_IP}:80/hotels; \
	'

# Configure traffic split between Go and Java apps
setup-traffic-split:
	kubectl create namespace trivago-webserver || true
	kubectl apply -f traffic-split/ --wait=true
	@sleep 3
	@sh -ec '\
	LB_IP=$(kubectl get svc -n istio-system istio-ingressgateway -ojsonpath="{.status.loadBalancer.ingress[0].ip}"); \
	curl -H Host:trivago.example.com "http://${LB_IP}:80/health" -I'

# Generate load test to common endpoint trivago.example.com with backend Go and Java to test traffic split
generate-load-traffic-split:
	@sh -ec '\
	LB_IP=$(kubectl get svc -n istio-system istio-ingressgateway -ojsonpath="{.status.loadBalancer.ingress[0].ip}"); \
	hey -host trivago.example.com -m GET http://${LB_IP}:80/hotels; \
	hey -host trivago.example.com -m GET http://${LB_IP}:80/ready'

#####      #####
##### MAIN #####
#####      #####

# Spinup all the infrastructure from local k8s to monitoring
setup-all-infra: deps setup-kind set-context setup-metallb setup-istio setup-ingress-gateway setup-kiali open-dashboards

# Spinup all the applications configurations from build, push to helm install
setup-all-apps: go-build java-build go-push java-push helm-install-go helm-install-java test-apps generate-load-to-specific-service setup-traffic-split generate-load-traffic-split

#####         #####
##### CLEANUP #####
#####         #####

# Cleanup the installation
setup-delete-all:
	kind delete cluster
	docker stop kind-registry
	docker rm kind-registry
	git checkout metallb/metallb-config.yaml