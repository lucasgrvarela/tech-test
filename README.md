# Notes
To install the dependencies to install just, run `make`. Now with `Just` installed on your system, all the tools you will need to have installed on your local machine are already provided in the `justfile` with the `deps` command

I usually install every dev tool with `asdf`, it makes my environment pretty easy to replicate and I don't need to think too much on how to install a new tool, if an asdf plugin is not available for the tool I'm installing then I will follow the tool documentation on how to install it

# Kubernetes with Kind tool
I had trouble with K3d and could not get it working quickly, I was starting to spend to much time troubleshooting here so I decided to use another tool I already knew: [kind](https://github.com/kubernetes-sigs/kind)

# Ingress and Traffic Split: Istio
I could have installed istio with `istioctl` binary but to keep the standard of deploying everything with Helm I configured: `just setup-istio`

# To setup all the k8s stack at once with monitoring
Run `just setup-all`

### PENDING: 
- fix DestinationRule and VirtualService for Java and Go
- create helm for DestinationRule and Virtual Service
- spin up prometheus+grafana with helm