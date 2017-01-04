#!/usr/bin/env python

from __future__ import print_function # Python 2/3 compatibility
import boto3

dynamodb = boto3.resource('dynamodb', region_name='us-west-2')
client = boto3.client('dynamodb')


#table = dynamodb.Table('Movies')

#table.delete()

tables = client.list_tables()
tableNames = tables['TableNames']
print (tableNames)

for i in tableNames:
  print (i)
  table = dynamodb.Table(i)

  table.delete()
