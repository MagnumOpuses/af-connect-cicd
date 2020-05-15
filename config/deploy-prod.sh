#!/bin/bash
# a script to deploy in onprem

oc login openshift.ams.se

# deploying to onprem prod
oc project af-connect

echo 'Available Tags'
git ls-remote --tags https://github.com/MagnumOpuses/af-connect.git

read -p 'Image Tag: ' imagetag

oc tag "af-connect:release-${imagetag}" af-connect:latest
oc tag "af-connect-outbox:release-${imagetag}" af-connect-outbox:latest
oc tag "af-portability:release-${imagetag}" af-portability:latest

oc logout