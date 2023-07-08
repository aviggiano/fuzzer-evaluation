#!/usr/bin/env bash

set -eux
S3_BUCKET="$1"
RESULTS=$(mktemp)
FINAL=/tmp/final.csv

DIR=$(mktemp -d)
aws s3 sync s3://$S3_BUCKET/ $DIR

for FILE in $(find $DIR -type f | grep -v 'old/' | grep 'results.txt'); do
	INSTANCE_ID=$(echo $FILE | awk -F'/' '{print $(NF-1)}')
	head -1 $FILE | sed "s/$/,instance_id/" > $FINAL
	cat $FILE | sed "s/$/,$INSTANCE_ID/"  >> $RESULTS
done;

sed '/fuzzer/d' $RESULTS >> $FINAL
sed -i '/.*,.*,.*,01,.*,i/d' $FINAL
sed -i '/.*,.*,.*,02,.*,i/d' $FINAL
sed -i '/.*,.*,.*,04,.*,i/d' $FINAL
sed -i '/.*,.*,.*,.*,0,i/d' $FINAL

cat $FINAL | sort -r -t, -k3,4 > $RESULTS
mv $RESULTS $FINAL

cd analysis
python3 -m analysis