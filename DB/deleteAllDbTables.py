#!/usr/bin/env python

from __future__ import print_function # Python 2/3 compatibility
import boto3

dynamodb = boto3.resource('dynamodb', region_name='us-west-2')
client = boto3.client('dynamodb')

tables = client.list_tables()
tableNames = tables['TableNames']

for i in tableNames:
  print ("Deleting " + i + "table")
  table = dynamodb.Table(i)

  table.delete()
