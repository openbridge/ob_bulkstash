# How to run

## TL;DR (summary)
To run this container do:
```
$ docker run crc python3 wrapper.py --settings 'settings_string' rclone <rclone_command> SOURCE:/path/to/[file] [DESTINATION:/path/to/]
```

settings_string: is a JSON encoded python dictionary that creates the rclone source/destination configuration.

All rclone options are supported.

## Full description

To run this container, Run this container with the following command:

Input should be a JSON string like the example below.
The keys of the dictionary vary with "type" and can be used either in source or destination

Example:
```
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
```

Tip: a python dictionary can be encoded as a JSON string doing:
```
import json
json_str = json.dumps(python_dictionary)
```

The docker container may be ran as:
```
$ docker run crc python3 wrapper.py --settings '{"source": {"TYPE": "sftp", "HOST": "annalectftp.annalect.com", "USER": "annalect_admin", "PORT": "22", "PASS": "1_TDlwcU4bLs0nQfMLZRQMH5y1_vFllo"}, "destination": {"TYPE": "s3", "ACCESS_KEY_ID": "AKIAJ6FYEG56CL3RNQIA", "SECRET_ACCESS_KEY": "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", "SERVER_SIDE_ENCRYPTION": "AES256", "STORAGE_CLASS": "REDUCED_REDUNDANCY"}}' rclone ls DESTINATION:/annalect-adt/
```