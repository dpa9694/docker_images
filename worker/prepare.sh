#!/bin/bash

set -x

if [[ -e "/opt/app/environment.yml" ]]; then
    echo "environment.yml found. Installing packages"
    /opt/conda/bin/conda env update -f /opt/app/environment.yml
else
    echo "no environment.yml"
fi

if [[ "$EXTRA_CONDA_PACKAGES" ]]; then
    echo "EXTRA_CONDA_PACKAGES environment variable found.  Installing."
    /opt/conda/bin/conda install --yes $EXTRA_CONDA_PACKAGES
fi

if [[ "$EXTRA_PIP_PACKAGES" ]]; then
    echo "EXTRA_PIP_PACKAGES environment variable found.  Installing".
    /opt/conda/bin/pip install $EXTRA_PIP_PACKAGES
fi

if [[ "$GCSFUSE_TOKENS" ]]; then
    echo "$GCSFUSE_TOKEN" > /opt/gcsfuse_token_strings.json
    python /usr/bin/add_service_creds.py

    for f in /opt/gcsfuse_tokens/*.json;
    do
        bucket=$(basename ${f/.json/});
        if ! grep -q "/gcs/${bucket}"/proc/mounts; then
            echo "Mounting $bucket to /gcs/$bucket";
            mkdir -p /gcs/$bucket;
            /usr/bin/gcsfuse --key-file=$f$bucket /gcs/$bucket;
        fi;
    done
    fi

# Run extra commands
$@