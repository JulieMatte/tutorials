
Docker workflow for deploying images.

Install Docker
--------------

Install docker on a linux machine.

```bash
# install docker
curl -fsSL https://get.docker.com/ | sh

# init the docker deamon
sudo systemctl start docker
#sudo dockerd # alternative method

# verify the deamon is running
sudo systemctl status docker

# enable docker at every server reboot
sudo systemctl enable docker

# [optional] to avoid sudo for commands, add user to docker group
sudo usermod -aG docker $(whoami)
sudo systemctl daemon-reload
sudo systemctl restart docker
```


Setup credentials
-----------------

Set up credentials for dockerhub.

```bash
docker login
```

Set up credentials for Google container registry. Note that you may need to request permission from your GCP administrator.

```bash
# see https://cloud.google.com/container-registry/docs/advanced-authentication
gcloud auth configure-docker
```


Make a Docker image from a conda environment
---------------------------------------------

```bash
# set environmental variables
CONDA_ENV="my_conda_env" # set the name of the conda environment to export
BUILD_DIR=$(pwd) # set the build dir to this REAMDE dir, with the Dockerfile
USER_DOCKER="my_dockerhub_user_name"

# source the conda environment
source activate ${CONDA_ENV}

# dump the conda environment
conda env export --no-builds | grep -v prefix | grep -v name > ${BUILD_DIR}/environment.yml

# build the Docker image
# NOTE: the default Dockerfile assumes environment.yml is in the same dir where
#       this command is executed.
docker build -f Dockerfile --tag staged/${CONDA_ENV} .

# push Docker image to Docker hub
docker tag staged/${CONDA_ENV} ${USER_DOCKER}/${CONDA_ENV}
docker push ${USER_DOCKER}/${CONDA_ENV}

# push Docker image to Google container registry
# NOTE: this will fail if using `sudo docker`
#docker tag staged/${CONDA_ENV} us.gcr.io/my-project-name/${CONDA_ENV}
#docker push us.gcr.io/my-project-name/${CONDA_ENV}
```


Cleanup all Docker containers
----------------------------

```bash
docker system prune --all --force

# Must be run first because images are attached to containers
docker rm -f $(docker ps -a -q)

# Delete every Docker image
docker rmi -f $(docker images -q)
```


Useful tips
-----------

Below are useful tips when encountering errors with a Docker image during runtime.

* Set the user to root instead of ${USER} in the Dockerfile, rebuild/deploy the image, and re-run. Note that there may be security risks in allowing the image to be run as root rather than ${USER}.
* Change the ENTRYPOINT or perhaps remove it altogether. For instance when running a Docker image on Google Pipelines APIv2, one must remove the ENTRYPOINT flag in the default Dockerfile provided here.
