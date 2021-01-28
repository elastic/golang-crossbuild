
@Library('apm@current') _

pipeline {
  agent { label 'ubuntu-18 && immutable && docker-buildx' }
  environment {
    REPO = 'golang-crossbuild'
    BASE_DIR = "src/github.com/elastic/${env.REPO}"
    NOTIFY_TO = credentials('notify-to')
    HOME = "${env.WORKSPACE}"
    PIPELINE_LOG_LEVEL = 'INFO'
    DOCKER_REGISTRY_SECRET = 'secret/observability-team/ci/docker-registry/prod'
    REGISTRY = 'docker.elastic.co'
    STAGING_IMAGE = "${env.REGISTRY}/observability-ci"
    GO_VERSION = '1.15.6'
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
    issueCommentTrigger('(?i)(.*jenkins\\W+run\\W+(?:the\\W+)?tests(?:\\W+please)?.*|/test)')
  }
  stages {
    stage('Checkout') {
      steps {
        deleteDir()
        gitCheckout(basedir: BASE_DIR)
        stash name: 'source', useDefaultExcludes: false
      }
    }
    stage('Package'){
      matrix {
        agent { label 'ubuntu-20 && immutable' }
        axes {
          axis {
            name "MAKEFILE"
            values 'Makefile', 'Makefile.debian7', 'Makefile.debian8', 'Makefile.debian9', 'Makefile.debian10'
          }
          axis {
            name 'GO_FOLDER'
            values 'go1.14', 'go1.15'
          }
        }
        stages {
          stage('Staging') {
            environment {
              REPOSITORY = "${env.STAGING_IMAGE}"
            }
            steps {
              withGithubNotify(context: "Build ${GO_FOLDER} ${MAKEFILE}") {
                deleteDir()
                unstash 'source'
                buildAndPushImages()
              }
            }
          }
          stage('Release') {
            when {
              branch 'master'
            }
            steps {
              withGithubNotify(context: "Release ${GO_FOLDER} ${MAKEFILE}") {
                buildAndPushImages()
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

def buildAndPushImages(){
  dockerLogin(secret: "${env.DOCKER_REGISTRY_SECRET}", registry: "${env.REGISTRY}")
  sh 'docker buildx create --use'
  withGoEnv(){
    dir("${env.BASE_DIR}"){
      sh "make -C ${GO_FOLDER} -f ${MAKEFILE} build"
    }
  }
}
