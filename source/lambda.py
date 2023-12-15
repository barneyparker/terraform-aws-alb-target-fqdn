import socket
import boto3
import math
import os

elb = boto3.client('elbv2')

def handler(event, context):

    # Get a list of target groups
    TargetGroupArns = []
    # Get a paginator
    targetgroup_paginator = elb.get_paginator('describe_target_groups')
    targetgroup_iterator = targetgroup_paginator.paginate()

    # Iterate it!
    for result in targetgroup_iterator:
        for target in result['TargetGroups']:
            TargetGroupArns.append(target['TargetGroupArn'])

    # Get all the tags
    tags = []
    # Use batches of 20 because thats the most we can pass to describe_tags
    for index in range(math.ceil(len(TargetGroupArns)/20)):
        theseTags = elb.describe_tags(
            ResourceArns = TargetGroupArns[(index*20):(index*20)+20]
        )
        tags = tags + theseTags['TagDescriptions']


    # Filter the tags to only those with FQDN
    FQDNTargets = []
    for target in tags:
        for tag in target['Tags']:
            if tag['Key'] == os.environ['FQDN_TAG']:
                # Make sure the tag isn't empty
                if tag['Value'] != '':
                    ob = {
                        'Arn': target['ResourceArn'],
                        'FQDN': tag['Value']
                    }
                    FQDNTargets.append(ob)

    # Iterate through the targets and register them
    for target in FQDNTargets:
        print('Target Group: ' + target['Arn'])
        print('FQDN: ' + target['FQDN'])
        # Do a DNS lookup
        try:
            answers = socket.gethostbyname_ex(target['FQDN'])
            print('Resolved: ', answers[2])

            # Create registration parameters
            regTargets = []
            for addr in answers[2]:
                newtarget = {
                    'Id': addr,
                    'AvailabilityZone': 'all',
                }
                regTargets.append(newtarget)

            print(regTargets)

            # Register all of these IPs as targets
            status = elb.register_targets(
                TargetGroupArn = target['Arn'],
                Targets = regTargets
            )

            # check the status of the targets
            health = elb.describe_target_health(
                TargetGroupArn = target['Arn']
            )
            print(health)

            # Remove any targets not in our latest list
            deregTargets = []
            for curTarget in health['TargetHealthDescriptions']:
                if curTarget['Target']['Id'] not in answers[2]:
                    print('Deregistering Target:')
                    print(curTarget['Target'])
                    deregTargets.append(curTarget['Target'])

            if(len(deregTargets) > 0):
                print(deregTargets)
                elb.deregister_targets(
                    TargetGroupArn = target['Arn'],
                    Targets = deregTargets
                )

        except socket.gaierror:
            print('Failure Resolving: ' + target['FQDN'])
        except Exception as e:
            print(e)

        print('-------')
    return {
        'message' : 'done'
    }

handler({}, {})