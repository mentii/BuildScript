#!/bin/bash

#Move to the builds dir and do everything there
cd ~/builds
#wget the tar file from the build server
wget -O new.build.tar https://cs.drexel.edu/~asp78/builds/build.tar
mv --backup=numbered new.build.tar build.tar
#remove the current mentii directory
cd ..
rm -rf ./mentii
#untar the tar from the build server
tar -xvf ./builds/build.tar
#Make deploy
cd mentii
make deploy
#Restart the server
sudo service httpd restart
#Notify slack that the 
~/slackNotify.sh "Deploy Process Complete"
