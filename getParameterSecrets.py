import boto3

# Credential module name: getParameterSecrets.py
#Usage example:
#from getParameterSecrets import getCredentials
#dsdk_username, dsdk_password  = getCredentials('dev.apps.redshift.dsdk.user','dev.apps.redshift.dsdk.pass')

def getCredentials(*param_name):
    """
    This function reads a secure parameter from AWS' SSM service.
    The request must be passed a valid parameter name, as well as
    temporary credentials which can be used to access the parameter.
    The parameter's value is returned.
    """
    # Create the SSM Client
    ssm = boto3.client('ssm',
        region_name='us-east-1'
    )

    # Get the requested parameter
    response = ssm.get_parameters(
        Names=list(param_name),
        WithDecryption=True
    )

    # Check for Invalid Parameters
    if response['InvalidParameters']:
        raise Exception("InvalidParameters: " + str(response['InvalidParameters']))

    credentials = []

    # Store the credentials in a variable
    for name in param_name:
         for secret in response['Parameters']:
            if name == secret['Name']:
                 credentials.append(secret['Value'])


    return tuple(credentials)
