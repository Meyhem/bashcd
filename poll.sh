#!/bin/bash
set -e
echo "Executing GIT poll"

git clone $GIT_REPO $SOURCE_DIR --quiet
pushd $SOURCE_DIR > /dev/null
git checkout $GIT_BRANCH --quiet

HEAD_HASH=$(git rev-parse HEAD)
STATE_FILE=$STATE_DIR/$GIT_BRANCH-head

# no state yet or state has different commit hash
if [ ! -f $STATE_FILE ] || [ "$(cat $STATE_FILE)" != "$HEAD_HASH" ]; then
    echo $HEAD_HASH > $STATE_FILE
    echo "has-changes"
    exit
fi

echo "no-changes"
