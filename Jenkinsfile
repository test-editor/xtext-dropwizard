#!groovy
JENKINS_NAME = "jenkins"

nodeWithProperWorkspace {

    stage('Checkout') {
        checkout scm
        if (isMaster()) {
            // git by default checks out detached, we need a local branch
            sh "git checkout $env.BRANCH_NAME" // workaround for https://issues.jenkins-ci.org/browse/JENKINS-31924
            sh 'git fetch --prune origin +refs/tags/*:refs/tags/*' // delete all local tags
            sh "git reset --hard origin/master"
            sh "git clean -ffdx"
        } else {
            sh "git clean -ffd"
        }
    }
    
    if (isMaster() && !lastCommitByJenkins()) {
        // Workaround: we don't want infinite releases.
        echo "Aborting build as the current commit on master is already tagged."
        currentBuild.displayName = "checkout-only"
        return
    }

    stage('Build') {
        withGradleEnv {
            gradle 'clean assemble'
        }
    }

    stage('Build example') {
        dir('example') {
            withGradleEnv {
                gradle 'build'
            }
        }
    }
    
    stage('Test') {
        withGradleEnv {
            gradle 'build'
        }
    }

    if (isMaster()) {
        stage('Release') {
            currentBuild.displayName = getVersion().replaceAll('-SNAPSHOT', '')
            withGradleEnv {
                sh 'git config user.email "jenkins@ci.testeditor.org"'
                sh "git config user.name \"$JENKINS_NAME\""
                // workaround: cannot push without credentials using HTTPS => push using SSH
                sh "git remote set-url origin ${getGithubUrlAsSsh()}"
                withCredentials([[$class: 'UsernamePasswordMultiBinding', credentialsId: '1e68e4c1-48a6-428c-8896-42511359493e', passwordVariable: 'BINTRAY_KEY', usernameVariable: 'BINTRAY_USER']]) {
                    gradle 'release -Prelease.useAutomaticVersion=true'
                }
            }
            
            // merge back to develop
            withGradleEnv {
                sh 'git checkout develop'
                sh 'git reset --hard origin/develop'
                sh 'git merge master'
                gradle 'updateVersion -Prelease.useAutomaticVersion=true'
                sh 'git add gradle.properties'
                sh 'git commit -m "[release] new version"'
                sh 'git push'
            }
        }
    }

}

boolean lastCommitByJenkins() {
    def lastCommitAuthor = bash('git log -1 --pretty="%an"').trim()
    println "Last commit by: $lastCommitAuthor"
    return lastCommitAuthor == JENKINS_NAME
}

String getVersion() {
    def properties = readProperties file: 'gradle.properties'
    return properties.version
}