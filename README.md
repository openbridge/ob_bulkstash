# Bulk Stash - Batch processing for cloud storage
Bulk Stash is an `rclone` service to sync, or copy, files between different storage services. For example, you can copy files either to or from a remote storage services like Amazon S3 to Google Cloud Storage, or locally from your laptop to a remote storage. Bulk Stash is a dockerized version of rclone.

You can also use this for copying or syncing files locally to a remote SFTP server or between two remote SFTP servers.

![rclone](https://github.com/openbridge/ob_bulkstash/raw/develop/rclone.png "How It Works")

There are advanced use cases where you can actually transfer a certain class of files (CSV) to Amazon S3 for import into Amazon Redshift, BigQuery or Amazon Athena. If you are interested in learning check out this [blog post](https://blog.openbridge.com/how-to-setup-a-batch-data-pipeline-for-csv-files-8c4d0cd7394b).

# Features
* **Dockerized**: `rclone` is neatly packed into a Docker image that can be run anywhere Docker can be installed.
* **Alpine Linux**: The container uses Alpine Linux which makes it light and efficient. The image size is < 26mb.
* **Environment Variables**: The image is designed to take advantage of recent support in `rclone` to utilize environment variables. This means you don't have to step through the typical config initialization process.
* **Process Monitoring and Management**: The container also uses `Monit` to ensure that long running processes are monitored under process management. For example, `Monit` will make sure `crond` is running in the background and will restart it if it crashed. You can extend Monit to monitor folders, check for file sizes and many other.
* **Configuration**: Configuration can be stored and managed outside the container. Configurations can also be inserted at runtime manually or via a controller script/app
* **Runtime**: You can run a collection of containers running independent tasks via config files. This means you can wrap the Docker service with other apps like bash, python and so forth on your host
* **Deployment**: You can setup things like Amazon Lambda and ECS tasks to control the runtime tasks. Configurations can be encrypted and stored in a service like AWS KMS. Configuration attributes can then be provided by an end user via a front-end web app. For example, you can have a form that collects all the S3 or Google OAuth tokens. A front end is not include :)
* **Notifications**: You can uses services like cronalarm, Cronitor.io, healthchecks.io...to set status and alerts. Notifications via Slack, Hipchat... are also possible, but not enabled.
* **Folder Size Monitoring**: Local source folders can be monitored. If the size of the contents in the source folder exceed a value you set an rclone copy operation will occur

### Features
* MD5/SHA1 hashes checked at all times for file integrity
* Timestamps preserved on files
* Partial syncs supported on a whole file basis
* Copy mode to just copy new/changed files
* Sync (one way) mode to make a directory identical
* Check mode to check for file hash equality
* Can sync to and from network, eg two different cloud accounts
* Optional encryption (Crypt)
* Optional FUSE mount (rclone mount)
* Optional database loading

## Supported Services
 What services are supported?
* Google drive
* **Amazon S3**
* Swift / Rackspace Cloudfiles / Memset Memstore
* Dropbox
* **Google Cloud Storage**
* Local filesystem
* Amazon Drive
* Backblaze B2
* Hubic
* Microsoft OneDrive
* Yandex Disk
* **SFTP**

For the items in **bold** there are sample commands and configurations in the readme.

# Getting Started

First, pull the latest docker image:

```bash
docker pull openbridge/ob_bulkstash
```
This will pull the latest version by default. However, as part of the `hooks/build` process we publish a number of older versions of rclone. If you want to see the available versions, check out Docker Hub [`openbridge/ob_bulkstash`](https://hub.docker.com/r/openbridge/ob_bulkstash/tags/). For example, if you wanted to run version `1.47`, then pull that version like this:

```bash
docker pull openbridge/ob_bulkstash:1.47.0
```
Additional pre-built versions are tagged and available for use: https://hub.docker.com/r/openbridge/ob_bulkstash/tags/

If you want to build your own image, you need to pass the version you want to use:
```bash
docker build --build-arg RCLONE_VERSION=1.47.0 -t openbridge/ob_bulkstash:1.46 .
docker build --build-arg RCLONE_VERSION=1.47.0 -t openbridge/ob_bulkstash:latest .
```
You may also pass a different architecture: `--build-arg RCLONE_TYPE=arm`

Got your version setup? Great. Next, we need to define a configuration for remote storage locations. The following demonstrates how to sync Amazon and Google cloud storages.

### Testing Your Build
The validate that your build worked correctly, you can run a simple check which will have rclone echo the version back to you.

If you run this `docker run openbridge/ob_bulkstash rclone -V` you should see the version displayed like this:
```Bash
rclone v1.47.0
- os/arch: linux/amd64
- go version: go1.12.4
```
If you see this, success! Your image is ready to go!

## Amazon and Google Examples
In our example we have a source of files at Amazon S3 and destination for those files at Google Cloud Storage location. This means we will need to set the configuration ENV variables for source and destination.

### Amazon S3
Here is an Amazon Simple Storage Service (aka "S3") config:

```bash
RCLONE_CONFIG_MYS3_TYPE=s3
RCLONE_CONFIG_MYS3_ACCESS_KEY_ID=enter your access key
RCLONE_CONFIG_MYS3_SECRET_ACCESS_KEY=enter your secret key
RCLONE_CONFIG_MYS3_SERVER_SIDE_ENCRYPTION=AES256
RCLONE_CONFIG_MYS3_STORAGE_CLASS=REDUCED_REDUNDANCY
```

The first thing is to define the `type` as s3: `RCLONE_CONFIG_MYS3_TYPE=s3`

Next, you need to provide credentials to access (pull data from or copy data to) S3:
`RCLONE_CONFIG_MYS3_ACCESS_KEY_ID=enter your access key` and
`RCLONE_CONFIG_MYS3_SECRET_ACCESS_KEY=enter your secret key`

You will want to set the encryption for the data you send to S3: `RCLONE_CONFIG_MYS3_SERVER_SIDE_ENCRYPTION=AES256`

You can also set your storage class in the event you want to use lower cost options: `RCLONE_CONFIG_MYS3_STORAGE_CLASS=REDUCED_REDUNDANCY`. Set this to your preference.


### Google
Like S3 we can use Google Cloud Storage as a remote location.

```bash
RCLONE_CONFIG_MYGS_TYPE=google cloud storage
RCLONE_CONFIG_MYGS_CLIENT_ID=
RCLONE_CONFIG_MYGS_CLIENT_SECRET=
RCLONE_CONFIG_MYGS_PROJECT_NUMBER=foo-mighty-139217
RCLONE_CONFIG_MYGS_SERVICE_ACCOUNT_FILE=/auth.json
```

The first step is to set the `type` for Google: `RCLONE_CONFIG_MYGS_TYPE=google cloud storage`

Next, make sure you set your credentials like you did for S3: `RCLONE_CONFIG_MYGS_CLIENT_ID=enter your client key` and `RCLONE_CONFIG_MYGS_CLIENT_SECRET=enter your secret key`

The project number is only needed only for list/create/delete buckets:
 `RCLONE_CONFIG_MYGS_PROJECT_NUMBER=foo-mighty-139217`

If you are using a Google Account Credentials JSON file you would leave the client ID and secret blank and enter the path to your file:
 `RCLONE_CONFIG_MYGS_SERVICE_ACCOUNT_FILE=/auth.json`

 You will need to make sure that the volume that contains the auth file is mounted and the path is passed via `RCLONE_CONFIG_MYGS_SERVICE_ACCOUNT_FILE`.

**Thats it!** You defined two remote locations, one for Amazon and one for Google. You can start to transfer files.

# How To Run
With your config setup, now you can run `rclone`!

This is an example Docker `RUN` command
```bash
docker run openbridge/ob_bulkstash \
  --env-file env/sample.env \
  rclone copy MYS3:myawsbucket/path/to/file/ MYGS:mygooglebucket/path/to/files/
```
Check out the [docker run docs](https://docs.docker.com/engine/reference/commandline/run/) for the latest syntax.

Lastly, you can use Docker Compose:
```bash
docker-compose up -d
```
or

```bash
/usr/local/bin/docker-compose -f prod.yml up -d --remove-orphans
```
Note: You will need to put the appropriate command in the compose YAML file you want docker rclone to run.


## Examples Running Docker On Your Host
These are a couple of simple examples around wrapping the Docker image with Bash on your host.

### Run multiple config files
This example will go through all the env files and run the image with a `COPY` command:
```bash
for i in ./env/*.env; do
docker run -v /my/volume:/data -it --env-file ${i} openbridge/ob_bulkstash rclone copy MYS3:myawsbucket/path/to/file/ MYGS:mygooglebucket/path/to/files/
done
```
Earlier we showed a simple rclone command to echo the version number:
```bash
docker run openbridge/ob_bulkstash rclone -V
```

### Using the Google AUTH file
Here is an example that mounts the Google auth file needed for service level accounts:
```bash
for i in ./env/prod/*.env; do
  echo "working on $i"
  bash -c "docker run -it -v /auth/prod/auth.json:/auth.json --env-file ${i} openbridge/ob_bulkstash rclone copy MYS3:myawsbucket/path/to/file/ MYGS:mygooglebucket/path/to/files/"
  if [[ $? = 0 ]]; then echo "OK: "; else echo "ERROR: "; fi
done
```
# Using `crond` Inside Docker
If you want to persist your container you can set it up to always be running with `crond` as a background process. While most everything is automated there are a few configuration items you need to set.

**IMPORTANT**: This assumes you have a basic understanding of Docker and background processes. If you do not know what `--detach , -d` means then please review the Docker docs about running in detached mode (hint: this is how you run things in the background)

## Runtime Environment
Depending on your use of `CROND`, it may not have access to the OS defined `ENV` variables. As a convenience, the image will output these to a file:

```bash
printenv | sed 's/^\([a-zA-Z0-9_]*\)=\(.*\)$/export \1="\2"/g' | grep -E "^export RCLONE" > /cron/rclone.env
```
If needed, you can then import these variables into any scripts that you want to run in the container such as using something like `source /cron/rclone.env`.

## Option 1: Bring Your Own Crontab Configuration

### Step 1: Setup your `crontab.conf` config
Running `crond` requires a proper configuration file. You can easily add a crontab config file and have the container use it. A `crontab.conf` should look something like this:

```bash
SHELL=/bin/bash
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
*/15 * * * * /usr/bin/env bash -c /rclone.sh run 2>&1
```
There is a sample of this in `cron/crontab.conf`. You can use this as a starting point for your own config. Once you have your config ready, we can move to Step 2.

### Step 2: Mount your `crontab.conf` config
Next, you will want to mount your config file. The config is on your host, not in the container. To get it into your container you need to mount it from your host into the container.

The basic template is this:

```docker
-v /path/to/the/file/on/your/host/crontab.conf:/where/we/mount/in/container/crontab.conf
```

This example shows the mount your config in docker compose format:
```docker
volumes:
  - /Github/ob_bulkstash/cron/crontab.conf:/cron/crontab.conf
```
It will look the same if you are doing it via Docker run:
```docker
-v /Github/ob_bulkstash/cron/crontab.conf:/cron/crontab.conf
```
In those examples, the `crontab.conf` located in my local GitHub folder will get mounted inside the container at `/cron/crontab.conf`

Mounting your config makes it available to the startup service within your container. If you are unfamiliar with `-v` or `volumes`, check the docs from Docker.


### Step 3: Set environment variable `RCLONE_CRONFILE`
In your `ENV` make sure to set the path to the location you are mounting your `crontab.conf` file. In our example above we are using `/cron/crontab.conf`. This means you set the `ENV` path like this:
```
RCLONE_CRONFILE=/cron/crontab.conf
```

**This is the location in your container, not the host**


## Option 2: Automatic Generation `RCLONE_CRONFILE`

You can let the image generate and run a command for you under `CROND`.
This is geared to running a single `CROND` task. If you want to run multiple tasks, it is best to choose **Option 1** which allows you more control over the number of tasks run.

### Setting your `CROND` command
In your ENV, you need to set the desired command via `RCLONE_SYNC_COMMAND`. Here is an example command:

```bash
docker run -d -e RCLONE_SYNC_COMMAND="*/15 * * * * /usr/bin/env bash -c /foo run" openbridge/ob_bulkstash crond -f
```
This will result in your container running in the detached mode (in the background) with a `CROND` entry like this:
```bash
SHELL=/bin/bash
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
*/15 * * * * /usr/bin/env bash -c /foo run
```
This is just an example command, it will likely vary according to what you are looking too run.


## IMPORTANT `crontab.conf` NOTE
Please note that if you set your own crontab config file via `RCLONE_CRONFILE=/cron/crontab.conf` it will take precedent over anything you pass via `-e` or set other environment variables.

## Understanding How To Run Docker and `CROND`
Here are a few examples of running Docker and `CROND` in the background. You can accomplish the same using `docker-compose`

Running in detached mode:
```bash
docker run -d -e RCLONE_SYNC_COMMAND="*/15 * * * * /usr/bin/env bash -c /foo run" openbridge/ob_bulkstash crond -f
```
You can see the process running in the background:
```bash
PID  PPID USER     STAT   VSZ %VSZ CPU %CPU COMMAND
 31     0 root     R     1528   0%   3   0% top
  1     0 root     S     1516   0%   1   0% crond -f
```
Running in detached mode using the `rcron.sh` helper script. This will use Monit has the background process monitor to make sure `CROND` is always running:
```bash
docker run -d -e RCLONE_SYNC_COMMAND="*/15 * * * * /usr/bin/env bash -c /foo run" openbridge/ob_bulkstash rcron start
```
You can see the process running in the background:
```bash
PID  PPID USER     STAT   VSZ %VSZ CPU %CPU COMMAND
 21     1 root     S     4788   0%   2   0% monit -Iv -c /etc/monitrc -l /dev/null
  1     0 root     S     2172   0%   3   0% bash /usr/bin/rcron start
 23     0 root     R     1524   0%   2   0% top
 20     1 root     S     1516   0%   0   0% crond -b
 ```
Here is another example running Monit as the controlling process:
```bash
docker run -d -e RCLONE_SYNC_COMMAND="*/15 * * * * /usr/bin/env bash -c /foo" openbridge/ob_bulkstash monit -Iv -c /etc/monitrc -l /dev/null
```
You can see the process running in the background:
```bash
PID  PPID USER     STAT   VSZ %VSZ CPU %CPU COMMAND
  1     0 root     S     4788   0%   2   0% monit -Iv -c /etc/monitrc -l /dev/null
 22     0 root     R     1528   0%   1   0% top
 21     1 root     S     1516   0%   3   0% crond -b
 ```

 Hopefully you get the point on how to do this. You have options, just make sure you understand the basics on how to run Docker in various contexts.

# Creating Your Own Scripts: The `/rclone.sh` Example

Included in the image is a utility script. You can use this as a robust example for creating your own. It highlights the potential to mount scripts like this into your container to run different types of operations.

**Note**: `rclone.sh` is provided as-is and has not been fully tested. Think of it as a proof-of-concept, not something you should blindly use.

## Overview
The script shows an example of how to run `rclone copy` and `rclone move`. It will also has a `foldersize` check in the event you want to trigger a `rclone move`. How is this helpful? If your disk is getting full this can trigger what amounts to be a cleanup task.  

### Getting Started with `/rclone.sh`
While the image contains `rclone.sh`, you will likely want to mount your own version of the script. For example;
```
-v /path/to/the/file/on/your/host/script.sh:/path/in/container/script.sh
```

Also, you need to make sure the image can use `/rclone.sh`. This means you need to make sure any required environment variables are set correctly. For example, in your `ENV`, you need to set the following for `rclone.sh`:

* `RCLONE_CROND_SCHEDULE` crontab schedule `* * * * *` to perform sync every midnight
* `RCLONE_CROND_SOURCE_PATH` source location for `rclone copy` command
* `RCLONE_CROND_DESTINATION_PATH` destination location for `rclone copy` command

#### Setting Source and Destination
In your environment file you need to make sure your source and destination remotes are set. You need to put the full statement (remote names, buckets, paths...) for the source and destination for each variable.
```bash
RCLONE_CROND_SOURCE_PATH="/temp"
RCLONE_CROND_DESTINATION_PATH="MYS3:myawsbucket/path/to/file/"
```
This will ensure that `rclone` knows where to look for the files and where you want them delivered.


This is what it would look like in your config:
```bash
RCLONE_CROND_SCHEDULE=*/5 * * * *
RCLONE_CROND_SOURCE_PATH="/tmp"
RCLONE_CROND_DESTINATION_PATH="MYS3:ob-testing/ebs"
```

### Optional Settings

#### Health check service

`RCLONE_CROND_HEALTHCHECK_URL`
If you want to use a cron healthcheck service, set the environment variable:
* `RCLONE_CROND_HEALTHCHECK_URL` used for health check services to ping status like cronalarm, Cronitor.io, healthchecks.io...

This is what it would look like in your config:
```bash
RCLONE_CROND_SCHEDULE=*/5 * * * *
RCLONE_CROND_SOURCE_PATH="/tmp"
RCLONE_CROND_DESTINATION_PATH="MYS3:ob-testing/ebs"
RCLONE_CROND_HEALTHCHECK_URL=https://hchk.io/asads-aa12-ee23-qqw1-543e4c2ddv54385
```
#### How to monitor the size of your source directory
You can use a `foldersize` check to monitor your source path. To do this set the environment variable `RCLONE_CROND_SOURCE_SIZE` to a number in megabytes. For example, if you want to monitor your source path for 1 GB of files, you would set `RCLONE_CROND_SOURCE_SIZE=1000`. The 1000 megabytes = 1 GB.


```bash
RCLONE_CROND_SCHEDULE=*/5 * * * *
RCLONE_CROND_SOURCE_PATH="/tmp"
RCLONE_CROND_DESTINATION_PATH="MYS3:ob-testing/ebs"
RCLONE_CROND_SOURCE_SIZE="1000"
```


# Setting Up SFTP Remotes
You can setup SFTP remotes. This allows you to upload or download files from an SFTP server. You can also do server to server transfers between two remotes.

Lastly, if you want to pipeline data to Redshift, BigQuery, Athena or Spectrum via rclone take a look at the following batch data pipeline workflow:
* https://blog.openbridge.com/how-to-setup-a-batch-data-pipeline-for-csv-files-8c4d0cd7394b

If you have any questions about how to pipeline data to a warehouse let me know.

Sample config
* `RCLONE_CONFIG_MYSFTP_TYPE=sftp`
* `RCLONE_CONFIG_MYSFTP_HOST=pipeline.openbridge.io`
* `RCLONE_CONFIG_MYSFTP_USER=user`
* `RCLONE_CONFIG_MYSFTP_PORT=443`
* `RCLONE_CONFIG_MYSFTP_PASS=34232424234234234`

Here is a sample command that copies data from a remote SFTP server locally with a `60s` timeout:
`rclone copy sftp:/folder /tmp --contimeout 60s`

# Sample Commands
Here are a few sample commands you can use use for testing or general usage

## List Remote Directories
List a remote drive  like this: `rclone lsd {remote name}:`
**Note:** The command has `:` at the after the remote. If you do not include `:` things wont work

Replace `{remote name}` with your actual remote name. Using our Amazon example it would look like this
`rclone lsd MYS3:`

Using Docker this is a possible way to run the command:
```bash
docker run -env-file /env/my.env openbridge/ob_bulkstash rclone lsd MYS3:
```

This will output your remote buckets like this:

```bash
          -1 2017-04-11 16:38:05        -1 athena-lambda
          -1 2016-12-04 14:32:54        -1 aws-athena-query
          -1 2016-12-17 14:19:23        -1 aws-logs
          -1 2015-03-31 21:48:40        -1 cf-templates
          -1 2016-11-17 15:56:56        -1 chat000
          -1 2016-10-06 17:09:10        -1 chat001
          -1 2016-10-24 05:28:09        -1 chat002
          -1 2014-02-11 14:55:25        -1 prod001
          -1 2014-02-11 14:55:43        -1 prod002
          -1 2016-06-05 21:59:28        -1 temp002
```

## List Remote Files
List remote files of a certain type:
`rclone --include "*.jpg" ls {remote name}:{aws bucket name}/{folder}`

Using our AWS remote:
`rclone --include "*.jpg" ls MYS3:mybucket/files`

## Make Remote Location (Bucket)
Make a new bucket sample:
`rclone mkdir {remote name}:{aws bucket name}`

Using our AWS remote:
`rclone mkdir MYS3:mynewbucket`

## Sync
Sync file sample:
`rclone sync /home/local/directory {remote name}:{aws bucket name}/{folder}`

Using our AWS remote:
`rclone sync /tmp MYS3:mynewbucket/temp [--drive-use-trash]`

## Copy
The basic structure of the `rclone` command looks like this for `COPY`:
```
rclone copy {{source_config}}:{{bucket}}/{{path/to/file/}} {{dest_config}}:{{bucket}}/{{path/to/file/}}
```
You assign your source and destinations according to your configs. For example, in this case we have `MYS3` and `MYGS` where we assing one as the source and the other as the destination:
```
rclone copy MYS3:myawsbucket/path/to/file/ MYGS:mygooglebucket/path/to/files/
```


# Why Use ENV variables?
This docker image uses rclone and is focused on separating configuration from the runtime. This does not preclude using a traditional config file. Feel free to go down that path if it makes sense to you. The image would support it.

## Config Syntax
* Each config statement has `RCLONE_`. It is the prefix for each variable.
* In each variable you define the name you block by setting `RCLONE_CONFIG_{{NAME}}_`. In our S3 example we use `RCLONE_CONFIG_MYS3` for Amazon and `RCLONE_CONFIG_MYGS` for Google.
* The last part is the formal configuration attribute. For example, `TYPE`, `ACCESS_KEY_ID` or `SERVER_SIDE_ENCRYPTION` are standard config elements for s3 rclone. Normally be prefixed like this: `--type`
* You need to make sure `{{NAME}}` is unique to avoid any collisions in your configs. For example, you cant have multiple `RCLONE_CONFIG_MYS3` statements. If you have multiple S3 locations do something like `RCLONE_CONFIG_MYS3-01`, `RCLONE_CONFIG_MYS3-02` and `RCLONE_CONFIG_MYS3-03`

## Using Docker Secrets
Environment variables can be formed to point at the content of Docker secrets
files, so as to avoid giving away sensitive information. Any environment
variable which value looks like the following `DOCKER-SECRET::<path>` (note the
leading `DOCKER-SECRET` keyword and the double colon `::`) will be replaced by
the content of the file at `<path>` if it exists. Relative paths are
automatically resolved to `/run/secrets` (the default path for Docker secrets),
but absolute paths can also be used.

# Performance Tips
These tips come from  http://moo.nac.uci.edu/~hjm/HOWTO-rclone-to-Gdrive.html

To obtain good transfer rates, you have to increase the number and size of files you transfer at one time, as well as the number of simultaneous streams and the checkers. So, for rclone to transfer files efficiently, there has to be a large payload per transfer and a number of simultaneous streams. It works best if there are large, identically sized files, but regardless, larger files are better, because of the initiation overhead.

`rclone --transfers=32 --checkers=16 --drive-chunk-size=16384k \
--drive-upload-cutoff=16384k  copy /my/folder MYGS:mybucket/myfiles`

Copy files from remote location locally:

`rclone --transfers=12  copy MYGS:mybucket/myfiles /my/local/dir`

# Versioning

Docker Tag | Git Hub Release | rclone | Alpine Version
---------- | --------------- | -------- | --------------
latest*     | develop         | latest   | 3.9.x

Additional versions are tagged and available for use: [https://hub.docker.com/r/openbridge/ob_bulkstash/tags/](https://hub.docker.com/r/openbridge/ob_bulkstash/tags/)

# Docs
For more examples on configuration and rclone commands please refer to the docs:
https://rclone.org/docs/

This images is using Docker. If you don't know what Docker is read "[What is Docker?](https://www.docker.com/what-docker)". Once you have a sense of what Docker is, you can then install the software. It is free: "[Get Docker](https://www.docker.com/products/docker)". Select the Docker package that aligns with your environment (ie. OS X, Linux or Windows). If you have not used Docker before, take a look at the guides:

- [Engine: Get Started](https://docs.docker.com/engine/getstarted/)
- [Docker Mac](https://docs.docker.com/docker-for-mac/)
- [Docker Windows](https://docs.docker.com/docker-for-windows/)

# Issues

If you have any problems with or questions about this docker rclone image, please contact us through a GitHub issue.

# Contributing

You are invited to contribute new features, fixes, or updates, large or small; we are always thrilled to receive pull requests, and do our best to process them as fast as we can.

Before you start to code, we recommend discussing your plans through a GitHub issue, especially for more ambitious contributions. This gives other contributors a chance to point you in the right direction, give you feedback on your design, and help you find out if someone else is working on the same thing.

# License

This project is licensed under the MIT License


# References
* https://hub.docker.com/r/tynor88/rclone/
* https://forum.rclone.org/t/request-official-docker-container/1659
* https://github.com/kevineye/docker-rclone
* https://github.com/valentine/docker-rclone-sh
