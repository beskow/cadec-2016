#!/bin/bash 

#  download_k8s.command
#  CoreOS Kubernetes Cluster for OS X
#
#  Created by Rimantas on 01/04/2014.
#  Copyright (c) 2014 Rimantas Mocevicius. All rights reserved.

function pause(){
read -p "$*"
}

rm -f kubectl
rm -f *.tgz

# get latest k8s version
function get_latest_version_number {
 local -r latest_url="https://storage.googleapis.com/kubernetes-release/release/stable.txt"
 curl -Ss ${latest_url}

}

K8S_VERSION=$(get_latest_version_number)

# download latest version of kubectl for OS X
echo "Downloading kubectl $K8S_VERSION for OS X"
curl -k -L https://storage.googleapis.com/kubernetes-release/release/$K8S_VERSION/bin/darwin/amd64/kubectl > kubectl
chmod a+x kubectl

# download latest version of k8s binaries for CoreOS
# master
bins=( kubectl kube-apiserver kube-scheduler kube-controller-manager )
for b in "${bins[@]}"; do
    curl -k -L https://storage.googleapis.com/kubernetes-release/release/$K8S_VERSION/bin/linux/amd64/$b > master/$b
done
chmod a+x master/*
tar czvf master.tgz -C master .
rm -f ./master/*

# nodes
bins=( kubectl kubelet kube-proxy )
for b in "${bins[@]}"; do
    curl -k -L https://storage.googleapis.com/kubernetes-release/release/$K8S_VERSION/bin/linux/amd64/$b > nodes/$b
done
chmod a+x nodes/*
tar czvf nodes.tgz -C nodes .
rm -f ./nodes/*

#
echo "Download has finished !!!"
pause 'Press [Enter] key to continue...'
