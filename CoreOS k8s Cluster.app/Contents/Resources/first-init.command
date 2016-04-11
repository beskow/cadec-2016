#!/bin/bash

#  first-init.command
#  CoreOS Kubernetes Cluster for OS X
#
#  Created by Rimantas on 01/04/2014.
#  Copyright (c) 2014 Rimantas Mocevicius. All rights reserved.

# get App's Resources folder
res_folder=$(cat ~/coreos-k8s-cluster/.env/resouces_path)

echo " "
echo Installing Kubernetes cluster...
echo " "
# install vagrant scp plugin
vagrant plugin install vagrant-scp

### getting files from github and setting them up
echo ""
echo "Downloading latest coreos-vagrant files from github to tmp folder: "
git clone https://github.com/coreos/coreos-vagrant.git ~/coreos-k8s-cluster/tmp
echo "Done downloading from github !!!"
echo ""

# copy Vagrantfile
cp ~/coreos-k8s-cluster/tmp/Vagrantfile ~/coreos-k8s-cluster/control/Vagrantfile
cp ~/coreos-k8s-cluster/tmp/Vagrantfile ~/coreos-k8s-cluster/workers/Vagrantfile

# change control IP to static
sed -i "" 's/172.17.8.#{i+100}/172.17.15.101/g' ~/coreos-k8s-cluster/control/Vagrantfile
# change nodes network subnet and IP to start from
sed -i "" 's/172.17.8.#{i+100}/172.17.15.#{i+101}/g' ~/coreos-k8s-cluster/workers/Vagrantfile

# config.rb files
# control
cp ~/coreos-k8s-cluster/tmp/config.rb.sample ~/coreos-k8s-cluster/control/config.rb
sed -i "" 's/#$instance_name_prefix="core"/$instance_name_prefix="k8smaster"/' ~/coreos-k8s-cluster/control/config.rb
sed -i "" 's/#$vm_memory = 1024/$vm_memory = 512/' ~/coreos-k8s-cluster/control/config.rb
sed -i "" 's/File.open/#File.open/' ~/coreos-k8s-cluster/control/config.rb
# nodes
cp ~/coreos-k8s-cluster/tmp/config.rb.sample ~/coreos-k8s-cluster/workers/config.rb
sed -i "" 's/#$instance_name_prefix="core"/$instance_name_prefix="k8snode"/' ~/coreos-k8s-cluster/workers/config.rb
sed -i "" 's/File.open/#File.open/' ~/coreos-k8s-cluster/workers/config.rb
# set nodes to 2
sed -i "" 's/[#]*$num_instances=1/$num_instances=2/' ~/coreos-k8s-cluster/workers/config.rb


###

### Set release channel
LOOP=1
while [ $LOOP -gt 0 ]
do
    VALID_MAIN=0
    echo "Set CoreOS Release Channel:"
    echo " 1)  Alpha "
    echo " 2)  Beta "
    echo " 3)  Stable "
    echo "Select an option:"

    read RESPONSE
    XX=${RESPONSE:=Y}

    if [ $RESPONSE = 1 ]
    then
        VALID_MAIN=1
        sed -i "" 's/#$update_channel/$update_channel/' ~/coreos-k8s-cluster/control/config.rb
        sed -i "" "s/channel='stable'/channel='alpha'/" ~/coreos-k8s-cluster/control/config.rb
        sed -i "" "s/channel='beta'/channel='alpha'/" ~/coreos-k8s-cluster/control/config.rb
        #
        sed -i "" 's/#$update_channel/$update_channel/' ~/coreos-k8s-cluster/workers/config.rb
        sed -i "" "s/channel='stable'/channel='alpha'/" ~/coreos-k8s-cluster/workers/config.rb
        sed -i "" "s/channel='beta'/channel='alpha'/" ~/coreos-k8s-cluster/workers/config.rb
        channel="Alpha"
        LOOP=0
    fi

    if [ $RESPONSE = 2 ]
    then
        VALID_MAIN=1
        sed -i "" 's/#$update_channel/$update_channel/' ~/coreos-k8s-cluster/control/config.rb
        sed -i "" "s/channel='alpha'/channel='beta'/" ~/coreos-k8s-cluster/control/config.rb
        sed -i "" "s/channel='stable'/channel='beta'/" ~/coreos-k8s-cluster/control/config.rb
        #
        sed -i "" 's/#$update_channel/$update_channel/' ~/coreos-k8s-cluster/workers/config.rb
        sed -i "" "s/channel='alpha'/channel='beta'/" ~/coreos-k8s-cluster/workers/config.rb
        sed -i "" "s/channel='stable'/channel='beta'/" ~/coreos-k8s-cluster/workers/config.rb
        channel="Beta"
        LOOP=0
    fi

    if [ $RESPONSE = 3 ]
    then
        VALID_MAIN=1
        sed -i "" 's/#$update_channel/$update_channel/' ~/coreos-k8s-cluster/control/config.rb
        sed -i "" "s/channel='alpha'/channel='stable'/" ~/coreos-k8s-cluster/control/config.rb
        sed -i "" "s/channel='beta'/channel='stable'/" ~/coreos-k8s-cluster/control/config.rb
        #
        sed -i "" 's/#$update_channel/$update_channel/' ~/coreos-k8s-cluster/workers/config.rb
        sed -i "" "s/channel='alpha'/channel='stable'/" ~/coreos-k8s-cluster/workers/config.rb
        sed -i "" "s/channel='beta'/channel='stable'/" ~/coreos-k8s-cluster/workers/config.rb
        channel="Stable"
        LOOP=0
    fi

    if [ $VALID_MAIN != 1 ]
    then
        continue
    fi
done
### Set release channel

#
function pause(){
read -p "$*"
}

# first up to initialise VMs
echo " "
echo "Setting up Vagrant VMs for CoreOS + Kubernetes Cluster on OS X"
cd ~/coreos-k8s-cluster/control
vagrant box update
vagrant up --provider virtualbox
#
cd ~/coreos-k8s-cluster/workers
vagrant up --provider virtualbox

# Add vagrant ssh key to ssh-agent
ssh-add ~/.vagrant.d/insecure_private_key >/dev/null 2>&1

echo " "
echo "Installing k8s files to master and nodes:"
cd ~/coreos-k8s-cluster/control
vagrant scp master.tgz k8smaster-01:/home/core/
vagrant ssh k8smaster-01 -c "sudo /usr/bin/mkdir -p /opt/bin && sudo tar xzf /home/core/master.tgz -C /opt/bin && sudo chmod 755 /opt/bin/* " >/dev/null 2>&1
#
cd ~/coreos-k8s-cluster/workers
vagrant scp nodes.tgz k8snode-01:/home/core/
vagrant scp nodes.tgz k8snode-02:/home/core/
#
vagrant ssh k8snode-01 -c "sudo /usr/bin/mkdir -p /opt/bin && sudo tar xzf /home/core/nodes.tgz -C /opt/bin && sudo chmod 755 /opt/bin/* " >/dev/null 2>&1
vagrant ssh k8snode-02 -c "sudo /usr/bin/mkdir -p /opt/bin && sudo tar xzf /home/core/nodes.tgz -C /opt/bin && sudo chmod 755 /opt/bin/* " >/dev/null 2>&1
echo "Done installing ... "
echo " "

# copy bundled versions of etcdctl and fleetctl to ~/coreos-k8s-cluster/bin
cp -f "${res_folder}"/etcdctl ~/coreos-k8s-cluster/bin
cp -f "${res_folder}"/fleetctl ~/coreos-k8s-cluster/bin

# update etcdctl and fleetctl, if necessary

cd ~/coreos-k8s-cluster/control
ETCDCTL_VERSION=$(vagrant ssh k8smaster-01 -c "etcdctl --version" | cut -d " " -f 3- | tr -d '\r' )
FILE=etcdctl
cd ~/coreos-k8s-cluster/bin
echo "Downloading etcdctl v$ETCDCTL_VERSION for OS X"
curl -L -o etcd.zip "https://github.com/coreos/etcd/releases/download/v$ETCDCTL_VERSION/etcd-v$ETCDCTL_VERSION-darwin-amd64.zip"
unzip -j -o "etcd.zip" "etcd-v$ETCDCTL_VERSION-darwin-amd64/etcdctl" > /dev/null 2>&1
rm -f etcd.zip

cd ~/coreos-k8s-cluster/control
FLEETCTL_VERSION=$(vagrant ssh k8smaster-01 -c 'fleetctl version' | cut -d " " -f 3- | tr -d '\r')
FILE=fleetctl
if [ ! -f ~/coreos-k8s-cluster/bin/$FILE ]; then
    cd ~/coreos-k8s-cluster/bin
    echo "Downloading fleetctl v$FLEETCTL_VERSION for OS X"
    curl -L -o fleet.zip "https://github.com/coreos/fleet/releases/download/v$FLEETCTL_VERSION/fleet-v$FLEETCTL_VERSION-darwin-amd64.zip"
    unzip -j -o "fleet.zip" "fleet-v$FLEETCTL_VERSION-darwin-amd64/fleetctl" > /dev/null 2>&1
    rm -f fleet.zip
else
    # we check the version of the binary
    INSTALLED_VERSION=$(~/coreos-k8s-cluster/bin/$FILE --version | awk '{print $3}' | tr -d '\r')
    MATCH=$(echo "${INSTALLED_VERSION}" | grep -c "${FLEETCTL_VERSION}")
    if [ $MATCH -eq 0 ]; then
        # the version is different
        cd ~/coreos-k8s-cluster/bin
        echo "Downloading fleetctl v$FLEETCTL_VERSION for OS X"
        curl -L -o fleet.zip "https://github.com/coreos/fleet/releases/download/v$FLEETCTL_VERSION/fleet-v$FLEETCTL_VERSION-darwin-amd64.zip"
        unzip -j -o "fleet.zip" "fleet-v$FLEETCTL_VERSION-darwin-amd64/fleetctl" > /dev/null 2>&1
        rm -f fleet.zip
    else
        echo " "
        echo "fleetctl is up to date ..."
        echo " "
    fi
fi

# get lastest OS X helm version from bintray
cd ~/coreos-k8s-cluster/bin
# curl -s https://get.helm.sh | bash > /dev/null 2>&1
bin_version=$(curl -sI https://bintray.com/deis/helm/helm/_latestVersion | grep "Location:" | sed -n 's%.*helm/%%;s%/view.*%%p')
echo "Downloading latest version of helm for OS X"
curl -L "https://dl.bintray.com/deis/helm/helm-$bin_version-darwin-amd64.zip" -o helm.zip
unzip -o helm.zip > /dev/null 2>&1
rm -f helm.zip
echo " "
echo "Installed latest helm $bin_version to ~/coreos-k8s-cluster/bin ..."

# set etcd endpoint
export ETCDCTL_PEERS=http://172.17.15.101:2379
#echo "etcd cluster:"
#~/coreos-k8s-cluster/bin/etcdctl ls /
#echo " "

# set fleetctl tunnel
export FLEETCTL_TUNNEL=
export FLEETCTL_ENDPOINT=http://172.17.15.101:2379
export FLEETCTL_DRIVER=etcd
export FLEETCTL_STRICT_HOST_KEY_CHECKING=false
echo "fleetctl list-machines:"
~/coreos-k8s-cluster/bin/fleetctl list-machines
echo " "
#
echo "Installing fleet units from '~/coreos-k8s-cluster/fleet' folder:"
cd ~/coreos-k8s-cluster/fleet
~/coreos-k8s-cluster/bin/fleetctl submit *.service
~/coreos-k8s-cluster/bin/fleetctl start *.service
echo "Finished installing fleet units"
~/coreos-k8s-cluster/bin/fleetctl list-units
echo " "

# generate kubeconfig file
~/coreos-k8s-cluster/bin/gen_kubeconfig 172.17.15.101
#

# set kubernetes master
export KUBERNETES_MASTER=http://172.17.15.101:8080
echo Waiting for Kubernetes cluster to be ready. This can take a few minutes...
spin='-\|/'
i=0
until ~/coreos-k8s-cluster/bin/kubectl version 2>/dev/null | grep 'Server Version' >/dev/null 2>&1; do i=$(( (i+1) %4 )); printf "\r${spin:$i:1}"; sleep .1; done
i=0
until ~/coreos-k8s-cluster/bin/kubectl get nodes 2>/dev/null | grep '172.17.15.102' | grep 'Ready' >/dev/null 2>&1; do i=$(( (i+1) %4 )); printf "\r${spin:$i:1}"; sleep .1; done
i=0
until ~/coreos-k8s-cluster/bin/kubectl get nodes 2>/dev/null | grep '172.17.15.103' | grep 'Ready' >/dev/null 2>&1; do i=$(( (i+1) %4 )); printf "\r${spin:$i:1}"; sleep .1; done

# attach label to the nodes
echo " "
~/coreos-k8s-cluster/bin/kubectl label nodes 172.17.15.102 node=worker1
~/coreos-k8s-cluster/bin/kubectl label nodes 172.17.15.103 node=worker2
#
echo " "
echo "Creating kube-system namespace ..."
~/coreos-k8s-cluster/bin/kubectl create -f ~/coreos-k8s-cluster/kubernetes/kube-system-ns.yaml
#
echo " "
echo "Installing SkyDNS ..."
~/coreos-k8s-cluster/bin/kubectl create -f ~/coreos-k8s-cluster/kubernetes/skydns-rc.yaml
~/coreos-k8s-cluster/bin/kubectl create -f ~/coreos-k8s-cluster/kubernetes/skydns-svc.yaml
#
echo " "
echo "Installing Kubernetes UI ..."
~/coreos-k8s-cluster/bin/kubectl create -f ~/coreos-k8s-cluster/kubernetes/dashboard-controller.yaml
~/coreos-k8s-cluster/bin/kubectl create -f ~/coreos-k8s-cluster/kubernetes/dashboard-service.yaml
# clean up kubernetes folder
rm -f ~/coreos-k8s-cluster/kubernetes/kube-system-ns.yaml
rm -f ~/coreos-k8s-cluster/kubernetes/skydns-rc.yaml
rm -f ~/coreos-k8s-cluster/kubernetes/skydns-svc.yaml
rm -f ~/coreos-k8s-cluster/kubernetes/dashboard-controller.yaml
rm -f ~/coreos-k8s-cluster/kubernetes/dashboard-service.yaml

#
echo " "
echo "kubectl get nodes:"
~/coreos-k8s-cluster/bin/kubectl get nodes
echo " "

#
echo " "
echo "Installation has finished, CoreOS VMs are up and running !!!"
echo "Enjoy CoreOS+Kubernetes Cluster on your Mac !!!"
echo " "
echo "Run from menu 'OS Shell' to open a terninal window with fleetctl, etcdctl and kubectl preset to master's IP!!!"
echo " "
pause 'Press [Enter] key to continue...'
