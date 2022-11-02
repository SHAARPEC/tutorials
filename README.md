# Welcome to SHAARPEC

## TL;DR

Install git and Docker. Clone this repo. Set the environment variables for the client id (SHAARPEC_CLIENT_ID) and the client secret (SHAARPEC_CLIENT_SECRET) in your environment.

Create the tutorial notebooks:

```bash
make setup
```

Start a jupyterlab server with the notebooks:

```bash
make run
```

Go to http://localhost:8888 and run the tutorials.

## What is SHAARPEC?

SHAARPEC is an analytics platform for healthcare data that supports:

-   Resource and cost calculations (based on encounters and patient encounter costing).
-   Analytics over cohesive patient trajectories (cross-silo analysis).
-   Definition and analysis over complex patient cohorts (dynamic cohort filters).
-   Rule-based compliance calculations (implementation of clinical prediction rules for estimating risks).

The results of these analyses are available via a [REST API](https://restfulapi.net), and can be used for post-processing with any BI/analytics tool (e.g., Tableau, Power BI, Qlikview). The REST API documentation is interactive and can be used to test all the endpoints. There is a demo instance of SHAARPEC running [here](https://platform-demo.shaarpec.com). Once you have an account, you can go there to browse the API.

Some re-occuring analyses have also been collected in a frontend application as a number of predetermined frontend views. They are meant to be used by no-code stakeholders such managers etc. to monitor the current state of the data in the organization. There is a demo instance of the SHAARPEC frontend running [here](https://platform-demo.shaarpec.com). Once you have an account, you can go there and check out the views.

Note: The SHAARPEC demo instances contain only artificial data, created with the [Synthea](https://synthetichealth.github.io/synthea) tool, and are not restricted by GDPR or the Swedish Patient Data Law.

## How to run the tutorials

This repo contains a number of SHAARPEC tutorials to get you started with the platform, in the form of [Jupyter notebooks](https://jupyter.org). They are most easily run and packaged with [Docker](https://www.docker.com). To run the tutorials:

1. Install Docker on your computer by following the above link.

2. Clone the repo.

3. Set the environment variables for the client id (SHAARPEC_CLIENT_ID) and the client secret (SHAARPEC_CLIENT_SECRET) in your environment.

4. Setup the tutorials by creating the notebooks. Use one of these methods from the root folder of the repo, listed in order of simplicity:

    a. In bash using `make`:

    ```bash
    make setup
    ```

    b. In bash without `make`:

    ```bash
    ./scripts/tutorials-setup.sh
    ```

    c. No bash

    ```bash
    > docker build -f Dockerfile -t shaarpec-tutorials .
    > docker run --rm --name shaarpec-setup-tutorials -v $(pwd)/src:/tmp/src shaarpec-tutorials jupytext --to ipynb --update-metadata '{"jupytext":null}' /tmp/src/*.md
    ```

    Move `scripts/*.ipynb` and `scripts/*.json` to tutorials folder.

5. Run the tutorials as a Docker image. Use one of these methods, listed in order of simplicity.

    a. In bash using `make`:

    ```bash
    make run
    ```

    You can later use `make stop` or `make kill` to stop the Docker image if you want.

    b. In bash without `make`:

    ```bash
    ./scripts/tutorials-run.sh
    ```

    c. No bash

    ```bash
    > docker run --name shaarpec-tutorials --user root -e OIDCISH_CLIENT_ID="${SHAARPEC_CLIENT_ID}" -e OIDCISH_CLIENT_SECRET="${SHAARPEC_CLIENT_SECRET}" -e OIDCISH_AUDIENCE=shaarpec_api.full_access_scope -e OIDCISH_SCOPE="openid shaarpec_api.full_access_scope offline_access" -e GRANT_SUDO=yes -v $(CURDIR)/tutorials:/home/jovyan/tutorials -w /home/jovyan/tutorials -p 8888:8888 -d shaarpec-tutorials start.sh jupyter lab --LabApp.token=''
    ```

6. Visit the jupyter server at http://localhost:8888 to go through the tutorials.

Note: You can also launch the Jupyter notebooks manually without Docker but that is outside the scope of this documentation.

## Tutorials

| Number | Title                                         | Content                                                      |
| ------ | --------------------------------------------- | ------------------------------------------------------------ |
| 000    | Accessing data via the SHAARPEC Analytics API | Authenticating with the API and extracting data.             |
| 010    | Introduction to Population Health             | Defining cohorts and analyzing populations in Python.        |
| 020    | Patient Encounter Costing (PEC)               | Perform PEC analysis over cost groups and cohorts.           |
| 030    | Rule-based compliance analysis                | Calculate risk prediction via scoring systems (Chads2Vasc2). |
| 040    | Patient trajectory analysis                   | Extract and visualize a full patient trajectory.             |
