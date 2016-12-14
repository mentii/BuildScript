#!/bin/bash

#Move to the builds dir and do everything there
cd ~/builds
#wget the tar file from the build server
if ! wget -O new.build.tar https://cs.drexel.edu/~asp78/builds/build.tar
then
    error_msg="Failed to wget file"
    date=`date`
    echo >&2 $error_msg
    /home/asp78/SD/slacknotify.sh "Deploy Failed at $date. Reason: $error_msg"
    exit 1
fi
mv --backup=numbered new.build.tar build.tar
#remove the current mentii directory
cd ..
rm -rf ./mentii
#untar the tar from the build server
tar -xvf ./builds/build.tar
#Make deploy
cd mentii
if ! make deploy
then
    error_msg="Failed to deploy application"
    date=`date`
    echo >&2 $error_msg
    /home/asp78/SD/slacknotify.sh "Deploy Failed at $date. Reason: $error_msg"
    exit 2
fi
#Restart the server
if ! sudo service httpd restart
then
    error_msg="Failed to restart server"
    date=`date`
    echo >&2 $error_msg
    /home/asp78/SD/slacknotify.sh "Deploy Failed at $date. Reason: $error_msg"
    exit 3
fi
#Notify slack that the 
~/slackNotify.sh "Deploy Process Complete"