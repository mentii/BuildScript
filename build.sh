#!/bin/bash

## $1 : branch_name

if [ $# -eq 0 ]
  then
    echo "No arguments supplied"
    exit 1
fi

## Get current git repo
cd /home/asp78/git/
rm -rf ./mentii/
git clone https://github.com/mentii/mentii.git
cd ./mentii/
git checkout $1

## Remove .git and .gitignore
echo "REMOVING .git AND .gitignore FILES"
git_last=`git log --pretty=format:'%h' -n 1`
rm -rf ./.git/ ./.gitignore

## Build
echo "BUILDING PROJECT"
make compile

## Remove unused files
echo "REMOVING UNUSED FILES"
find . -name "*.js.map" -type f -delete
find . -name "*.ts" -type f -delete


## Tar it up and move it
cd /home/asp78/git/
echo "TARING UP AND MOVING PROJECT"
tar -cf build.tar ./mentii
mv --backup=numbered ./build.tar /home/asp78/public_html/builds/build.tar

## Delete repo
cd ./mentii
#rm -rf ./mentii/

## Send slack notification
date=`date`
/home/asp78/slacknotify.sh "Build Complete at $date. Latest commit: $git_last"
echo "DONE!"
