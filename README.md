## AF-Connect-Infrastructure

This repo contains the configuration information from building all the aritifacts of AF-connect to deploying them to different clusters.


## This Repo has:
1. config folder: contains all necessary the build, deployment and imagestream configuration for the openshift.
2. pipeline init folder: contains the pipeline that initiate the jenkins pipeline for each artifacts.
3. skopeo folder: contains documentain and configuration of skopeo to transfer images form test cluster to prod/t2/onprem-prod