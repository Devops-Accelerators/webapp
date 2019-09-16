@Library('my_shared_library')_

def workspace;
def branch;
def dockerImage;
def props='';
def microserviceName;
def port;
def docImg;
def gitUrl;
def repoName;
def credentials = 'docker-credentials';

node {
    stage('Checkout Code')
    {
	checkout scm
	workspace = pwd() 
	     sh "ls -lat"
	props = readProperties  file: """deploy.properties"""   
    }
    
   /* stage ('Static Code Analysis')
    { 
	    sonarexec "${props['deploy.sonarqubeserver']}"
    }
    
     stage ('Build and Unit Test Execution')
    {
          testexec "junit testing.."
    }
    
     stage ('Code Coverage')
    { 
        codecoveragexec "${props['deploy.sonarqubeserver']}"
    }*/
    stage ('create war')
    {
    	mavenbuildexec "mvn build"
    }
    
     stage ('Create Docker Image')
    { 
	     echo 'creating an image'
	     docImg="${props['deploy.dockerhub']}/${props['deploy.microservice']}"
             dockerImage = dockerexec "${docImg}"
    }
    
     stage ('Push Image to Docker Registry')
    { 
	     docker.withRegistry('https://registry.hub.docker.com','docker-credentials') {
             dockerImage.push("${BUILD_NUMBER}")
	     }
    }
    
    stage ('Config helm')
    { 
    	
	def filename = 'helmchart/values.yaml'
	def data = readYaml file: filename
	
	data.image.repository = "${docImg}"
	data.image.tag = "$BUILD_NUMBER"
	data.service.appPort = "${props['deploy.port']}"
	
	sh "rm -f helmchart/values.yaml"
	writeYaml file: filename, data: data
	
    }
    stage ('deploy to cluster')
    {
    	//helmdeploy "${props['deploy.microservice']}"
	withKubeConfig(credentialsId: 'kubernetes-creds', serverUrl: 'https://104.198.157.239') {

		sh """ helm delete --purge ${props['deploy.microservice']} | true"""
		helmdeploy "${props['deploy.microservice']}"
	}
	
    }
	
}
		
