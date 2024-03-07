import boto3
from botocore.config import Config
import json
import sys
import uuid

def generate_bucket_unique_name(bucket_base_name):
    # Generate a GUID
    guid = str(uuid.uuid4())

    # Append the GUID to the base name
    unique_name = f"{bucket_base_name}-{guid}"

    # AWS S3 bucket names must be between 3 and 63 characters long
    # and can contain only lowercase letters, numbers, hyphens, and periods
    # Ensure the name length is within limits and replace any invalid characters
    unique_name = unique_name[:63].lower().replace('_', '-').replace('.', '-')

    return unique_name

def create_bucket_with_lifecycle(access_key_id, secret_access_key, session_token):
    # Read JSON config file
    config_file="config.json"
    with open(config_file, 'r') as f:
        config_json = json.load(f)

    # ... and extract information
    region_name = config_json['Region']
    bucket_base_name = config_json['BucketBaseName']
    lifecycle_configuration = config_json['LifecycleConfiguration']

    # Initialize AWS S3 client
    s3 = {}
    if session_token == "None":
        s3 = boto3.client(
            's3',
            aws_access_key_id=access_key_id,
            aws_secret_access_key=secret_access_key,
            region_name=region_name
        )
    else:
        s3 = boto3.client(
            's3',
            aws_access_key_id=access_key_id,
            aws_secret_access_key=secret_access_key,
            aws_session_token=session_token,
            region_name=region_name
        )

    # Create unique bucket name
    bucket_unique_name = generate_bucket_unique_name(bucket_base_name)

    # debug
    print(f"region_name={region_name}")
    print(f"bucket_unique_name={bucket_unique_name}")

    # Create bucket
    s3.create_bucket(
        Bucket=bucket_unique_name
    )

    # Apply lifecycle configuration to the bucket
    s3.put_bucket_lifecycle_configuration(
        Bucket=bucket_unique_name,
        LifecycleConfiguration=lifecycle_configuration
    )

    print(f"Bucket '{bucket_unique_name}' created with lifecycle configuration.")
    return bucket_unique_name

if __name__ == "__main__":
    if len(sys.argv) != 4:
        print("Usage: python script.py <access_key_id> <secret_access_key> <session_token>")
        sys.exit(1)

    access_key_id = sys.argv[1]
    secret_access_key = sys.argv[2]
    session_token = sys.argv[3]

    create_bucket_with_lifecycle(access_key_id, secret_access_key, session_token)
