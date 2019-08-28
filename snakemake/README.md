
Google Kubernetes Engine (GKE)
------------------------------

Run Snakemake using GKE.

1. Set variables

```bash
# cd into the directory with this README.md file
SNK_REPO=$(pwd)
CONDA_ENV="gke_demo"

GCP_BUCKET="myproject-bucket/test-gke"
GCP_CLUSTER_NAME="${USER}-$(echo ${CONDA_ENV} | sed s/'_'/'-'/)"
GCP_ZONE="us-west1-b"
GCP_PROJECT="myproject"
```


2. Make conda environment for container and local job execution.

```bash
# build the environment to run GKE
conda create --name gke_run
source activate gke_run
conda install snakemake
conda install python-kubernetes
conda install r

# build the execution image
conda create --name ${CONDA_ENV}
source activate ${CONDA_ENV}
conda install snakemake
```


3. Make Docker image (see [docker tutorial](../docker/README.md)) of execution image.


4. Make demo data and to put it in a Bucket.

```bash
Rscript scripts/make_data.R

gsutil cp demo_data.tsv.gz gs://${GCP_BUCKET}
```


5. Run the Snakemake pipeline locally to verify it works.

```bash
snakemake --snakefile ${SNK_REPO}/Snakefile
```


6. Make GKE

```bash
gcloud container clusters create ${GCP_CLUSTER_NAME} \
    --zone=${GCP_ZONE} \
    --num-nodes=2 \
    --machine-type=n1-standard-8 \
    --disk-size=10GB \
    --disk-type=pd-ssd \
    --scopes=gke-default,storage-rw,service-control \
    --project=${GCP_PROJECT} \
    --no-enable-basic-auth \
    --no-issue-client-certificate

gcloud container clusters get-credentials ${GCP_CLUSTER_NAME} \
    --zone=${GCP_ZONE} \
    --project=${GCP_PROJECT}
```


7. Run Snakemake pipeline using GKE

```bash
GKE_THREADS="8"
GKE_NODES="2"
SNK_JOBS=$((${THREADS} * ${NODES}))
DOCKER_IMG="letaylor/gke_demo"

# compute via GKE using bucket files
# NOTE: it is not possible to run this using local files, both as data inputs
#       and via a local config
snakemake \
    --snakefile ${SNK_REPO}/Snakefile \
    --verbose \
    --printshellcmds \
    --jobs ${SNK_JOBS} \
    --max-status-checks-per-second 0.25 \
    --kubernetes \
    --container-image ${DOCKER_IMG} \
    --default-remote-provider GS \
    --default-remote-prefix ${GCP_BUCKET}
```


8. Shut down GKE

```bash
gcloud container clusters delete ${GCP_CLUSTER_NAME} \
    --zone=${GCP_ZONE} \
    --project=${GCP_PROJECT}
```
