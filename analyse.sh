#!/usr/bin/env bash

set -eux
S3_BUCKET="$1"
RESULTS=$(mktemp)
FINAL=/tmp/final.csv

for FILE in $(aws s3 ls --recursive s3://$S3_BUCKET/ | grep 'results.txt' | awk '{print $NF}'); do
	OUT=$(mktemp)
	aws s3 cp s3://$S3_BUCKET/$FILE $OUT
	cat $OUT >> $RESULTS
done;

TMP=$(mktemp)
head -1 $RESULTS > $TMP
sed '/fuzzer/d' $RESULTS >> $TMP
mv $TMP $FINAL

cd analysis
python3 -m analysis