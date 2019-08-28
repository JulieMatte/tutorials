
Introduction to working on the Google Cloud Platform (GCP).


Logging into GCP
----------------

```bash
# by default the authentication is saved to:
# ${HOME}/.config/gcloud/application_default_credentials.json
# gcloud auth login --no-launch-browser
gcloud auth application-default login --no-launch-browser
```

Initialize a virtual machine
-----------------------------

Connect to a virtual machine and configure gcloud. Note: if this is a new VM you may need to install software (e.g., gcloud, gcsfuse).

```bash
gcloud compute \
    --project "myproject" ssh \
    --zone "us-west1-b" "${USER}-myorgnization"

# set glcoud defaults
#gcloud config set project myproject
#gcloud config set compute/zone us-west1-b
```


Google service account
----------------------

To run many requests to Google Kubernetes Engine (GKE), Google requires a service account. See [this link](https://cloud.google.com/docs/authentication/getting-started) and [this link](https://cloud.google.com/kubernetes-engine/docs/tutorials/authenticating-to-cloud-platform). If you do not make a service account, GKE will complain and after many requests, may block you.

1. Follow the instructions to make a service account
2. Download json authentication and copy to `${HOME}/.config/gcloud/${USER}-myproject-service-credentials.json`
3. Submit a request to your admin asking for GKE access for the new account.

```bash
# export the application
export GOOGLE_APPLICATION_CREDENTIALS=${HOME}/.config/gcloud/${USER}-myproject-service-credentials.json

# the below method is preferable to simply exporting (in some cases simply
# exporting did not work properly)
GCP_SERVICE_ID="" # something@your-project.iam.gserviceaccount.com
GCP_SERVICE_JSON=${USER}/.config/gcloud/something.json
gcloud auth activate-service-account ${GCP_SERVICE_ID} \
    --key-file ${GCP_SERVICE_JSON}
```

To see your active authentications:
```bash
gcloud auth list

# set an account
gcloud config set account ${GCP_SERVICE_ID}
```


Google Container Registry (GCR) and Docker
------------------------------------------

Using GCR is a bit tricky. To be able to push to it from a service account, you must first grant the account permissions by following the steps under "Granting users and other projects access to a registry" at [this page](https://cloud.google.com/container-registry/docs/access-control). Note the GCR bucket is not under the project name, but rather looks like [REGION].artifacts.[PROJECT-ID].appspot.com; for instance, if the project is cool-stuff, the bucket may look like us.artifacts.cool-stuff.appspot.com.

In order to figure out the service account user name (whose permissions need to be updated), see the "client_email" value in the json authentication file. You may need to give the account the custom permissions of a group within your organization.

```bash
cat ${HOME}/.config/gcloud/${USER}-myproject-service-credentials.json
# "client_email": "[SERVICE_USER_NAME]@[PROJECT_ID].iam.gserviceaccount.com"
```

Configure Docker to [push to GCR](https://cloud.google.com/container-registry/docs/pushing-and-pulling). Note that in older gsutil versions one could push an image from gsutil; however, this is no longer supported.

```bash
# configure Docker to push to Google container registry
gcloud auth configure-docker

sudo docker login -u _json_key -p "$(cat ${HOME}/.config/gcloud/${USER}-myproject-service-credentials.json)" https://us.gcr.io
```

Now push the image to GCR. Note GCR is very picky about how images are tagged.

```bash
DOCKER_IMAGE_NAME="my_docker_image"
GCP_HOSTNAME="us.gcr.io"
GCP_PROJECT_ID="myproject"

# build the Docker image
sudo docker build -f Dockerfile --tag ${DOCKER_IMAGE_NAME} .

# push Docker image to Google container registry
# image format = [HOSTNAME]/[PROJECT-ID]/[IMAGE]
sudo docker tag ${DOCKER_IMAGE_NAME} ${GCP_HOSTNAME}/${GCP_PROJECT_ID}/${DOCKER_IMAGE_NAME}
sudo docker push ${GCP_HOSTNAME}/${GCP_PROJECT_ID}/${DOCKER_IMAGE_NAME}
```
