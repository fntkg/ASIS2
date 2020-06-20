#!/bin/bash
set -e

export NODE_1="192.168.56.2"
export NODE_2="192.168.56.3"
export NODE_3="192.168.56.4"
export USER=root

# The first server starts the cluster
k3sup install \
  --cluster \
  --user $USER \
  --ip $NODE_1

# The second node joins
k3sup join \
  --server \
  --ip $NODE_2 \
  --user $USER \
  --server-user $USER \
  --server-ip $NODE_1

# The third node joins
k3sup join \
  --server \
  --ip $NODE_3 \
  --user $USER \
  --server-user $USER \
  --server-ip $NODE_1