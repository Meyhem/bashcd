#!/bin/bash

set -e
set -o pipefail

function die {
    echo "Error: $1" >&2
    exit 1
}

function cleanup {
    rm -rf $SOURCE_DIR
    rm $LOCK_DIR/pipeline.lock

    if [ $PIPELINE_STATUS != "nochange" ] || [ "$KEEP_NOCHANGE_LOGS" == "true" ]; then
        mv $LOG_FILE $LOG_DIR/$PIPELINE_RUN_ID-$PIPELINE_STATUS.log
    else
        rm $LOG_FILE
    fi
}

if [ -z "$WORK_DIR" ]; then
    die "WORK_DIR not defined"
fi

export SCRIPT_DIR=$(dirname "$0" | xargs realpath)
export PIPELINE_RUN_ID=$(date +"%Y%m%d%H%M%S")
export WORK_DIR=$(realpath $WORK_DIR)
export SOURCE_DIR=$WORK_DIR/source
export LOCK_DIR=$WORK_DIR/lock
export LOG_DIR=$WORK_DIR/log
export LOG_FILE=$LOG_DIR/$PIPELINE_RUN_ID.log
export STATE_DIR=$WORK_DIR/state
export ARTIFACT_DIR=$WORK_DIR/artifact
export PIPELINE_LOCK_FILE=$LOCK_DIR/pipeline.lock
export LOG_RETENTION_DAYS="+1"
export KEEP_NOCHANGE_LOGS=false

PIPELINE_STATUS="success"

. $SCRIPT_DIR/config.sh

if [ -f PIPELINE_LOCK_FILE ]; then
    die "Lock file exists $PIPELINE_LOCK_FILE"
fi
touch $PIPELINE_LOCK_FILE

rm -rf $SOURCE_DIR
mkdir -p $WORK_DIR $SOURCE_DIR $LOCK_DIR $LOG_DIR $STATE_DIR $ARTIFACT_DIR

# remove all logs except configured retention
find $LOG_DIR -type f -name "*.log" -mtime +$LOG_RETENTION_DAYS -delete

# get last echo, should contain result of Polling
set +e
POLL_RESULT=$($SCRIPT_DIR/poll.sh 2>&1 | tee -a $LOG_FILE | tail -n1)
POLL_EXIT=$?
set -e

if [ $POLL_EXIT != "0" ]; then
    PIPELINE_STATUS="pollfailed"
    echo "Poll failed with non-zero status, exiting" >> $LOG_FILE
    cleanup
    exit 1
fi

if [ "$POLL_RESULT" != "has-changes" ]; then 
    PIPELINE_STATUS="nochange"
    echo "No changes detected, exiting" >> $LOG_FILE
    cleanup
    exit
fi

pushd $SOURCE_DIR > /dev/null
set +e
$SCRIPT_DIR/run.sh >> $LOG_FILE 2>&1
EXEC_EXIT=$?
set -e
popd > /dev/null

if [ $EXEC_EXIT != "0" ]; then
    echo "Execution failed with non-zero status, exiting" >> $LOG_FILE
    PIPELINE_STATUS="execfailed"
    cleanup
    exit 1
fi

cleanup
