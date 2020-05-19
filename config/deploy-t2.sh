#!/bin/bash
# a script to deploy in onprem

oc login openshift.ams.se

# deploying to onprem t2
oc project gravity-t2

echo 'Available Tags'
git ls-remote --tags https://github.com/MagnumOpuses/af-connect.git

read -p 'Enter only tag number ' imagetag

oc tag "af-connect:pre-release-${imagetag}" af-connect:latest
oc tag "af-connect-outbox:pre-release-${imagetag}" af-connect-outbox:latest
oc tag "af-portability:pre-release-${imagetag}" af-portability:latest

oc logout