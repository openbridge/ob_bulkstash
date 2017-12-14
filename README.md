

# Bulk Stash - Batch processing for cloud storage
Bulk Stash is an `rclone` service to sync, or copy, files between different storage services. For example, you can copy files either to or from a remote storage services like Amazon S3 to Google Cloud Storage, or locally from your laptop to a remote storage. Bulk Stash is a dockerized version of rclone.
You can also use this for copying or syncing files locally to a remote SFTP server or between two remote SFTP servers.

![rclone](/rclone.png "How It Works")

There are advanced use cases where you can actually transfer a certain class of files (CSV) to Amazon S3 for import into Amazon Redshift, BigQuery or Amazon Athena. If you are interested in learning more reach out.

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
To get started we need to define a configuration for remote storage locations. The following demonstrates how to sync Amazon and Google cloud storages.

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
docker run \
  -e RCLONE_CONFIG_MYS3_TYPE=s3 \
  -e RCLONE_CONFIG_MYS3_ACCESS_KEY_ID= \
  -e RCLONE_CONFIG_MYS3_SECRET_ACCESS_KEY= \
  -e RCLONE_CONFIG_MYS3_SERVER_SIDE_ENCRYPTION=AES256 \
  -e RCLONE_CONFIG_MYS3_STORAGE_CLASS=REDUCED_REDUNDANCY \
  -e RCLONE_CONFIG_MYGS_TYPE=google cloud storage \
  -e RCLONE_CONFIG_MYGS_CLIENT_ID= \
  -e RCLONE_CONFIG_MYGS_CLIENT_SECRET= \
  -e RCLONE_CONFIG_MYGS_PROJECT_NUMBER= \
  -e RCLONE_CONFIG_MYGS_SERVICE_ACCOUNT_FILE= \
  -e RCLONE_CONFIG_MYGS_TOKEN= \
  rclone copy MYS3:myawsbucket/path/to/file/ MYGS:mygooglebucket/path/to/files/
```
This example uses an ENV file:
```bash
docker run \
  --env-file env/sample.env \
  rclone copy MYS3:myawsbucket/path/to/file/ MYGS:mygooglebucket/path/to/files/
```


Lastly, you can use Docker Compose:
```bash
docker-compose up -d
```
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

## Step 1

You need to set environment variables to correctly run `crond` as a background process

* `RCLONE_CROND_SCHEDULE` crontab schedule `* * * * *` to perform sync every midnight
* `RCLONE_CROND_SOURCE_PATH` source location for `rclone copy` command
* `RCLONE_CROND_DESTINATION_PATH` destination location for `rclone copy` command
* `RCLONE_CROND_HEALTHCHECK_URL` used for healthcheck services to ping status like cronalarm, Cronitor.io, healthchecks.io...

This is what it would look like in your config:
```bash
RCLONE_CROND_SCHEDULE=*/5 * * * *
RCLONE_CROND_SOURCE_PATH="/tmp"
RCLONE_CROND_DESTINATION_PATH="MYS3:ob-testing/ebs"
RCLONE_CROND_HEALTHCHECK_URL=https://hchk.io/asads-aa12-ee23-qqw1-543e4c2ddv54385
```
Your crontab config file is generated automatically for you based on `RCLONE_CROND_SCHEDULE` and will look like this:
```bash
SHELL=/bin/bash
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
*/5 * * * * /usr/bin/env bash -c /rclone.sh 2>&1
```
The only thing you should change is the `RCLONE_CROND_SCHEDULE` run times like `*/15 * * * *` to `5 12 * * *` or whatever you prefer. Leave everything else as is.

## Step 2
In your environment file you need to make sure your source and destination remotes are set:
```
RCLONE_CROND_SOURCE_PATH=/temp
RCLONE_CROND_DESTINATION_PATH=MYS3:myawsbucket/path/to/file/
```
You need to put the full statement (remote names, buckets, paths...) for the source and destination for each variable. For example:
```
RCLONE_CROND_SOURCE_PATH=/temp
RCLONE_CROND_DESTINATION_PATH=MYS3:myawsbucket/path/to/file/
```

This will ensure that `rclone` knows where to look for the files and where you want them delivered.

# Setting Up SFTP Remotes
You can setup SFTP remotes. This allows you to upload or download files from an SFTP server. You can also do server to server transfers between two remotes. Lastly, if you want to pipeline data to Redshift, BigQuery, Athena or Spectrum via `rclone` this would be the path you would take following this documentation:
 https://github.com/openbridge/openbridge.github.io/blob/master/pipeline.md

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

This will output your remote buckets like this:

```
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
latest     | Master          | latest   | 3.6

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
