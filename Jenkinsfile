
@Library('apm@current') _

pipeline {
  agent { label 'linux && immutable' }
  environment {
    REPO = 'golang-crossbuild'
    BASE_DIR = "src/github.com/elastic/${env.REPO}"
    NOTIFY_TO = credentials('notify-to')
    PIPELINE_LOG_LEVEL = 'INFO'
    HOME = "${env.WORKSPACE}"
    DOCKER_REGISTRY_SECRET = 'secret/apm-team/ci/docker-registry/prod'
    REGISTRY = 'docker.elastic.co'
    STAGING_IMAGE = "${env.REGISTRY}/observability-ci"
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
        stash allowEmpty: true, name: 'source', useDefaultExcludes: false
      }
    }
    stage('Build') {
      steps {
        withGithubNotify(context: 'Build') {
          deleteDir()
          unstash 'source'
          dir(BASE_DIR){
            sh 'make build'
          }
        }
      }
    }
    stage('Staging') {
      steps {
        withGithubNotify(context: 'Staging') {
          dir(BASE_DIR){
            dockerLogin(secret: "${DOCKER_REGISTRY_SECRET}", registry: "${REGISTRY}")
            sh(label: "push docker image to ${env.STAGING_IMAGE}/${env.REPO}",
               script: "REPOSITORY=${env.STAGING_IMAGE}/${env.REPO} VERSION=${env.BRANCH_NAME} make push")
          }
        }
      }
    }
    stage('Release') {
      when {
        anyOf {
          tag pattern: 'v\\d+\\.\\d+.*', comparator: 'REGEXP'
        }
      }
      stages {
        stage('Publish') {
          steps {
            withGithubNotify(context: 'Publish') {
              dir(BASE_DIR){
                dockerLogin(secret: "${DOCKER_REGISTRY_SECRET}", registry: "${REGISTRY}")
                sh 'make push'
              }
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