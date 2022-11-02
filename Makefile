SHELL=/bin/bash

.PHONY: build setup run restart stop clean kill check-client-id check-client-secret

build:	
		docker build \
            -f Dockerfile \
            -t shaarpec-tutorials .

setup:	build
		docker run \
			--rm \
			--name shaarpec-setup-tutorials \
			-v $(CURDIR)/src:/tmp/src \
			shaarpec-tutorials jupytext --to ipynb --update-metadata '{"jupytext":null}' /tmp/src/*.md \
			&& mv src/*.ipynb tutorials/ && cp src/style.json tutorials

run:	build check-client-id check-client-secret
		@docker run \
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
			start.sh jupyter lab \
				--LabApp.token='' \
				--ServerApp.iopub_data_rate_limit=1.0e10 \
				|| { echo "Failed to start tutorials!"; exit 1; }
		@echo "Tutorials started at http://localhost:8888!"

restart:	
		docker restart shaarpec-tutorials

stop:	
		docker stop shaarpec-tutorials

clean:	
		docker rm shaarpec-tutorials

kill:	stop clean

check-client-id:
ifndef SHAARPEC_CLIENT_ID
	$(error Please set the SHAARPEC_CLIENT_ID environment variable)
endif

check-client-secret:
ifndef SHAARPEC_CLIENT_SECRET
	$(error Please set the SHAARPEC_CLIENT_SECRET environment variable)
endif
