#!/usr/bin/env python

from __future__ import print_function # Python 2/3 compatibility
import boto3

dynamodb = boto3.resource('dynamodb', region_name='us-west-2')
client = boto3.client('dynamodb')

## Add a few classes, and a user who's enrolled in some
usersTable = dynamodb.Table('users')
classesTable = dynamodb.Table('classes')
booksTable = dynamodb.Table('books')

## Add classes
activitiesList = [
    {
        'title':'Basic Addition and Subtraction', 
        'bookId': '13382a2d-a5e0-42f5-8397-47d2bac7182f', 
        'chapterTitle': 'Chapter 1', 
        'sectionTitle': 'Section 1'
    },
    {
        'title':'Positive and Negative Numbers',
        'bookId': '13382a2d-a5e0-42f5-8397-47d2bac7182f', 
        'chapterTitle': 'Chapter 1', 
        'sectionTitle': 'Section 2'
    },
    {
        'title':'Multiplication and Division',
        'bookId': '13382a2d-a5e0-42f5-8397-47d2bac7182f', 
        'chapterTitle': 'Chapter 1', 
        'sectionTitle': 'Section 3'
    }, 
    {
        'title':'Advanced Problems',
        'bookId': '13382a2d-a5e0-42f5-8397-47d2bac7182f', 
        'chapterTitle': 'Chapter 1', 
        'sectionTitle': 'Section 4'
    } 
    ]

studentSet = set(['student@mentii.me'])
'''
classesTable.put_item(
  Item={
    'title': 'Algebra I',
    'description': 'This class contains activities realted to solving algebra 1 problems. This includes: Solving for a variable involving manipulation of both positive and negative numbers, solving for a variable involving manipulation of numbers using multiplication and division, and more complex problems with these concepts.',
    'code': 'd26713cc-f02d-4fd6-80f0-026784d1ab9b',
    'department': 'Math',
    'classSection': '001',
    'activities': activitiesList,
    'students': studentSet
  }
)
'''

classCodes = set(['d26713cc-f02d-4fd6-80f0-026784d1ab9b'])

## Add user
usersTable.put_item(
  Item={
    'email': 'student@mentii.me',
    'password': 'ce8f8a02b2e2741a6e79e62280d3b5ec',
    'activationId': '1231262d-a5e0-40f5-8397-47d2daa7182f',
    'active': 'T',
    'userRole': 'student'
  #  'classCodes': classCodes
  }
)

#teachingCodes = set(['d26713cc-f02d-4fd6-80f0-026784d1ab9b'])

usersTable.put_item(
  Item={
    'email': 'teacher@mentii.me',
    'password': 'ce8f8a02b2e2741a6e79e62280d3b5ec',
    'activationId': '1234262d-a5e0-40f5-8397-47d2daa7182f',
    'active': 'T',
    'userRole': 'teacher'
    #'teaching': teachingCodes
  }
)
'''
## Add sample book
booksTable.put_item(
  Item={
    'bookId':'13382a2d-a5e0-42f5-8397-47d2bac7182f',
    'title':'Foundations of Algebra I',
    'description':'An introduction to algebra concepts',
    'chapters': [
      {
        'title': 'Chapter 1',
        'sections' : [
          {
            'title': 'Section 1',
            'problems' : [
              {
                'problemString' : '$var + $b $op $d = $c|0|10|+ -'
              },
              {
                'problemString' : '$b - $var $op $c = 22|0|20|+ -'
              }
            ]
          },
          {
            'title': 'Section 2',
            'problems' : [
              {
                'problemString' : '$var + $b $op $d = $c|-10|10|+ -'
              },
              {
                'problemString' : '$b - $a - $var $op $c = $d|-20|20|+ -'
              },
              {
                'problemString' : '$a - ($var $op $c) = $d|-20|20|+ -'
              }
            ]
          },
          {
            'title': 'Section 3',
            'problems' : [
              {
                'problemString' : '$a$var + $b = $c|0|10|+ - * /'
              },
              {
                'problemString' : '$var $op $b - $d = $c|-10|10|* /'
              },
              {
                'problemString' : '$a$var = $c $op $a|-5|5|+ * /' 
              },
              {
                'problemString' : '$a($var - $b) = $c $op $a|-5|5|+ * /' 
              }
            ]
          },
          {
            'title': 'Section 4',
            'problems' : [
              {
                'problemString' : '$a($var - $b) $op $c = $d |-25|25|+ * / -' 
              },
              {
                'problemString' : '$var * ($a + $b) + $a$var $op $d = $c|-25|25|+ * /' 
              },
              {
                'problemString' : '$amulb$var + $b * ($var / $a) = $c $op $d|-15|15|+ * /' 
              }
            ]
          }

        ]
      },
      {
        'title': 'Chapter 2',
        'sections' : [
          {
            'title': 'Section 1',
            'problems' : [
              {
                'problemString' : '$b - $var $op $c = $a'
              }
            ]
          },
          {
            'title': 'Section 2',
            'problems' : [
              {
                'problemString' : '8x-9x=7'
              }
            ]
          }
        ]
      },
      {
        'title': 'Chapter 3',
        'sections' : [
          {
            'title': 'Section 1',
            'problems' : [
              {
                'problemString' : '6+9x=53'
              }
            ]
          },
          {
            'title': 'Section 2',
            'problems' : [
              {
                'problemString' : '7+4x=77'
              }
            ]
          }
        ]
      }
    ]
  }
)
'''
