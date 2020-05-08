# Jenkins builds and Multicluster deployments

## Background

In order to ensure redundancy in our environments, the devops team has deployed two clusters each for Test and Prod environments. The intention is to have a load balancer that can easily switch between the two clusters in case one experiences issues. This, however, will increase the complexity of the actual deployments for the development teams.

## Architecture

The plan is to build all container images in one of the test clusters and then distribute them to the other clusters for deployment. The tools to use for this is Jenkins and Skopeo. Initially the way to actually get the images deployed will be to have triggers for image change set in the deploymentConfigs of the services. Other planned methods will be discussed later.

## Tutorial
### Using Jenkins to build and deploy

First you need to have your application deployed in the primary cluster you plan to use in a namespace of your choice. Make sure you replace <namespace_name> with this in all places.
If you do not have an application of your own, you can use the demo app at https://github.com/sclorg/cakephp-ex.git
Create a namespace either through the gui or using the cli with 
~~~~ 
oc create namespace <namespace_name> 
~~~~
Then create the application using 
~~~~ 
oc new-app https://github.com/sclorg/cakephp-ex.git -n <namespace_name>
~~~~
For now lets remove the triggers that would cause the application to redeploy in case of an image or configuration change. We will do that with Jenkins.
~~~~
oc set triggers dc/cakephp-ex.git --remove-all -n <namespace_name>
~~~~
Next, create the Jenkins application which will handle the deploys etc in this namespace. We will create a persistant Jenkins.
~~~~
oc new-app jenkins-persistent --param ENABLE_OAUTH=true --param MEMORY_LIMIT=2Gi --param VOLUME_CAPACITY=4Gi --param DISABLE_ADMINISTRATIVE_MONITORS=true -n <namespace_name>
~~~~
Since we are planning to use Skopeo to handle moving images between clusters, we will create a Jenkins agent with Skopeo installed. First create the image stream and buildConfig for the agent, and then start the build. The buildConfig contains an inline Dockerfile which will use an existinc CentOS jnlp-agent base image and install Skopeo ontop of it using yum. If you need other packages you can add them to this file to be installed.
~~~~
oc apply -f skopeo_is.yaml -n <namespace_name>
oc apply -f skopeo_bc_agent.yaml -n <namespace_name>
oc start-build jnlp-slopeo
~~~~
Once we the agent has been built, we can go ahead and setup our buildConfig that will use the pipeline strategy to build with Jenkins.
In the file skopeo_demo_pipeline_bc.yaml, fill in the environment variables for NAMESPACE, and SOURCE_IMAGE_REPO. The latter can be found in the Image stream for the cakephp-ex image. 

![Image of Imagestream](images/image_stream.png)

When this is done create the buildConfig.
~~~~
oc apply -f skopeo_demo_pipeline_bc.yaml -n <namespace_name>
~~~~
When you run the buildconfig, Jenkins will start a new pod with our skopeo agent and execute the oc commands in that pod. This should build the cakephp-ex image again, tag it with the jenkins buildnumber and update and rollout the deploymentConfig to use the new image.

### Using Skopeo to push images to a different cluster
In order to use Skopeo to push images between clusters there need to be service accounts in the source and destination namespaces that are allowed to read and push images. 

First create the namespace and application in the destination cluster in the same way as previously. Do not create a Jenkins instance or any of the related artifacts.
Next create a service account by running
~~~~~
oc apply -f skopeo_serviceaccount.yaml -n <namespace_name>
~~~~~
You need to do this in both the source and destination cluster.

Next you will give the newly created service account the rolebinding that will allow it to handle images in the namespace. This will bind it to the role system:image-builder which is a clusterrole.
~~~~~~
oc apply -f skopeo_rolebinding.yaml -f <namespace_name>
~~~~~~
You also need to do this in both clusters.
Now edit the skopeo_demo_pipeline_bc.yaml and remove the comments for the stage Deploy to backup cluster. Find and enter the Public Image Repository URLs for the cakephp-ex imagestreams in the Source and Destination Clusters. Finally you need to add the tokens for the skopeo service accounts from source and destination to SCRED and DCRED respectively. You can either find the token by running 
~~~~~
oc get secrets -o jsonpath='{range .items[?(@.metadata.annotations.kubernetes\.io/service-account\.name=="skopeo")]}{.metadata.annotations.openshift\.io/token-secret\.value}{end}' |tee skopeo-token
~~~~~~
in the source and destination namespace respectively. Or you can find it using the gui. 

![Image of Imagestream](images/service_account.png)

After the environment variables have been edited, save the file and run
~~~~
oc apply -f skopeo_demo_pipeline_bc.yaml -n <namespace_name>
~~~~
If you start the build, Jenkins should now build the image, tag it, update and rollout the deployment in the source repository and file Skopeo will copy the image to the imagestream in the destination repository.
