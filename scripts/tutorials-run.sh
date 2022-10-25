#!/bin/bash

# run tutorials
docker run \
    --name shaarpec-tutorials \
    --user root \
    -e OIDCISH_CLIENT_ID="${SHAARPEC_CLIENT_ID}" \
    -e OIDCISH_CLIENT_SECRET="${SHAARPEC_CLIENT_SECRET}" \
    -e OIDCISH_AUDIENCE=shaarpec_api.full_access_scope \
    -e OIDCISH_SCOPE="openid shaarpec_api.full_access_scope offline_access" \
    -e GRANT_SUDO=yes \
    -v $(CURDIR)/tutorials:/home/jovyan/tutorials \
    -w /home/jovyan/tutorials \
    -p 8888:8888 \
    -d shaarpec-tutorials \
    start.sh jupyter lab --LabApp.token=''
