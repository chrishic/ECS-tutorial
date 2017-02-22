#!/bin/bash

usage() { echo "Usage: $0 <CLUSTER_NUM>"; echo "=> Valid cluster num (1-4)" 1>&2; exit 1; }

if [ "$#" -ne 1 ]; then
    usage;
fi

CLUSTER_NUM=$(($1 + 0))

if [[ $CLUSTER_NUM -lt 1 || $CLUSTER_NUM -gt 4 ]]; then
    usage;
fi

SERVICE_NAME="tutorial-$CLUSTER_NUM"
CLUSTER_NAME="$SERVICE_NAME"
TASK_DEFINITION_NAME="ecs-$SERVICE_NAME"
ECS_TASK_JSON="ecs-task.json"

IMAGE="nginx:alpine"

die() {
    echo >&2 "=> ERROR: $@"
    exit 1
}

# Verify jq is installed
if ! type jq > /dev/null 2>&1; then
    die "jq is a required dependency. To install, 'brew install jq'."
fi

# Verify that AWS CLI is properly configured
if [[ -z "$AWS_ACCESS_KEY_ID" || -z "$AWS_SECRET_ACCESS_KEY" || -z "$EC2_REGION" ]]; then
    die "AWS CLI not properly configured. Missing: AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, and/or EC2_REGION."
fi

echo "Deploying..."

# Splice task name into ECS task template
CLI_JSON=`cat $ECS_TASK_JSON | sed -e 's@__SERVICE_NAME__@'"$SERVICE_NAME"'@'`

# Splice image name into ECS task template
CLI_JSON=`echo $CLI_JSON | sed -e 's@__IMAGE__@'"$IMAGE"'@'`

# Create new task definition with ECS
aws ecs register-task-definition --cli-input-json "$CLI_JSON" > /dev/null 2>&1
if [[ $? != 0 ]]; then
    die "ECS register-task-definition failed."
fi

# Verify ECS service exists
SERVICE_DESCRIPTOR=$(aws ecs describe-services --cluster $CLUSTER_NAME --service $SERVICE_NAME | jq "(.services[] | select((.status==\"ACTIVE\") and .serviceName==\"$SERVICE_NAME\"))")
if [[ -z "$SERVICE_DESCRIPTOR" ]]; then
    # Service doesn't exist - create it
    echo "ECS service, $SERVICE_NAME, does not exist. Creating it."
    aws ecs create-service --cluster $CLUSTER_NAME --service-name $SERVICE_NAME --task-definition $TASK_DEFINITION_NAME --desired-count 1 --deployment-configuration maximumPercent=200,minimumHealthyPercent=0 > /dev/null 2>&1
    if [[ $? != 0 ]]; then
        die "Failed to create ECS service, $SERVICE_NAME.";
    fi
fi

# Now update the ECS service with the new task definition
aws ecs update-service --cluster $CLUSTER_NAME --service $SERVICE_NAME --task-definition $TASK_DEFINITION_NAME > /dev/null 2>&1
if [[ $? != 0 ]]; then
    die "ECS update-service failed."
fi

echo "Successfully deployed."
