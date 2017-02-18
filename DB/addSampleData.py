#!/usr/bin/env python

from __future__ import print_function # Python 2/3 compatibility
import boto3

dynamodb = boto3.resource('dynamodb', region_name='us-west-2')
client = boto3.client('dynamodb')

## Add a few classes, and a user who's enrolled in some
usersTable = dynamodb.Table('users')
classesTable = dynamodb.Table('classes')

activitiesList = [
    {'title':'Week 1'},
    {
        'title':'Week 2',
        'description':'These got fractions"'
    },
    {
        'title':'Week 3',
        'description':'These got roots',
        'targetDate':'Monday Mar 13 2017 17:13:04 GMT-0500 (EST)'
    }]

studentSet = set(['student@mentii.me'])

classesTable.put_item(
  Item={
    'title': 'Algebra I',
    'description': 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Pellentesque hendrerit mi at massa suscipit, sollicitudin euismod felis lacinia. Phasellus malesuada, enim vitae ultricies ullamcorper, orci eros vestibulum sem, vel tristique justo est ac nisl. Ut sagittis orci feugiat nisi pharetra, ac iaculis odio placerat. Duis ornare congue ultricies. Ut sed commodo neque.',
    'code': 'd26713cc-f02d-4fd6-80f0-026784d1ab9b',
    'department': 'School of Math',
    'section': '001',
    'activities': activitiesList,
    'students': studentSet
  }
)

classesTable.put_item(
  Item={
    "title": "Biology 121",
    "description": "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Pellentesque hendrerit mi at massa suscipit, sollicitudin euismod felis lacinia. Phasellus malesuada, enim vitae ultricies ullamcorper, orci eros vestibulum sem, vel tristique justo est ac nisl. Ut sagittis orci feugiat nisi pharetra, ac iaculis odio placerat. Duis ornare congue ultricies. Ut sed commodo neque.",
    "code": "d93cd63f-6eda-4644-b603-60f51142749e",
    'section': '002'
  }
)

classesTable.put_item(
  Item={
    "title": "Business Accounting",
    "description": "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Pellentesque hendrerit mi at massa suscipit, sollicitudin euismod felis lacinia. Phasellus malesuada, enim vitae ultricies ullamcorper, orci eros vestibulum sem, vel tristique justo est ac nisl. Ut sagittis orci feugiat nisi pharetra, ac iaculis odio placerat. Duis ornare congue ultricies. Ut sed commodo neque.",
    "code": "93211750-a753-41cc-b8dc-904d6ed2f931",
    'department': 'School of Business'
  }
)

classCodes = set(['d26713cc-f02d-4fd6-80f0-026784d1ab9b', 'd93cd63f-6eda-4644-b603-60f51142749e'])

usersTable.put_item(
  Item={
    'email': 'student@mentii.me',
    'password': '5f4dcc3b5aa765d61d8327deb882cf99',
    'activationId': '1231262d-a5e0-40f5-8397-47d2daa7182f',
    'active': 'T',
    'userRole': 'student',
    'classCodes': classCodes
  }
)

classCodes = set(['93211750-a753-41cc-b8dc-904d6ed2f931'])
teachingCodes = set(['d26713cc-f02d-4fd6-80f0-026784d1ab9b'])

usersTable.put_item(
  Item={
    'email': 'teacher@mentii.me',
    'password': '5f4dcc3b5aa765d61d8327deb882cf99',
    'activationId': '1234262d-a5e0-40f5-8397-47d2daa7182f',
    'active': 'T',
    'userRole': 'teacher',
    'classCodes': classCodes,
    'teaching': teachingCodes
  }
)
