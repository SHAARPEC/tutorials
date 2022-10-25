FROM jupyter/minimal-notebook:python-3.10

RUN rm -rf /home/jovyan/work
RUN mkdir /home/jovyan/tutorials

USER root
RUN apt-get update && apt-get install -y emacs
USER jovyan

COPY --chown=${NB_UID}:${NB_GID} requirements.txt /tmp

RUN pip install -r /tmp/requirements.txt

COPY overrides.json /opt/conda/share/jupyter/lab/settings/overrides.json
