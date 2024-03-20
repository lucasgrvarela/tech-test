# Prerequisites
```
# git
$ sudo apt install git -y

# asdf
$ [ -d ~/.asdf ] && echo "asdf exists" || git clone https://github.com/asdf-vm/asdf.git ~/.asdf --branch v0.13.0
$ echo -e "\nsource ~/.asdf/asdf.sh" >> ~/.bashrc

# just
$ asdf plugin add just && asdf install just latest && asdf global just latest
```

With `Just` installed on your system, all the tools you will need to have installed on your local machine are already provided on the `justfile` with the `deps` command

# Kubernetes (Kind)
I had trouble with K3d and could not get it working quickly, I was starting to spend to much time troubleshooting here so I decided to use another tool I already knew: _kind_  
Cgroups was on v1 instead of v2 on my host as I'm using rootless docker setup I had to configure my host following the doc: https://kind.sigs.k8s.io/docs/user/rootless/#host-requirements

# Ingress and Traffic Split: Istio
```
$ helm repo add istio https://istio-release.storage.googleapis.com/charts
$ helm repo update
$ helm install <release> <chart> --namespace <namespace> --create-namespace [--set <other_parameters>]
```

# Prometheus
```
$ helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
$ helm repo update
$ helm install prometheus-community/prometheus --generate-name


NAME: prometheus-1710887676
LAST DEPLOYED: Tue Mar 19 19:34:38 2024
NAMESPACE: default
STATUS: deployed
REVISION: 1
TEST SUITE: None
NOTES:
The Prometheus server can be accessed via port 80 on the following DNS name from within your cluster:
prometheus-1710887676-server.default.svc.cluster.local


Get the Prometheus server URL by running these commands in the same shell:
  export POD_NAME=$(kubectl get pods --namespace default -l "app.kubernetes.io/name=prometheus,app.kubernetes.io/instance=prometheus-1710887676" -o jsonpath="{.items[0].metadata.name}")
  kubectl --namespace default port-forward $POD_NAME 9090


The Prometheus alertmanager can be accessed via port 9093 on the following DNS name from within your cluster:
prometheus-1710887676-alertmanager.default.svc.cluster.local


Get the Alertmanager URL by running these commands in the same shell:
  export POD_NAME=$(kubectl get pods --namespace default -l "app.kubernetes.io/name=alertmanager,app.kubernetes.io/instance=prometheus-1710887676" -o jsonpath="{.items[0].metadata.name}")
  kubectl --namespace default port-forward $POD_NAME 9093
#################################################################################
######   WARNING: Pod Security Policy has been disabled by default since    #####
######            it deprecated after k8s 1.25+. use                        #####
######            (index .Values "prometheus-node-exporter" "rbac"          #####
###### .          "pspEnabled") with (index .Values                         #####
######            "prometheus-node-exporter" "rbac" "pspAnnotations")       #####
######            in case you still need it.                                #####
#################################################################################


The Prometheus PushGateway can be accessed via port 9091 on the following DNS name from within your cluster:
prometheus-1710887676-prometheus-pushgateway.default.svc.cluster.local


Get the PushGateway URL by running these commands in the same shell:
  export POD_NAME=$(kubectl get pods --namespace default -l "app=prometheus-pushgateway,component=pushgateway" -o jsonpath="{.items[0].metadata.name}")
  kubectl --namespace default port-forward $POD_NAME 9091

For more information on running Prometheus, visit:
https://prometheus.io/
```
