@Library('my_shared_library')_

def workspace;
def dockerImage;
def props='';
def targetURL='';
def microserviceName;
def docImg;
def repoName;
def credentials = 'docker-credentials';
def commit_Email;
def archery='';
node {
    stage('Checkout Code')
    {
	try{
	checkout scm
	workspace = pwd() 
	     sh "ls -lat"
	commit_Email=sh(returnStdout: true, script: '''Email=$(git log -1 --pretty=%ae) 
                                                            echo $Email''').trim();
	props = readProperties  file: """deploy.properties""" 
	}
	catch (error) {
				currentBuild.result='FAILURE'
				notifyBuild(currentBuild.result, "At Stage Checkout Code", commit_Email, "",props['deploy.archery'])
				echo """${error.getMessage()}"""
				throw error
			}
    }
    
    stage ('Check-secrets')
    {
	try{
	sh "rm trufflehog || true"
	sh "docker run gesellix/trufflehog --json --regex ${props['deploy.gitURL']} > trufflehog"
	sh "cat trufflehog"
	
	/*File file = new File("./trufflehog");
	if (file.length() == 0)
	{
		sh "echo Trufflehog didn't find any secrets. We are good to go !"
	}*/
	}
	catch (error) {
				currentBuild.result='FAILURE'
				notifyBuild(currentBuild.result, "At Stage Check-secrets", commit_Email, "",props['deploy.archery'])
				echo """${error.getMessage()}"""
				throw error
			}
    }
    
    stage ('Source Composition Analysis') 
    {
         try{
	 
	snykSecurity projectName: "${props['deploy.microservice']}", severity: 'high', snykInstallation: 'SnykSec', snykTokenId: 'snyk-personal', targetFile: '.'
	 
	 }
	 catch (error) {
				currentBuild.result='FAILURE'
				notifyBuild(currentBuild.result, "At Stage Source Composition Analysis", commit_Email, "",props['deploy.archery'])
				echo """${error.getMessage()}"""
				throw error
			}
    }
    
    stage ('SAST')
    {
	    try{
		sonarexec "${props['deploy.sonarqubeserver']}"
		 }
	 catch (error) {
				currentBuild.result='FAILURE'
				notifyBuild(currentBuild.result, "At Stage SAST", commit_Email, "",props['deploy.archery'])
				echo """${error.getMessage()}"""
				throw error
			}
    } 
    
    stage ('create war')
    {
    	try{
	mavenbuildexec "mvn build"
	}
	 catch (error) {
				currentBuild.result='FAILURE'
				notifyBuild(currentBuild.result, "At Stage create war", commit_Email, "",props['deploy.archery'])
				echo """${error.getMessage()}"""
				throw error
			}
    }
    
    stage ('Create Docker Image')
    { 
	     try{
	     echo 'creating an image'
	     docImg="${props['deploy.dockerhub']}/${props['deploy.microservice']}"
             dockerImage = dockerexec "${docImg}"
	     }
	     catch (error) {
				currentBuild.result='FAILURE'
				notifyBuild(currentBuild.result, "At Stage create war", commit_Email, "",props['deploy.archery'])
				echo """${error.getMessage()}"""
				throw error
			}
    }
    
    stage ('Push Image to Docker Registry')
    { 
	     try{
	     docker.withRegistry('https://registry.hub.docker.com','docker-credentials') {
             dockerImage.push("${BUILD_NUMBER}")
	     }
	     }
	     catch (error) {
				currentBuild.result='FAILURE'
				notifyBuild(currentBuild.result, "At Stage Push Image to Docker Registry", commit_Email, "",props['deploy.archery'])
				echo """${error.getMessage()}"""
				throw error
			}
    }
    
    stage ('Scan Container Images')
    {
	try{
	sh 'rm anchore_images || true'
    	sh """echo "${docImg}:${BUILD_NUMBER} `pwd`/Dockerfile" > anchore_images"""
	anchore 'anchore_images'
	}
	catch (error) {
				currentBuild.result='FAILURE'
				notifyBuild(currentBuild.result, "At Stage Push Image to Docker Registry", commit_Email, "",props['deploy.archery'])
				echo """${error.getMessage()}"""
				throw error
		}
    }
    
    stage ('Config helm')
    { 
    	
	try{
	def filename = 'helmchart/values.yaml'
	def data = readYaml file: filename
	
	data.image.repository = "${docImg}"
	data.image.tag = "$BUILD_NUMBER"
	data.service.appPort = "${props['deploy.port']}"
	
	sh "rm -f helmchart/values.yaml"
	writeYaml file: filename, data: data
	}
	     catch (error) {
				currentBuild.result='FAILURE'
				notifyBuild(currentBuild.result, "At Stage Config helm", commit_Email, "",props['deploy.archery'])
				echo """${error.getMessage()}"""
				throw error
			}
	
    }
    stage ('deploy to cluster')
    {
    	try{
	//helmdeploy "${props['deploy.microservice']}"
	withKubeConfig(credentialsId: 'kubernetes-creds', serverUrl: 'https://35.225.92.51') {

		sh """ helm delete --purge ${props['deploy.microservice']} | true"""
		helmdeploy "${props['deploy.microservice']}"
		sh """sleep 80"""
		targetURL = sh(returnStdout: true, script: "kubectl get svc --namespace default ${props['deploy.microservice']} \
								-o jsonpath='{.status.loadBalancer.ingress[0].ip}'")
	}
	}
	     catch (error) {
				currentBuild.result='FAILURE'
				notifyBuild(currentBuild.result, "At Stage deploy to cluster", commit_Email, "",props['deploy.archery'])
				echo """${error.getMessage()}"""
				throw error
			}
	
    } 
    
    stage ('DAST')
    {
    	try{
		
	sh """
		echo ${targetURL}
		export ARCHERY_HOST=props['deploy.archery']
		export TARGET_URL='http://${targetURL}/app'
		bash /var/lib/jenkins/archery/zapscan.sh || true
	"""
	
	}
	     catch (error) {
				currentBuild.result='FAILURE'
				notifyBuild(currentBuild.result, "At Stage DAST", commit_Email, "",props['deploy.archery'])
				echo """${error.getMessage()}"""
				throw error
			}
    } 
    notifyBuild(currentBuild.result, "", commit_Email, "Build successful.",props['deploy.archery'])
	
}
def notifyBuild(String buildStatus, String buildFailedAt, String commit_Email, String bodyDetails,String archery) 
{
	buildStatus = buildStatus ?: 'SUCCESS'
	def details = """Please find attahcment for archerysec report \"${archery}\" \n and log and Check console output at ${BUILD_URL}\n \n \"${bodyDetails}\"
		\n"""
	emailext attachLog: true,attachmentsPattern: 'owasp-dependency-check.sh',
	notifyEveryUnstableBuild: true,
	recipientProviders: [[$class: 'RequesterRecipientProvider']],
	body: details, 
	subject: """${buildStatus}: [${BUILD_NUMBER}] ${buildFailedAt}""", 
	to: """${commit_Email}"""
	
	slackSend message: """Build Result: ${buildStatus} \n ${BUILD_URL} """

}
