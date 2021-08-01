#!/bin/bash

echo "Executing GIT poll"

git clone $GIT_REPO $SOURCE_DIR --quiet
pushd $SOURCE_DIR
git checkout $GIT_BRANCH --quiet

HEAD_HASH=$(git rev-parse HEAD)
STATE_FILE=$STATE_DIR/$GIT_BRANCH-head

echo "HASH $HEAD_HASH"
echo "FILE $(cat $STATE_FILE)"

# no state yet or state has different commit hash
if [ ! -f $STATE_FILE ] || [ "$(cat $STATE_FILE)" != "$HEAD_HASH" ]; then
    echo $HEAD_HASH > $STATE_FILE
    echo "has-changes"
    exit
fi

echo "no-changes"
