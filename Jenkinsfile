
@Library('apm@current') _

pipeline {
  agent { label 'ubuntu && immutable' }
  environment {
    REPO = 'golang-crossbuild'
    BASE_DIR = "src/github.com/elastic/${env.REPO}"
    NOTIFY_TO = credentials('notify-to')
    HOME = "${env.WORKSPACE}"
    PIPELINE_LOG_LEVEL = 'INFO'
    DOCKER_REGISTRY_SECRET = 'secret/observability-team/ci/docker-registry/prod'
    REGISTRY = 'docker.elastic.co'
    STAGING_IMAGE = "${env.REGISTRY}/observability-ci"
    GO_VERSION = '1.15.4'
  }
  options {
    timeout(time: 2, unit: 'HOURS')
    buildDiscarder(logRotator(numToKeepStr: '20', artifactNumToKeepStr: '20', daysToKeepStr: '30'))
    timestamps()
    ansiColor('xterm')
    disableResume()
    durabilityHint('PERFORMANCE_OPTIMIZED')
    rateLimitBuilds(throttle: [count: 60, durationName: 'hour', userBoost: true])
    quietPeriod(10)
  }
  triggers {
    issueCommentTrigger('(?i).*jenkins\\W+run\\W+(?:the\\W+)?tests(?:\\W+please)?.*')
  }
  stages {
    stage('Checkout') {
      steps {
        deleteDir()
        gitCheckout(basedir: BASE_DIR)
        stash name: 'source', useDefaultExcludes: false
      }
    }
    stage('Build') {
      steps {
        withGithubNotify(context: 'Build') {
          deleteDir()
          unstash 'source'
          buildImages()
        }
      }
    }
    stage('Staging') {
      environment {
        REPOSITORY = "${env.STAGING_IMAGE}"
      }
      steps {
        withGithubNotify(context: 'Staging') {
          // It will use the already cached docker images that were created in the
          // Build stage. But it's required to retag them with the staging repo.
          buildImages()
          publishImages()
        }
      }
    }
    stage('Release') {
      when {
        branch 'master'
      }
      stages {
        stage('Publish') {
          steps {
            withGithubNotify(context: 'Publish') {
              publishImages()
            }
          }
        }
      }
    }
  }
  post {
    always {
      notifyBuildResult()
    }
  }
}

def buildImages(){
  withGoEnv(){
    dir("${env.BASE_DIR}"){
      sh 'make build'
    }
  }
}

def publishImages(){
  dockerLogin(secret: "${env.DOCKER_REGISTRY_SECRET}", registry: "${env.REGISTRY}")
  dir("${env.BASE_DIR}"){
    sh(label: "push docker image to ${env.REPOSITORY}", script: 'make push')
  }
}
