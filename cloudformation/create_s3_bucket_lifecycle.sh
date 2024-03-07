#!/bin/bash

# Check if jq is installed
if ! command -v jq &> /dev/null; then
    echo "jq is not installed. Please install it."
    exit 1
fi

# Check if AWS CLI is installed
if ! command -v aws &> /dev/null; then
    echo "AWS CLI is not installed. Please install it."
    exit 1
fi

# Check if required arguments are provided
if [ $# -ne 3 ]; then
    echo "Usage: $0 <access_key_id> <secret_access_key> <session_token>"
    exit 1
fi

# Check if the JSON config file exists
config_file="config.json"
if [ ! -f "$config_file" ]; then
    echo "Error: config file '$config_file' not found"
    exit 1
fi

# Check if the YAML cloudformation config file exists
cloudformation_config_file="cloudformation_config.yaml"
if [ ! -f "$cloudformation_config_file" ]; then
    echo "Error: config file '$cloudformation_config_file' not found"
    exit 1
fi

# Read JSON config file and extract information
region_name=$(jq -r '.Region' "$config_file")
bucket_base_name=$(jq -r '.BucketBaseName' "$config_file")
stack_base_name=$(jq -r '.StackBaseName' "$config_file")

# Create unique names for the bucket and the stack
guid=$(uuidgen)
bucket_unique_name="$bucket_base_name-$guid"
stack_unique_name="$stack_base_name-$guid"

# Read the contents of the YAML cloudformation config file and 
# inject our unique bucket name
cloudformation_config_yaml=$(cat "$cloudformation_config_file")
cloudformation_yaml=${cloudformation_config_yaml//BUCKET_UNIQUE_NAME/$bucket_unique_name}

# Write out the cloudformation template file
cloudformation_file="cloudformation.yaml"
echo "$cloudformation_yaml" > "$cloudformation_file"

# debug
echo "region_name=$region_name"
echo "bucket_unique_name=$bucket_unique_name"
echo "stack_unique_name=$stack_unique_name"

# export our credentials
export AWS_ACCESS_KEY_ID="$1"
export AWS_SECRET_ACCESS_KEY="$2"
if [ "$3" != "None" ]; then
    export AWS_SESSION_TOKEN="$3"
fi

# Create the CloudFormation stack
aws cloudformation create-stack --stack-name "$stack_unique_name" --template-body file://"$cloudformation_file" --region "$region_name" --capabilities CAPABILITY_IAM --parameters ParameterKey=BucketName,ParameterValue="$bucket_unique_name"
