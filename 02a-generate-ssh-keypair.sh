#!/usr/bin/env bash
# This generates SSH key pair to enable
# passwordless SSH to k8s master node

source .env

if [ ! -f $KEYFILENAME ]; then
    echo $KEYFILENAME does not exist.
    cat /dev/zero | ssh-keygen -t ${ENCRYPTION_TYPE} -b ${KEYBITS} -q -N "" > /dev/null
    echo "New public key: " && cat ~/.ssh/${KEYNAME}.pub
else
    echo "Key pair [ ${KEYNAME} ] exists."
    cat $KEYFILENAME.pub
fi
