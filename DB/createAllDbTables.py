#!/usr/bin/env python

from __future__ import print_function # Python 2/3 compatibility
import boto3

dynamodb = boto3.resource('dynamodb', region_name='us-west-2')

## USERS Table
usersTable = dynamodb.create_table(
    TableName='users',
    KeySchema=[
        {
            'AttributeName': 'email',
            'KeyType': 'HASH'  #Partition key
        }
    ],
    AttributeDefinitions=[
        {
            'AttributeName': 'email',
            'AttributeType': 'S'
        }
    ],
    ProvisionedThroughput={
        'ReadCapacityUnits': 1,
        'WriteCapacityUnits': 1
    }
)

## Classes Table
classesTable = dynamodb.create_table(
    TableName='classes',
    KeySchema=[
        {
            'AttributeName': 'code',
            'KeyType': 'HASH'  #Partition key
        }
    ],
    AttributeDefinitions=[
        {
            'AttributeName': 'code',
            'AttributeType': 'S'
        }
    ],
    ProvisionedThroughput={
        'ReadCapacityUnits': 1,
        'WriteCapacityUnits': 1
    }
)

## Books Table
booksTable = dynamodb.create_table(
    TableName='books',
    KeySchema=[
        {
            'AttributeName': 'bookId',
            'KeyType': 'HASH'  #Partition key
        }
    ],
    AttributeDefinitions=[
        {
            'AttributeName': 'bookId',
            'AttributeType': 'S'
        }
    ],
    ProvisionedThroughput={
        'ReadCapacityUnits': 1,
        'WriteCapacityUnits': 1
    }
)

if (usersTable.wait_until_exists()):
  print('Failed to create users table', file=sys.stderr)
  sys.exit(1)
else:
  print('Users table created.')

if (classesTable.wait_until_exists()):
  print('Failed to create classes table', file=sys.stderr)
  sys.exit(1)
else:
  print('Classes table created.')

if (booksTable.wait_until_exists()):
  print('Failed to create books table', file=sys.stderr)
  sys.exit(1)
else:
  print('Books table created.')
