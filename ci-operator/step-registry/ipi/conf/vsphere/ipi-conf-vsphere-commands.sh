#!/bin/bash

set -o nounset
set -o errexit
set -o pipefail

CONFIG="${SHARED_DIR}/install-config.yaml"
TFVARS_PATH=/var/run/secrets/ci.openshift.io/cluster-profile/vmc.secret.auto.tfvars
vsphere_user=$(grep -oP 'vsphere_user\s*=\s*"\K[^"]+' ${TFVARS_PATH})
vsphere_password=$(grep -oP 'vsphere_password\s*=\s*"\K[^"]+' ${TFVARS_PATH})
base_domain=$(<"${SHARED_DIR}"/basedomain.txt)

declare -a vips
mapfile -t vips < "${SHARED_DIR}/vips.txt"

cat >> "${CONFIG}" << EOF
baseDomain: $base_domain
controlPlane:
  name: "master"
  replicas: 3
  platform:
    vsphere:
      osDisk:
        diskSizeGB: 120
compute:
- name: "worker"
  replicas: 3
  platform:
    vsphere:
      cpus: 4
      coresPerSocket: 1
      memoryMB: 16384
      osDisk:
        diskSizeGB: 120
platform:
  vsphere:
    vcenter: "vcenter.sddc-35-155-70-129.vmwarevmc.com"
    datacenter: SDDC-Datacenter
    defaultDatastore: WorkloadDatastore
    cluster: "Cluster-1"
    network: "ci-segment"
    password: ${vsphere_password}
    username: ${vsphere_user}
    apiVIP: "${vips[0]}"
    ingressVIP: "${vips[1]}"
EOF
