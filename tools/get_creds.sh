#!/bin/bash
set -e

usage() { echo "Usage: $0 [ -b <BUCKET> ] [ -k <KEY> ]" ] 1>&2; exit 1; }

BUCKET=

while getopts ":b:k:" flag; do
  case "${flag}" in
    b) BUCKET=${OPTARG} ;;
    k) KEY=${OPTARG} ;;
    *) usage ;;
  esac
done

if [[ -z $BUCKET || -z $KEY ]]; then
    usage;
fi

OUTPUT_FILENAME="${KEY##*/}"

# Retrieve encrypted file from S3
aws s3 cp s3://$BUCKET/$KEY tmp.encrypt

# Decrypt
aws kms decrypt --ciphertext-blob fileb://tmp.encrypt --query Plaintext --output text | base64 --decode > $OUTPUT_FILENAME
echo "Wrote $OUTPUT_FILENAME"

# Cleanup
rm tmp.encrypt
