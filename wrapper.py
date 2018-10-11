#!/bin/python3

import argparse
import sys
import json
import subprocess
import os

"""
For instructions on how to use, please refer to README.md file
"""

parser = argparse.ArgumentParser(description='Helper to create S3 buckets')

parser.add_argument("-s", "--settings", default=None,
                    help = "Name of the bucket when bucket")

parser.add_argument('commands', nargs=argparse.REMAINDER)

args = parser.parse_args()

if args.settings is None:
    json_example = """
    {
        "source": {
            "TYPE":"sftp",
            "HOST":"url",
            "USER":"username",
            "PORT":"22",
            "PASS":"passwd"
        },
        "destination": {
            "TYPE":"s3",
            "ACCESS_KEY_ID":"ACCESSKEY",
            "SECRET_ACCESS_KEY":"AWSSECRET",
            "SERVER_SIDE_ENCRYPTION":"AES256",
            "STORAGE_CLASS":"REDUCED_REDUNDANCY"
        }
    }
    """
    input_str = json.dumps(json.loads(json_example))
    print(f"Error: Please specify a first parameter. Input argument example: \n\n{input_str}")
    sys.exit(1)

input_dict = json.loads(args.settings)
input_str = json.dumps(input_dict, indent=4)
print(f"using settings: {input_str}")

# setting environment variable
for _type in ["source", "destination"]:
    typeupper = _type.upper()
    for key, value in input_dict[_type].items():
        keyupper = key.upper()
        varname = f"RCLONE_CONFIG_{typeupper}_{keyupper}"
        os.environ[varname] = value
        # print(f"export {varname}={value}")

print("Executing command:")
command = " ".join(args.commands)
print(command)
# sys.exit()
try:
    ret = subprocess.check_output(command, stderr=subprocess.STDOUT, shell=True)
    print("--output--")
    print(ret.decode())
except subprocess.CalledProcessError as e:
    print("--error--")
    print(e.output.decode())
    print(e)
