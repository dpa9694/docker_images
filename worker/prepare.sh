#!/bin/bash

set -x

if [[ "$EXTRA_CONDA_PACKAGES" ]]; then
    echo "EXTRA_CONDA_PACKAGES environment variable found.  Installing."
    /opt/conda/bin/conda install --yes $EXTRA_CONDA_PACKAGES
fi

if [[ "$EXTRA_PIP_PACKAGES" ]]; then
    echo "EXTRA_PIP_PACKAGES environment variable found.  Installing".
    /opt/conda/bin/pip install $EXTRA_PIP_PACKAGES
fi

if [[ "$GCSFUSE_TOKENS" ]]; then
    echo "$GCSFUSE_TOKENS" > /opt/gcsfuse_token_strings.json;

    mkdir -p /opt/gcsfuse_tokens/;

    python /usr/bin/add_service_creds.py;

    for f in /opt/gcsfuse_tokens/*.json;
    do
        bucket=$(basename ${f/.json/});
        if ! grep -q "/gcs/${bucket}" /proc/mounts; then
            echo "Mounting $bucket to /gcs/$bucket";
            mkdir -p "/gcs/${bucket}";
            /usr/bin/gcsfuse --key-file="$f" "${bucket}" "/gcs/${bucket}";
        fi;
    done
fi

if [[ "$SQL_TOKEN" ]]; then
    if [[ "$SQL_INSTANCE" ]]; then
        echo "Starting SQL proxy connection to $SQL_INSTANCE";
        echo "$SQL_TOKEN" > /opt/sql_token_string.json;
        /usr/bin/cloud_sql_proxy -instances=$SQL_INSTANCE -credential_file=/opt/sql_token_string.json &
    fi;
fi

if [[ "$GOOGLE_APPLICATION_CREDENTIALS" ]]; then
    gcloud auth activate-service-account --key-file $GOOGLE_APPLICATION_CREDENTIALS;
fi

# Run extra commands
$@
