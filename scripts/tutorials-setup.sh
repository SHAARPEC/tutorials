#!/bin/bash

# build docker image
docker build \
    -f Dockerfile \
    -t shaarpec-tutorials .

# setup tutorials
docker run \
    --rm \
    --name shaarpec-setup-tutorials \
    -v $(pwd)/src:/tmp/src \
    shaarpec-tutorials jupytext --to ipynb --update-metadata '{"jupytext":null}' /tmp/src/*.md \
    && mv src/*.ipynb src/*.json tutorials/
