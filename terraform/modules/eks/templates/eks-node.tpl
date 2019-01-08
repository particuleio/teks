#!/bin/bash
set -o xtrace
/etc/eks/bootstrap.sh --apiserver-endpoint '${apiserver_endpoint}' --b64-cluster-ca '${b64_cluster_ca}' '${cluster_name}' ${kubelet_extra_args}
