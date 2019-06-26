
Getting started with workflow management using [cromwell](https://cromwell.readthedocs.io/en/stable). A useful reference pipeline is the [ENCODE ATAC-seq pipeline](https://github.com/ENCODE-DCC/atac-seq-pipeline).


# General

## 1. Install cromwell with conda.

```bash
conda install -c bioconda cromwell
```

## 2. Validate the workflow

```bash
womtool validate hello.wdl
```

## 3. Configure the backend

To run on any backend you should not have to change the `backend.conf` file; however, you may need to adjust the opts file based on the specific needs (e.g., `slurm.json`).


## 4. Configure pipeline parameters

Generate a file of the inputs. Note you may need to edit this file by hand.

```bash
womtool inputs hello.wdl | sed s/\"String\"/\"${USER}\"/ > inputs.json
```


# Run: local machine

## 1. Run the pipeline

Note that we include `--metadata-output` (an optional directory path to output metadata) in order to help resume failed jobs.

```bash
CROMWELL_LIB_DIR=lib-cromwell
CROMWELL_BACKEND=${CROMWELL_LIB_DIR}/backend.conf

cromwell \
    -Dconfig.file=${CROMWELL_BACKEND} \
    -Dbackend.default=local \
    run hello.wdl \
    --inputs inputs.json \
    --metadata-output metadata.json
```


# Run: local machine via Docker

## 1. Run the pipeline

```bash
cromwell \
    -Dconfig.file=${CROMWELL_BACKEND} \
    -Dbackend.default=docker \
    run hello.wdl \
    --inputs inputs.json \
    --metadata-output metadata.json
```


# Run: slurm backend

## 1. Run the pipeline

```bash
CROMWELL_OPTS=${CROMWELL_LIB_DIR}/workflow_opts/slurm.json

cromwell \
    -Dconfig.file=${CROMWELL_BACKEND} \
    -Dbackend.default=slurm \
    run hello.wdl \
    --inputs inputs.json \
    --options ${CROMWELL_OPTS} \
    --metadata-output metadata.json
```


## 2. Server mode: set up a server

If you want to run multiple pipelines, then run a Cromwell server on an interactive node using tmux to keep the session alive.

Get the IP of the node that will become the server.
```bash
CROMWELL_SVR_IP=$(hostname -f)
echo ${CROMWELL_SVR_IP}
```

Boot up the server
```bash
cromwell \
    -Dconfig.file=${CROMWELL_BACKEND} \
    -Dbackend.default=slurm \
    server
```


## 3. Server mode: submit jobs to a server instance

Submit a job to the server like so. You can submit multiple jobs by looping over multiple .wdl or .json input files and submitting them as shown below:

```bash
CROMWELL_OPTS=${CROMWELL_LIB_DIR}/workflow_opts/google.json

curl -X POST --header "Accept: application/json" -v "${CROMWELL_SVR_IP}:8000/api/workflows/v1" \
    -F workflowSource=@hello.wdl \
    -F workflowInputs=@inputs.json \
    -F workflowOptions=@${CROMWELL_OPTS}
```


## 4. Job caching: MySQL database

From the [cromwell website](https://cromwell.readthedocs.io/en/stable/cromwell_features/CallCaching):

> Call Caching allows Cromwell to detect when a job has been run in the past so that it doesn't have to re-compute results, saving both time and money. Cromwell searches the cache of previously run jobs for one that has the exact same command and exact same inputs. If a previously run job is found in the cache, Cromwell will use the results of the previous job instead of re-running it.
> Cromwell's call cache is maintained in its database. In order for call caching to be used on any previously run jobs, it is best to configure Cromwell to point to a MySQL database instead of the default in-memory database. This way any invocation of Cromwell (either with run or server subcommands) will be able to utilize results from all calls that are in that database.

Other good resources on booting up a MySQL database are [here](https://cromwell.readthedocs.io/en/stable/Configuring/#database), [here](https://github.com/ENCODE-DCC/atac-seq-pipeline/tree/master/test), and [here](https://gatkforums.broadinstitute.org/wdl/discussion/12534/how-to-enable-call-caching-using-database).

Start the docker session (note that `${MYSQL_DIR}` is referenced in `backend_with_db.conf` and `${MYSQL_INIT}`, so if you change `${MYSQL_DIR}`, be sure to change those as well):

```bash
MYSQL_DIR=${HOME}/cromwell_db
MYSQL_INIT=${CROMWELL_LIB_DIR}/mysql

mkdir ${MYSQL_DIR}

# -e MYSQL_USER=cromwell \
# -e MYSQL_PASSWORD=cromwell \
docker run -d \
    --name mysql-cromwell \
    -v ${MYSQL_DIR}:/var/lib/mysql \
    -v ${MYSQL_INIT}:/docker-entrypoint-initdb.d \
    -e MYSQL_ROOT_PASSWORD=cromwell \
    -e MYSQL_DATABASE=cromwell_db \
    --publish 3306:3306 mysql

# list the docker processes
docker ps
```

Once enabled, cromwell by default will search the call cache for every call statement invocation.
* If there was no cache hit, the call will be executed as normal. Once finished it will add itself to the cache.
* If there was a cache hit, outputs are either copied from the original cached job to the new job's output directory or referenced from the original cached job depending on the Cromwell Configuration settings.

Run cromwell utilizing the cache:

```bash
CROMWELL_BACKEND=${CROMWELL_LIB_DIR}/backend_with_db.conf
CROMWELL_OPTS=${CROMWELL_LIB_DIR}/slurm.json

cromwell \
    -Dconfig.file=${CROMWELL_BACKEND} \
    -Dbackend.default=slurm \
    run hello.wdl \
    --inputs inputs.json \
    --options ${CROMWELL_OPTS} \
    --metadata-output metadata.json
```

Stop and remove the docker mysql session:
```bash
docker stop mysql-cromwell

docker rm -f mysql-cromwell
```



# Run: Google Cloud Platform (GCP) backend via Google Pipelines

## 1. Set up GCP

We assume you have a a Google Project (with the following APIs enabled: Compute Engine API, Google Cloud Storage, Google Cloud Storage JSON API, and Genomics API) and Google Storage bucket have been set up.

Set your default Google Cloud Project. Pipeline will provision instances on this project.
```bash
gcloud config set project "my-project-name"
```

The permissions can be tricky. The recommended way is to use a service account (see [GCP tutorial](../gcp/README.md)) and directly pass the json authentication (1a). To make a service account, ask your systems admin to provide you with a service account with the following IAM roles:
* Read / write permissions to any required buckets (e.g., Storage Admin of your project)
* Genomics Service Agent

Note: In theory, that should be all of the requirements.


### 1a. Backend authentication method: user-service-account (recommended)

```bash
# assuming you have jc installed: (a) compress the json file, (b) make the
# entire file a string, and (c) escape \n and "
#
# add the line resulting from the below command to
# ${CROMWELL_LIB_DIR}/workflow_opts/google.json
echo \"user_service_account_json\" : \"$(cat ${GCP_SERVICE_JSON} | jq -c | sed s/'\"'/'\\"'/g | awk '{gsub(/\\n/,"\\\\n")}1' )\"
```

### 1b. Backend authentication method: application-default

Alternatively, you can tell cromwell to use the default authentication from gcloud. Note that you *cannot* simply change the credentials using `GOOGLE_APPLICATION_CREDENTIALS` as described in this [GitHub issue](https://github.com/broadinstitute/cromwell/issues/3690).

Run using a user account:
```bash
# Assuming the above authentication commands have been run, you can just export
# the json file containing the credentials.
# NOTE: Do not use the below method. See https://github.com/broadinstitute/cromwell/issues/3690
#unset GOOGLE_APPLICATION_CREDENTIALS
#export GOOGLE_APPLICATION_CREDENTIALS=${HOME}/.config/gcloud/application_default_credentials.json

gcloud auth login --no-launch-browser
gcloud auth application-default login --no-launch-browser
```

For batch runtime execution, use a service account:
```bash
# NOTE: Do not use the below method. See https://github.com/broadinstitute/cromwell/issues/3690
# unset GOOGLE_APPLICATION_CREDENTIALS
# export GOOGLE_APPLICATION_CREDENTIALS=${HOME}/.config/gcloud/${USER}-service-credentials.json

GCP_SERVICE_ID="" # something@your-project.iam.gserviceaccount.com
GCP_SERVICE_JSON=${USER}/.config/gcloud/something.json

gcloud auth activate-service-account ${GCP_SERVICE_ID} \
    --key-file ${GCP_SERVICE_JSON}
```

To see your active authentications (the activate account should be the service account):
```bash
gcloud auth list

# set an account
gcloud config set account ${GCP_SERVICE_ID}
```



## 2. Run the pipeline

Note: it is good practice to check that you can run the pipeline using the docker image locally before running on GCP:
```bash
CROMWELL_BACKEND=${CROMWELL_LIB_DIR}/backend.conf
CROMWELL_OPTS=${CROMWELL_LIB_DIR}/workflow_opts/google.json
GCP_PROJECT="my-project-name"
GCP_BUCKET="gs://my-bucket-name/tmp"

cromwell \
    -Dconfig.file=${CROMWELL_BACKEND} \
    -Dbackend.default=google \
    -Dbackend.providers.google.config.project=${GCP_PROJECT} \
    -Dbackend.providers.google.config.root=${GCP_BUCKET} \
    run hello.wdl \
    --inputs inputs.json \
    --options ${CROMWELL_OPTS} \
    --metadata-output metadata.json
```

Run the pipeline with monitoring enabled via a monitoring script:
```bash
# NOTE: if there are permissions errors in the logs, you may need to make the
# USER root in the Dockerfile
gsutil cp ${CROMWELL_LIB_DIR}/cromwell_monitor/cromwell_monitor.sh ${GCP_BUCKET}
GCP_MONITOR=${GCP_BUCKET}/cromwell_monitor.sh

# add the following line to opts-google-monitoring.json
cp ${CROMWELL_OPTS} opts-google-monitoring.json
echo '"monitoring_script" : "'${GCP_MONITOR}'",'

# alternatively one could use the monitoring image option
GCP_MONITOR_IMG="letaylor/cromwell_monitor"
echo '"monitoring_image" : "'${GCP_MONITOR_IMG}'",'

# ...and re-run
cromwell \
    -Dconfig.file=${CROMWELL_BACKEND} \
    -Dbackend.default=google \
    -Dbackend.providers.google.config.project=${GCP_PROJECT} \
    -Dbackend.providers.google.config.root=${GCP_BUCKET} \
    run hello.wdl \
    --inputs inputs.json \
    --options opts-google-monitoring.json \
    --metadata-output metadata.json
```

Run the pipeline with monitoring enabled via a [monitoring image](https://github.com/broadinstitute/cromwell-monitor) ([assumes PAPIv2](https://github.com/broadinstitute/cromwell/pull/4510) and uses [Stackdriver](https://cloud.google.com/monitoring/)).
```bash
# add the following lines to opts-google-monitoring.json, drop the
# monitoring_script line
GCP_MONITOR_IMG="quay.io/broadinstitute/cromwell-monitor"
echo '"monitoring_image" : "'${GCP_MONITOR_IMG}'",'

# alternatively one could use the monitoring script option
# git clone https://github.com/broadinstitute/cromwell-monitor.git
# gsutil cp -r cromwell-monitor ${GCP_BUCKET}
# GCP_MONITOR=${GCP_BUCKET}/cromwell-monitor/monitor.py
# echo '"monitoring_script" : "'${GCP_MONITOR}'",'
```


## 3. Preemptible nodes

One option to cut down costs is to allow jobs to be [preemptible](https://cloud.google.com/compute/docs/instances/preemptible). Define the number of preemptible retrials by setting the `default_runtime_attributes.preemptible` variable. If all retrials fail, then the instance will be upgraded to a regular one. By default preemptible is disabled (i.e. is set to `"0"`).

```
{
  "default_runtime_attributes" : {
    ...
    "preemptible": "0",
    ...
}
```


## 4. Cloud tools

Below are useful tools when running cromwell with a GCP backend.
* [cromwell-monitor](https://github.com/broadinstitute/cromwell-monitor): monitoring resource utilization in Cromwell tasks running
* [cromwell-accountant](https://github.com/broadinstitute/cromwell-accountant): This script estimates the cost of running a Cromwell pipeline on Google Cloud based on Cromwell metadata JSON, which is a full response to GET https://${chromwell_host}/api/workflows/v1/{workflow_id}/metadata.
