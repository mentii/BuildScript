#!/bin/bash

## Parameters ##
## $1   branch_name (required)
## $2+  flags

## Script flags
deploy_flag='true'
slack_flag='true'
test_flag='true'
database_flag='true'
sampleData_flag='false'
prod_flag='false'

## Locations
git_repo_dir='/home/asp78/git'
mentii_repo_dir="$git_repo_dir/mentii"
builds_dir='/home/asp78/public_html/builds'
buildScript_dir="$git_repo_dir/BuildScript"

## Variables
gitBranch=''
gitBranchLastCommit=''
currentDateEST=''
username=''
flagsGiven=''
applicationVersion=''
tarballName=''

## Checks if any arguments are passed into this script
exitIfNoArgumentsGiven() {
  if [ $1 -eq 0 ]
  then
    echo >&2 "No arguments supplied"
    unlockScript
    exit 1
  else
    gitBranch=$2
  fi
}

## Displays the help text in STDOUT
printHelpToSTDOUT() {
  echo "To run the build script, make sure you are on TWINKLE with (-X) X11 forwarding and then:"
  echo ""
  echo "build.sh BRANCH_NAME [FLAG1 FLAG2 ... FLAGN]"
  echo ""
  echo "and YES the flags must come after the BRANCH_NAME. This ain't some fancy script."
  echo ""
  echo "Here are the allowed flags:"
  echo "-h              Displays this gorgeous help screen"
  echo "--no-deploy     Does not automatically deploy the tarball post build"
  echo "--no-test       Does not run unit tests USE WISELY"
  echo "--quiet         Does not send slack notifications on success OR failure"
  echo "--no-database   Does not wipe the database on deploy"
  echo "--prod          Deploys to prod"
  echo ""
  echo "If stuff seems broken, message Alex. If he is dead, message Ryan."
}

## Handle any flags passed to the build script
handleAnyFlags() {
  flagsGiven=$*
  for i in ${*:1}
  do
    if [ $i == "-h" ] ; then
      printHelpToSTDOUT
      unlockScript
      exit 0
    elif [ $i == "--no-deploy" ] ; then
      deploy_flag='false'
      echo "Not deploying to AWS post build."
    elif [ $i == "--quiet" ] ; then
      slack_flag='false'
      echo "Not sending slack notifications."
    elif [ $i == "--no-test" ] ; then
      test_flag='false'
      echo "Not running unit tests."
    elif [ $i == "--no-database" ] ; then
      database_flag='false'
      echo "Not wiping and recreating database tables."
    elif [ $i == "--sample-data" ] ; then
      sampleData_flag='true'
      echo "Adding sample data."
    elif [ $i == "--prod" ] ; then
      prod_flag='true'
      echo "Deploying to prod."
    fi
  done
}

## Check if the given branch exists in the mentii repo
exitIfMentiiBranchDoesntExist() {
  local repo_exists=`git ls-remote --heads https://github.com/mentii/mentii.git $gitBranch | wc -l`

  if [ $repo_exists == '0' ]; then
    echo >&2 "Given branch '$gitBranch' does not exist in the mentii repository."
    unlockScript
    exit 2
  fi
}

## Clone fresh instance of the mentii repository
## Also sends a slack notification that the build process has started
cloneMentiiRepository () {
  echo "CLONING MENTII REPO ON BRANCH '$gitBranch'"
  cd $git_repo_dir
  rm -rf $mentii_repo_dir

  setUserName
  updateCurrentDateEST
  local message="$username has started a build at $currentDateEST for branch '$gitBranch'."
  sendSlackNotification $message

  if ! git clone -b $gitBranch https://github.com/mentii/mentii.git
  then
    updateCurrentDateEST
    local errorReason='Failed to clone the mentii repository.'
    local errorMessage="Build Failed at $currentDateEST. Reason: $errorReason"
    echo >&2 "$errorReason"
    sendSlackNotification $errorMessage
    unlockScript
    exit 3
  fi

  # Get last commit for notifications
  cd $mentii_repo_dir
  gitBranchLastCommit=`git log --pretty=format:'%h' -n 1`

  # Get application version
  applicationVersion=`grep "version" ~/git/mentii/Frontend/package.json | awk -F " " '{print $2}' | cut -d "\"" -f 2`

  # Change group permissions
  chown -Rf :mentil_senior_proj_1617 $mentii_repo_dir
}

## Updates the current date and time variable
updateCurrentDateEST() {
  currentDateEST=`TZ="America/New_York" date`
}

## Sends a slack notification with given message
sendSlackNotification() {
  if [ "$slack_flag" = 'true' ]
  then
    /home/asp78/SD/slacknotify.sh "$*"
  fi
}

## Compiles mentii project for testing (includes devDependencies)
buildMentiiProjectForTesting() {
  echo "BUILDING PROJECT FOR TESTING"
  cd $mentii_repo_dir
  if ! make compile
  then
    rm -rf $mentii_repo_dir
    updateCurrentDateEST
    local errorReason='Failed to compile.'
    local errorMessage="Build Failed at $currentDateEST. Latest commit on $gitBranch: $gitBranchLastCommit. Reason: $errorReason"
    echo >&2 "$errorReason"
    sendSlackNotification $errorMessage
    unlockScript
    exit 5
  fi
}

## Runs unit tests
## Kills the database xterm after they are done as well as deletes the virtual environment
runUnitTests() {
  if [ "$test_flag" = 'true' ]
  then
    buildMentiiProjectForTesting
    echo "RUNNING TESTS"
    cd $mentii_repo_dir
    if ! make runtests-nocompile
    then
      rm -rf $mentii_repo_dir
      pkill -9 xterm
      rm -rf $mentii_repo_dir/Backend/env
      rm -rf $git_repo_dir/LocalDB/env
      updateCurrentDateEST
      local errorReason='Failed to pass tests.'
      local errorMessage="Build Failed at $currentDateEST. Latest commit on $gitBranch: $gitBranchLastCommit. Reason: $errorReason"
      echo >&2 "$errorReason"
      sendSlackNotification $errorMessage
      unlockScript
      exit 6
    fi

    ## Kill database xterm - super bad
    pkill -9 xterm

    ## Delete Virtual Environments
    rm -rf $mentii_repo_dir/Backend/env
    rm -rf $git_repo_dir/LocalDB/env
  fi
}

## Compiles mentii project without devDependencies
buildProductionMentiiProject() {
  echo "BUILDING PRODUCTION CODE"

  # Clean repo, removes devDependencies
  cd $mentii_repo_dir
  make clean
  cd $mentii_repo_dir/Frontend

  # Remove testing
  rm -rf $mentii_repo_dir/Frontend/karma.conf.js
  rm -rf $mentii_repo_dir/Frontend/karma-test-shim.js
  rm -rf $mentii_repo_dir/Frontend/testing/

  if ! make compile-prod
  then
    rm -rf $mentii_repo_dir
    updateCurrentDateEST
    local errorReason='Failed to compile-prod.'
    local errorMessage="Build Failed at $currentDateEST. Latest commit on $gitBranch: $gitBranchLastCommit. Reason: $errorReason"
    echo >&2 "$errorReason"
    sendSlackNotification $errorMessage
    unlockScript
    exit 7
  fi
}

## Removes unneeded files from repo to save on space in tarball
deleteUnusedFilesFromProject() {
  echo "REMOVING UNUSED FILES FROM PROJECT"
  cd $mentii_repo_dir
  find . -name "*.js.map" -type f -delete
  find . -name "*.ts" -type f -delete

  # Remove .git and .gitignore from repo
  rm -rf $mentii_repo_dir/.git/ $mentii_repo_dir/.gitignore
}

## Tars the project up and moves it
tarProjectUpAndMove() {
  echo "TARING UP AND MOVING PROJECT TO BUILDS DIRECTORY"
  cd $git_repo_dir
  tarballName="build.tar.$applicationVersion"
  tar -cf $tarballName ./mentii

  # Change group owner of tarball
  chown -f :mentil_senior_proj_1617 ./$tarballName

  # Moves tarball to the builds directory
  mv --backup=numbered ./$tarballName $builds_dir/$tarballName
}

## Deletes the repo and notifies team of completion
finishBuild() {
  # Deletes mentii repository
  rm -rf $mentii_repo_dir

  # Sends slack message saying build is done
  updateCurrentDateEST
  local message="Build Complete at $currentDateEST. Latest commit on $gitBranch: $gitBranchLastCommit"
  sendSlackNotification $message
}

## Starts a deploy if the flag is true
triggerDeploy() {
  if $deploy_flag
  then
    if $prod_flag
    then
      echo "Deploying to AWS prod server"
      ssh aws "/home/ec2-user/deploy.sh $tarballName $flagsGiven"
    else
      echo "Deploying to AWS staging server"
      ssh aws-staging "/home/ec2-user/deploy.sh $tarballName $flagsGiven"
    fi
  fi
}

lockScriptOrQuit() {
  if [ -f $buildScript_dir/buildIsInProgress.tmp ] ; then
    echo >&2 "Another person is running this right now, wait a sec."
    exit 7
  else
    cd $buildScript_dir
    touch ./buildIsInProgress.tmp
    chown -f :mentil_senior_proj_1617 ./buildIsInProgress.tmp
    cd -
  fi
}

unlockScript() {
  rm -f $buildScript_dir/buildIsInProgress.tmp
}

setUserName() {
  local user=$USER
  if [ "$user" = 'asp78' ]
  then
    username='Alex, Master of the DevOps,'
  elif [ "$user" = 'ams665' ]
  then
    username='Aaron, The Wise Old Man,'
  elif [ "$user" = 'smc395' ]
  then
    username='Micah, The Faithful Companion,'
  elif [ "$user" = 'jtm333' ]
  then
    username='Jon, The Lord of Flames,'
  elif [ "$user" = 'rdy29' ]
  then
    username='Ryan, The Emperor of Robotics,'
  else
    username='Someone, I have no idea who,'
  fi
}

main () {
  lockScriptOrQuit
  exitIfNoArgumentsGiven $# $1
  handleAnyFlags $*
  exitIfMentiiBranchDoesntExist
  cloneMentiiRepository
  runUnitTests
  buildProductionMentiiProject
  deleteUnusedFilesFromProject
  tarProjectUpAndMove
  finishBuild
  triggerDeploy
  unlockScript

  echo "\nDONE!"
}

main $*
