#!/bin/bash
set -e

KMS_KEY="tutorial-master"

usage() { echo "Usage: $0 [ -b <BUCKET> ] [ -k <KEY> ] [ -f <PUT_FILE>" ] 1>&2; exit 1; }

BUCKET=

while getopts ":b:k:f:" flag; do
  case "${flag}" in
    b) BUCKET=${OPTARG} ;;
    k) KEY=${OPTARG} ;;
    f) PUT_FILE=${OPTARG} ;;
    *) usage ;;
  esac
done

if [[ -z $BUCKET || -z $KEY || -z $PUT_FILE ]]; then
    usage;
fi

if [ ! -f $PUT_FILE ]; then
    echo "** Unable to find specified put_file, $PUT_FILE.";
    exit 1
fi

# Encrypt local file
aws kms encrypt --key-id alias/$KMS_KEY --plaintext fileb://$PUT_FILE --output text --query CiphertextBlob | base64 --decode > tmp.encrypt

# Copy encrypted file to S3
aws s3 cp --sse AES256 tmp.encrypt s3://$BUCKET/$KEY
echo "Wrote file, $PUT_FILE, to $BUCKET/$KEY."

# Cleanup
rm tmp.encrypt
