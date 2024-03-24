# Prerequisites
To install the dependencies to install just, run `make`.  
Now with `Just` installed on your system, all the tools you will need to have installed on your local machine are provided in the `justfile` with the `deps` command

# To setup all the local tools, kubernetes stack and once with monitoring
Run `just setup-all-infra`

# To setup the apps with all the configurations
Run `just setup-all-apps`

# Just documentation
```
$ just
Available recipes:
    default               # Helper/List all the available commands and their description
    deps                  # Install all the tools you will need to setup the project
    generate-load         # Load test the applications
    go-build              # Build the Go app
    go-push               # Docker tag and push the Go app to the local registry
    helm-install-go       # Install the Go app using Helm
    helm-install-java     # Install the Java app using Helm
    java-build            # Build the Java app
    java-push             # Docker tag and push the Java app to the local registry
    set-context           # Set the current kubernetes context to the kind cluster
    setup-all-apps        # Spinup all the applications configurations from build, push to helm install
    setup-all-infra       # Spinup all the infrastructure from local k8s to monitoring
    setup-ingress-gateway # Install the istio ingress gateway
    setup-istio           # Install istio CRDs and istiod -- control plane
    setup-kiali           # Configure Kiali, Prometheus, Grafana, Tracing (Jaeger)
    setup-kind            # Create local kubernetes cluster with KinD
    setup-metallb         # Configure metallb to have an loadbalancer on the cluster and expose services to the host machine
```

# Result
After running the apps and starting the `generate-load-traffic-split` this is the expected result to be seen on Kiali
![traffic-split](images/traffic-split.png)
![go-app](images/go.png)
![java-app](images/java.png)

# Additional notes
I usually install every dev tool with `asdf`, it makes my environment pretty easy to replicate and I don't need to think too much on how to install a new tool, if an asdf plugin is not available for the tool I'm installing then I will follow the tool documentation on how to install it. This allow me to easily switch between different version of the tools too.

I had trouble with K3d and could not get it working quickly, I was starting to spend to much time troubleshooting here so I decided to use another tool I already knew: [kind](https://github.com/kubernetes-sigs/kind). Later I realized the problems were related with the old machine I was running the setup and their lack of cgroups v2.

I could have installed istio with `istioctl` binary but to keep the standard of deploying everything with Helm I configured: `just setup-istio`.

For a production system I believe all the commands could be improved to be more idempotent so I could check if some tool was already installed or not before trying to install, I could install a specific version instead of just relying on latests, check for errors and perform retry if the installation failed for some reason at some point, all that would be nice for a more mature setup.