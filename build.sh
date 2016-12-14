#!/bin/bash

## $1 : branch_name

## Update git repo
echo "UPDATING GIT REPO"
cd /home/asp78/git/mentii
git fetch
git clean -fd
git checkout $1
git pull

## Remove .git and .gitignore
echo "REMOVING .git AND .gitignore FILES"
mv ./.git/ ../
mv ./.gitignore ../

## Build
echo "BUILDING PROJECT"
make compile
find . -name "*.js.map" -type f -delete
find . -name "*.ts" -type f -delete
cd ..


## Tar it up and move it
echo "TARING UP AND MOVING PROJECT"
tar -cf build.tar ./mentii
mv --backup=numbered ./build.tar /home/asp78/public_html/builds/build.tar

## Replace  .git and .gitignore
cd /home/asp78/git
mv ./.git/ ./mentii/
mv ./.gitignore ./mentii/

## Send slack notification
date=`date`
cd /home/asp78/git/mentii
git_last=`git log --pretty=format:'%h' -n 1`
#/home/asp78/slacknotify.sh "Build Complete at $date. Latest commit: $git_last"
echo "DONE!"
