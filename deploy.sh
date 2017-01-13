#!/bin/bash

## Locations
home_dir='/home/ec2-user'
mentii_repo_dir="$home_dir/mentii"
builds_dir="$home_dir/builds"
build_scripts_dir="$home_dir/BuildScripts"

# Wget the tar file from the build server
echo "GETTING THE TAR FILE FROM TUX"
cd $builds_dir
if ! wget --no-verbose -O new.build.tar https://cs.drexel.edu/~asp78/builds/build.tar
then
    error_msg="Failed to wget file"
    date=`TZ="America/New_York" date`
    echo >&2 $error_msg
    /home/ec2-user/slackNotify.sh "Deploy Failed at $date. Reason: $error_msg"
    exit 1
fi
mv --backup=numbered new.build.tar build.tar

# Remove the current mentii directory
echo "DELETING THE CURRENT MENTII REPOISTORY"
rm -rf $mentii_repo_dir

# Delete Current DBs table and recreate them fresh
echo "DELETING THE DB TABLES"
$build_scripts_dir/DB/deleteAllDbTables.py
sleep 6 # needed for sync time to amazon

echo "CREATING DB TABLES"
$build_scripts_dir/DB/createAllDbTables.py

# Untar the tar from the build server
echo "UNTARING THE FILE"
cd $home_dir
tar -xf $builds_dir/build.tar

# Make deploy
echo "DEPLOYING THE APPLICATION"
cd $mentii_repo_dir
if ! make deploy
then
    error_msg="Failed to deploy application"
    date=`TZ="America/New_York" date`
    echo >&2 $error_msg
    /home/ec2-user/slackNotify.sh "Deploy Failed at $date. Reason: $error_msg"
    exit 2
fi

# Restart the server
echo "RESTARTING THE SERVER"
if ! sudo service httpd restart
then
    error_msg="Failed to restart server"
    date=`TZ="America/New_York" date`
    echo >&2 $error_msg
    /home/ec2-user/slackNotify.sh "Deploy Failed at $date. Reason: $error_msg"
    exit 3
fi

# Notify slack that the deploy has finished
echo "SENDING SLACK NOTIFICATION"
date=`TZ="America/New_York" date`
/home/ec2-user/slackNotify.sh "Deploy Complete at $date."
