#!/bin/bash

home_dir='/home/ec2-user'
mentii_repo_dir="$home_dir/mentii"
builds_dir="$home_dir/builds"

#wget the tar file from the build server
echo "GETTING THE TAR FILE FROM TUX"
cd $builds_dir
if ! wget --no-verbose -O new.build.tar https://cs.drexel.edu/~asp78/builds/build.tar
then
    error_msg="Failed to wget file"
    date=`date`
    echo >&2 $error_msg
    /home/ec2-user/slackNotify.sh "Deploy Failed at $date. Reason: $error_msg"
    exit 1
fi
mv --backup=numbered new.build.tar build.tar

#remove the current mentii directory
echo "DELETING THE CURRENT MENTII REPOISTORY"
rm -rf $mentii_repo_dir

#untar the tar from the build server
echo "UNTARING THE FILE"
cd $home_dir
tar -xf $builds_dir/build.tar

#Make deploy
echo "DEPLOYING THE APPLICATION"
cd $mentii_repo_dir
if ! make deploy
then
    error_msg="Failed to deploy application"
    date=`date`
    echo >&2 $error_msg
    /home/ec2-user/slackNotify.sh "Deploy Failed at $date. Reason: $error_msg"
    exit 2
fi

#Restart the server
echo "RESTARTING THE SERVER"
if ! sudo service httpd restart
then
    error_msg="Failed to restart server"
    date=`date`
    echo >&2 $error_msg
    /home/ec2-user/slackNotify.sh "Deploy Failed at $date. Reason: $error_msg"
    exit 3
fi

#Notify slack that the 
echo "SENDING SLACK NOTIFICATION"
date=`date`
/home/ec2-user/slackNotify.sh "Deploy Complete at $date."
