#!/bin/bash
set -e
echo "Executing script"
gcc main.c -o $ARTIFACT_DIR/program
