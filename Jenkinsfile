def devProjectNamespace = "af-connect-dev"
def cicdProjectNamespace = "af-connect-cicd"
def afConnectDemo = "af-connect-demo"
def afConnectDemoGitRepo = "https://github.com/MagnumOpuses/af-connect-demo.git"
def afConnectDemoGitBranch = "master"

pipeline {
    agent any

    stages {
        stage('preamble') {
            steps {
                script {
                    openshift.withCluster() {
                        openshift.withProject("${cicdProjectNamespace}") {
                            echo "Using project: ${openshift.project()}"
                        }
                    }
                }
            }
        }
        stage('Create Image Builder') {
            when {
                expression {
                    openshift.withCluster() {
                    openshift.withProject("${cicdProjectNamespace}") {
                        return !openshift.selector("bc", "${afConnectDemo}").exists();
                        }
                    }
                }
            }
            steps {
                script {
                    openshift.withCluster() {
                        openshift.withProject("${cicdProjectNamespace}") {
                            openshift.newBuild("--name=${afConnectDemo}", "--strategy=docker", "${afConnectDemoGitRepo}#${afConnectDemoGitBranch}")
                        }
                    }
                }
            }
        }
        stage('Build Image') {
            steps {
                script {
                    openshift.withCluster() {
                        openshift.withProject("${cicdProjectNamespace}") {
                            openshift.selector("bc", "${afConnectDemo}").startBuild()
                        }
                    }
                }
            }
        }
        stage('Deploy Image') {
            steps {
                script {
                    openshift.withCluster() {
                        openshift.withProject("${cicdProjectNamespace}") {
                            openshift.newApp("${afConnectDemo}", "--name=af-connect-demo")
                        }
                    }
                }
            }
        }
    }
}