# BashCD

Simple cron-friendly polling continuous deployment script.

- [Setup](#1-configure-configsh)
- [Variables](#-variables)
- [Polling](#-polling---pollsh)
- [Logs](#-logs)
- [Locks](#-locks)

## &bull; Setup
### 1. Configure `config.sh`
```sh
# Url of the git repo to be cloned (may contain creds)
export GIT_REPO="<<repo url>>"
# branch to checkout
export GIT_BRANCH="<<branch to poll>>"
# delete logs older that n days
export LOG_RETENTION_DAYS=1
# keep logs of runs that didn't detect change (maybe good for debug)
export KEEP_NOCHANGE_LOGS=false
```
### 2. Implement `run.sh`
Add your custom `run.sh` implementation, CWD for the script is source code downloaded by `poll.sh` ($SOURCE_DIR).

`run.sh` will be ran only when `poll.sh` determines a change.

Preferably always `set -e` as the pipeline handles failed scripts gracefully.

### 3. Test 
You must set ENV var WORK_DIR where all intermediate files will be stored. It should be persistent store (not /tmp). 
Then execute.
```sh
WORK_DIR=./cdpipeline ./bashcd.sh
```
### 4. CRON
Register tested command as CRON job.

## &bull; Variables
BashCD sets some variables for you to use during running of your script `run.sh`

```sh
# contains unique identifier of job instance
$PIPELINE_RUN_ID

# Absolute path of directory containing source code of polled app
$SOURCE_DIR 

# Absolute path to file that contains log for current job instance, always append >> to it. All stdout/stderr of run.sh is redirected there by default.
$LOG_FILE 

# Absolute path to dir where to put built binaries etc...
$ARTIFACT_DIR 
```

## &bull; Polling - poll.sh
By default it contains GIT poller that checks whether there is new HEAD hash in git repo and compares it with previous poll.

`poll.sh` is expected to download all necessary sources and put them into $SOURCE_DIR and print either "has-changes" or "no-changes".

It should store its current state into $STATE_DIR which is persisted for next runs.

## &bull; Logs
All outputs of `poll.sh` and `run.sh` are stored into log files that are located at `$WORK_DIR/logs`. Filename always contains timestamp and result of pipeline e.g. _20210803090340-success.log_, _20210803090348-execfailed.log_, _20210803090514-nochange.log_, 20210803090609-pollfailed.log

Logs are deleted based on $LOG_RETENTION_DAYS. 

If $KEEP_NOCHANGE_LOGS is not set to "true" then _nochange_ logs are deleted after run to prevent unnecessary log files.

## &bull; Locks
On job startup a lockfile is created that prevents running another same job in parallel. Early bird gets the worm.

License MIT
