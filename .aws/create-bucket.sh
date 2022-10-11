#!/usr/bin/env bash
set -x
echo "create bucket = topics"
awslocal s3 mb s3://topics
set +x
