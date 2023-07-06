#!/usr/bin/env bash

set -eux
S3_BUCKET="$1"
RESULTS=$(mktemp)
FINAL=/tmp/final.csv

for FILE in $(aws s3 ls --recursive s3://$S3_BUCKET/ | grep 'results.txt' | awk '{print $NF}'); do
	INSTANCE_ID=$(echo $FILE | awk -F'/' '{print $(NF-1)}')
	TMP=$(mktemp)
	aws s3 cp s3://$S3_BUCKET/$FILE $TMP
	head -1 $TMP | sed "s/$/,instance_id/" > $FINAL
	cat $TMP | sed "s/$/,$INSTANCE_ID/"  >> $RESULTS
done;

sed '/fuzzer/d' $RESULTS >> $FINAL

cd analysis
python3 -m analysis