#!/bin/bash

set -e

function die {
    echo "Error: $1" >&2
    exit 1
}

function cleanup {
    rm -rf $SOURCE_DIR
    rm $LOCK_DIR/pipeline.lock
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

. $SCRIPT_DIR/config.sh

if [ -f PIPELINE_LOCK_FILE ]; then
    die "Lock file exists $PIPELINE_LOCK_FILE"
fi
touch $PIPELINE_LOCK_FILE

rm -rf $SOURCE_DIR
mkdir -p $WORK_DIR $SOURCE_DIR $LOCK_DIR $LOG_DIR $STATE_DIR $ARTIFACT_DIR

# get last echo, should contain result of Polling
POLL_RESULT=$($SCRIPT_DIR/poll.sh | tee -a $LOG_FILE | tail -n1)

echo "POLL RES $POLL_RESULT"

if [ "$POLL_RESULT" != "has-changes" ]; then 
    cleanup
    echo "No changes detected, exiting"
    exit
fi

pushd $SOURCE_DIR &> /dev/null
. $SCRIPT_DIR/run.sh || "$SCRIPT_DIR/run.sh failed on error"
popd &> /dev/null

cleanup
exit