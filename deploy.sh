#!/bin/bash

## Parameters ##
## All parameters are just flags

## Script flags
slack_flag='true'
database_flag='true'

## Locations
home_dir='/home/ec2-user'
mentii_repo_dir="$home_dir/mentii"
builds_dir="$home_dir/builds"
build_scripts_dir="$home_dir/BuildScripts"

## Variables
currentDateEST=''

# Displays the help text in STDOUT
printHelpToSTDOUT() {
  echo "To run the deploy script, make sure you are on the AWS server and then:"
  echo ""
  echo "deploy.sh [FLAG1 FLAG2 ... FLAGN]"
  echo ""
  echo "Here are the allowed flags:"
  echo "-h              Displays this gorgeous help screen"
  echo "--quiet         Does not send slack notifications on success OR failure"
  echo "--no-database   Does not wipe the database on deploy"
  echo ""
  echo "If stuff seems broken, message Alex. If he is dead, message Ryan."
}

# Handle any flags passed to the build script
handleAnyFlags() {
  for i in ${*:1}
  do
    if [ $i == "-h" ] ; then
      printHelpToSTDOUT
      exit 0
    elif [ $i == "--quiet" ] ; then
      slack_flag='false'
      echo "Not sending slack notifications."
    elif [ $i == "--no-database" ] ; then
      database_flag='false'
      echo "Not wiping and recreating database tables."
    fi
  done
}

# Wget the tar file from the build server
getTarFileFromTux() {
  echo "GETTING THE TAR FILE FROM TUX"
  cd $builds_dir
  if ! wget --no-verbose -O new.build.tar https://cs.drexel.edu/~asp78/builds/build.tar
  then
    updateCurrentDateEST
    local errorReason="Failed to wget file"
    local errorMessage="Deploy Failed at $currentDateEST. Reason: $errorReason"
    echo >&2 $errorMessage
    sendSlackNotification $errorMessage
    exit 1
  fi

  # Move old application tar to backups
  mv --backup=numbered new.build.tar build.tar
}

# Remove the current mentii directory
removeExistingApplication() {
  echo "DELETING THE CURRENT MENTII REPOISTORY"
  rm -rf $mentii_repo_dir
}

# Deletes all tables from the DB and recreates them
recreateDatabase() {
  echo "DELETING THE DB TABLES"
  if ! $build_scripts_dir/DB/deleteAllDbTables.py
  then
    updateCurrentDateEST
    local errorReason="Failed to delete the database tables"
    local errorMessage="Deploy Failed at $currentDateEST. Reason: $errorReason"
    echo >&2 $errorMessage
    sendSlackNotification $errorMessage
    exit 2
  fi

  ## TODO: Find a better way to find out when tables are finished being removed
  sleep 6 # needed for sync time to amazon

  echo "CREATING DB TABLES"
  if ! $build_scripts_dir/DB/createAllDbTables.py
  then
    updateCurrentDateEST
    local errorReason="Failed to create the database tables"
    local errorMessage="Deploy Failed at $currentDateEST. Reason: $errorReason"
    echo >&2 $errorMessage
    sendSlackNotification $errorMessage
    exit 3
  fi

  ## TODO: Find a better way to find out when tables are finished being removed
  sleep 6 # needed for sync time to amazon

  echo "POPULATING  DB TABLES"
  if ! $build_scripts_dir/DB/setupInitialData.py
  then
    updateCurrentDateEST
    local errorReason="Failed to populate the database tables"
    local errorMessage="Deploy Failed at $currentDateEST. Reason: $errorReason"
    echo >&2 $errorMessage
    sendSlackNotification $errorMessage
    exit 3
  fi
}

# Untar the new application
untarMentii() {
  echo "UNTARING THE FILE"
  cd $home_dir
  tar -xf $builds_dir/build.tar
}

# Deploys the new application
deployMentii() {
  echo "DEPLOYING THE APPLICATION"
  cd $mentii_repo_dir
  if ! make deploy
  then
    updateCurrentDateEST
    local errorReason="Failed to deploy application"
    local errorMessage="Deploy Failed at $currentDateEST. Reason: $errorReason"
    echo >&2 $errorMessage
    sendSlackNotification $errorMessage
    exit 4
  fi
}

# Restart the server
restartServer() {
  echo "RESTARTING THE SERVER"
  if ! sudo service httpd restart
  then
    updateCurrentDateEST
    local errorReason="Failed to restart server"
    local errorMessage="Deploy Failed at $currentDateEST. Reason: $errorReason"
    echo >&2 $errorMessage
    sendSlackNotification $errorMessage
    exit 5
  fi
}

# Notify slack that the deploy has finished
notifyComplete() {
  updateCurrentDateEST
  sendSlackNotification "Deploy Complete at $currentDateEST."
}

# Sends a slack notification with given message
sendSlackNotification() {
  if [ "$slack_flag" = 'true' ]
  then
    /home/asp78/SD/slacknotify.sh "$*"
  fi
}

# Updates the current date and time variable
updateCurrentDateEST() {
  currentDateEST=`TZ="America/New_York" date`
}

main() {
  handleAnyFlags $*
  getTarFileFromTux
  removeExistingApplication
  if [ "$database_flag" = 'true' ]
  then
    recreateDatabase
  fi
  untarMentii
  deployMentii
  restartServer
  notifyComplete
}

main $*
