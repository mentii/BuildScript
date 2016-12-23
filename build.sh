#!/bin/bash

## Parameters ##
## $1   : branch_name (required)
## $2+  : flags

deploy_flag=true
slack_flag=true

## If no arguments are given, terminate since
## it does not know which branch to use
if [ $# -eq 0 ]
  then
    echo >&2 "No arguments supplied"
    exit 1
fi

## Iterate through flags
for i in ${*:2}
do
  if [ $i == "--no-deploy" ] ; then
    deploy_flag=false
    echo "Not deploying to AWS post build."
  elif [ $i == "--quiet" ] ; then
    slack_flag=false
    echo "Not sending slack notifications."
  fi
done

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
    date=`date`
    echo >&2 $error_msg
    if $slack_flag
    then
      /home/asp78/SD/slacknotify.sh "Build Failed at $date. Latest commit on $1: $git_last. Reason: $error_msg"
    fi
    exit 3
fi

## Checkout given branch
echo "CHECKING OUT BRANCH '$1'"
cd $mentii_repo_dir

if ! git checkout $1
then
    rm -rf $mentii_repo_dir
    error_msg="Failed to checkout branch '$1'"
    date=`date`
    echo >&2 $error_msg
    if $slack_flag
    then
      /home/asp78/SD/slacknotify.sh "Build Failed at $date. Latest commit on $1: $git_last. Reason: $error_msg"
    fi
    exit 4
fi

## Change group permissions to our group
echo "CHANGING GROUP PERMISSIONS OF REPO"
chown -Rf :mentil_senior_proj_1617 $mentii_repo_dir

## Remove .git and .gitignore files
echo "REMOVING .git AND .gitignore FILES"
git_last=`git log --pretty=format:'%h' -n 1` # used in slack notification
rm -rf $mentii_repo_dir/.git/ $mentii_repo_dir/.gitignore

## Build
echo "BUILDING PROJECT"
if ! make compile
then
    rm -rf $mentii_repo_dir
    error_msg="Failed to compile"
    date=`date`
    echo >&2 $error_msg
    if $slack_flag
    then
      /home/asp78/SD/slacknotify.sh "Build Failed at $date. Latest commit on $1: $git_last. Reason: $error_msg"
    fi
    exit 6
fi

## Run unit tests
echo "RUNNING TESTS"
cd $mentii_repo_dir
if ! make runtests-nocompile
then
    rm -rf $mentii_repo_dir
    error_msg="Failed to pass tests"
    date=`date`
    echo >&2 $error_msg
    if $slack_flag
    then
      /home/asp78/SD/slacknotify.sh "Build Failed at $date. Latest commit on $1: $git_last. Reason: $error_msg"
    fi
    exit 5
fi

## Kill database xterm - super bad
echo "KILLING THE DATABASE PROCESS"
pkill -9 xterm

## Delete Virtual Environment
echo "REMOVING VIRTUAL ENVIRONMENT"
rm -rf $mentii_repo_dir/Backend/env

## Remove unused .ts and .js.map files from the project
## to shave off some size
echo "REMOVING UNUSED FILES FROM PROJECT"
cd $mentii_repo_dir
find . -name "*.js.map" -type f -delete
find . -name "*.ts" -type f -delete

## Tar it up and move it
echo "TARING UP AND MOVING PROJECT TO BUILDS DIRECTORY"
cd $git_repo_dir
tar -cf build.tar ./mentii
chown -f :mentil_senior_proj_1617 ./build.tar
mv --backup=numbered ./build.tar $builds_dir/build.tar

## Delete repository
echo "DELETING THE MENTII REPOSITORY"
rm -rf $mentii_repo_dir

## Send slack notification
echo "SENDING SLACK NOTIFICATION"
date=`date`
if $slack_flag
then
  /home/asp78/SD/slacknotify.sh "Build Complete at $date. Latest commit on $1: $git_last"
fi

## Deploy if deploy_flag is true
if $deploy_flag
then
  echo "Deploying to AWS server"
  ssh aws /home/ec2-user/deploy.sh
fi

echo "DONE!"
