# Notes
To install the dependencies to install just, run `make`. Now with `Just` installed on your system, all the tools you will need to have installed on your local machine are already provided in the `justfile` with the `deps` command

I usually install every dev tool with `asdf`, it makes my environment pretty easy to replicate and I don't need to think too much on how to install a new tool, if an asdf plugin is not available for the tool I'm installing then I will follow the tool documentation on how to install it

# Kubernetes with Kind tool
I had trouble with K3d and could not get it working quickly, I was starting to spend to much time troubleshooting here so I decided to use another tool I already knew: [kind](https://github.com/kubernetes-sigs/kind) "Kubernetes IN Docker: local clusters for testing Kubernetes", created and maintaned by kubernetes-sigs

Cgroups was on v1 instead of v2 on my host as I'm using rootless docker setup I had to configure my host following the doc: https://kind.sigs.k8s.io/docs/user/rootless/#host-requirements

# Ingress and Traffic Split: Istio
I could have installed istio with `istioctl install --set profile=demo -y` but to keep the standard of deploying everything with Helm run: `just setup-istio`

# Prometheus
To install Prometheus with Helm run: `just setup-prometheus`

# To setup all the tools at once
Run `just setup-all`

### PENDING: 
- create kind local registry: https://kind.sigs.k8s.io/docs/user/local-registry/
- push images to local registry: justfile
- spin up istio Ingress Gateway with helm: https://istio.io/latest/docs/setup/platform-setup/kind/#setup-metallb-for-kind
- spin up prometheus+grafana with helm