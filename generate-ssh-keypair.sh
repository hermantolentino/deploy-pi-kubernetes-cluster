#!/usr/bin/env bash
# This generates SSH key pair to enable
# passwordless sudo to k8s master node

source .env

if [ ! -f $KEYFILENAME ]; then
    echo $KEYFILENAME does not exist.
else
    echo "Key pair [ ${KEYNAME} ] exists."
    cat $KEYFILENAME
    rm $KEYFILENAME && echo "$KEYFILENAME deleted."
    rm ${KEYFILENAME}.pub && echo "${KEYFILENAME}.pub deleted."
fi
cat /dev/zero | ssh-keygen -t rsa -q -N "" > /dev/null
echo "public key: " && cat ~/.ssh/id_rsa.pub
