#!/usr/bin/env python

from __future__ import print_function # Python 2/3 compatibility
import boto3

dynamodb = boto3.resource('dynamodb', region_name='us-west-2')
client = boto3.client('dynamodb')

## Add admin user to db
usersTable = dynamodb.Table('users')

usersTable.put_item(
  Item={
    'email': 'admin@mentii.me',
    'password': 'ce8f8a02b2e2741a6e79e62280d3b5ec',
    'activationId': '8411262d-a5e0-40f5-8397-47d2daa7182f',
    'active': 'T',
    'userRole': 'admin'
  }
)
