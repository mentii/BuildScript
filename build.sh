#!/bin/bash

## Parameters ##
## $1 : branch_name

## If no arguments are given, terminate since
## it does not know which branch to use
if [ $# -eq 0 ]
  then
    echo >&2 "No arguments supplied"
    exit 1
fi

## If the branch does not exist in the repo, terminate
repo_exists=`git ls-remote --heads https://github.com/mentii/mentii.git $1 | wc -l`

if [ $repo_exists == '0' ]; then
  echo >&2 "Given branch '$1' does not exist in the mentii repository."
  exit 2
fi

git_repo_dir='/home/asp78/git'
mentii_repo_dir="$git_repo_dir/mentii"
builds_dir='/home/asp78/public_html/builds'

## Clone fresh instance of the repo
echo "CLONING MENTII REPO"
cd $git_repo_dir
rm -rf $mentii_repo_dir

if ! git clone https://github.com/mentii/mentii.git
then
    error_msg="Failed to clone the mentii repository"
    echo >&2 $error_msg
    /home/asp78/slacknotify.sh "Build Failed at $date. Latest commit: $git_last. Reason: $error_msg"
    exit 3
fi

## Checkout given branch
echo "CHECKING OUT BRANCH '$1'"
cd $mentii_repo_dir

if ! git checkout $1
then
    error_msg="Failed to checkout branch '$1'"
    echo >&2 $error_msg
    /home/asp78/slacknotify.sh "Build Failed at $date. Latest commit: $git_last. Reason: $error_msg"
    exit 4
fi

## Remove .git and .gitignore files
echo "REMOVING .git AND .gitignore FILES"
git_last=`git log --pretty=format:'%h' -n 1` # used in slack notification
rm -rf $mentii_repo_dir/.git/ $mentii_repo_dir/.gitignore

## Build
echo "BUILDING PROJECT"
if ! make -S compile
then
    error_msg="Failed to compile"
    echo >&2 $error_msg
    /home/asp78/slacknotify.sh "Build Failed at $date. Latest commit: $git_last. Reason: $error_msg"
    exit 5
fi

## Remove unused .ts and .js.map files from the project
## to shave off some size
echo "REMOVING UNUSED FILES FROM PROJECT"
find . -name "*.js.map" -type f -delete
find . -name "*.ts" -type f -delete

## Tar it up and move it
echo "TARING UP AND MOVING PROJECT TO BUILDS DIRECTORY"
cd $git_repo_dir
tar -cf build.tar $mentii_repo_dir
mv --backup=numbered ./build.tar $builds_dir/build.tar

## Delete repository
echo "DELETING THE MENTII REPOSITORY"
rm -rf $mentii_repo_dir

## Send slack notification
echo "SENDING SLACK NOTIFICATION"
date=`date`
/home/asp78/slacknotify.sh "Build Complete at $date. Latest commit: $git_last"

echo "DONE!"
