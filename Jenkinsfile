
@Library('apm@current') _

pipeline {
  agent { label 'ubuntu-20 && immutable' }
  environment {
    REPO = 'golang-crossbuild'
    BASE_DIR = "src/github.com/elastic/${env.REPO}"
    NOTIFY_TO = credentials('notify-to')
    HOME = "${env.WORKSPACE}"
    PIPELINE_LOG_LEVEL = 'INFO'
    DOCKER_REGISTRY_SECRET = 'secret/observability-team/ci/docker-registry/prod'
    REGISTRY = 'docker.elastic.co'
    STAGING_IMAGE = "${env.REGISTRY}/observability-ci"
    GO_VERSION = '1.18.1'
  }
  options {
    timeout(time: 3, unit: 'HOURS')
    buildDiscarder(logRotator(numToKeepStr: '20', artifactNumToKeepStr: '20', daysToKeepStr: '30'))
    timestamps()
    ansiColor('xterm')
    disableResume()
    durabilityHint('PERFORMANCE_OPTIMIZED')
    rateLimitBuilds(throttle: [count: 60, durationName: 'hour', userBoost: true])
    quietPeriod(10)
  }
  triggers {
    issueCommentTrigger("${obltGitHubComments()}")
  }
  stages {
    stage('Checkout') {
      options { skipDefaultCheckout() }
      steps {
        deleteDir()
        gitCheckout(basedir: BASE_DIR)
        stash name: 'source', useDefaultExcludes: false
      }
    }
    stage('Package'){
      options { skipDefaultCheckout() }
      matrix {
        agent { label "${PLATFORM}"  }
        axes {
          axis {
            name 'MAKEFILE'
            values 'Makefile', 'Makefile.debian7', 'Makefile.debian8', 'Makefile.debian9', 'Makefile.debian10', 'Makefile.debian11'
          }
          axis {
            name 'PLATFORM'
            values 'ubuntu-20 && immutable', 'arm'
          }
        }
        excludes {
          exclude {
            axis {
              name 'PLATFORM'
              values 'arm'
            }
            axis {
              name 'MAKEFILE'
              values 'Makefile'
            }
          }
          exclude {
            axis {
              name 'PLATFORM'
              values 'arm'
            }
            axis {
              name 'MAKEFILE'
              values 'Makefile.debian7'
            }
          }
          exclude {
            axis {
              name 'PLATFORM'
              values 'arm'
            }
            axis {
              name 'MAKEFILE'
              values 'Makefile.debian8'
            }
          }
          exclude {
            axis {
              name 'PLATFORM'
              values 'arm'
            }
            axis {
              name 'MAKEFILE'
              values 'Makefile.debian10'
            }
          }
          exclude {
            axis {
              name 'PLATFORM'
              values 'arm'
            }
            axis {
              name 'MAKEFILE'
              values 'Makefile.debian11'
            }
          }
        }
        stages {
          stage('Staging') {
            when {
              changeRequest()
            }
            environment {
              REPOSITORY = "${env.STAGING_IMAGE}"
            }
            steps {
              stageStatusCache(id: "Build ${MAKEFILE} ${PLATFORM}") {
                withGithubNotify(context: "Build ${MAKEFILE} ${PLATFORM}") {
                  deleteDir()
                  unstash 'source'
                  buildImages()
                }
                withGithubNotify(context: "Staging ${MAKEFILE} ${PLATFORM}") {
                  publishImages()
                }
              }
            }
          }
          stage('Release') {
            when {
              anyOf {
                branch 'main'
                branch pattern: "\\d+\\.\\d+", comparator: 'REGEXP'
              }
            }
            steps {
              withGithubNotify(context: "Release ${MAKEFILE} ${PLATFORM}") {
                deleteDir()
                unstash 'source'
                buildImages()
                publishImages()
              }
            }
          }
        }
      }
    }
    stage('Post-Release') {
      when {
        anyOf {
          branch 'main'
          branch pattern: "\\d+\\.\\d+", comparator: 'REGEXP'
        }
      }
      environment {
        HOME = "${env.WORKSPACE}"
        PATH = "${env.HOME}/bin:${env.WORKSPACE}/${env.BASE_DIR}/.ci/scripts:${env.PATH}"
      }
      options { skipDefaultCheckout() }
      steps {
        whenTrue(isNewRelease()) {
          postRelease()
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
  log(level: 'INFO', text: "buildImages with ${MAKEFILE} for ${PLATFORM}")
  withGoEnv(){
    withGCPEnv(secret: 'secret/observability-team/ci/elastic-observability-account-auth'){
      dir("${env.BASE_DIR}"){
        def platform = (PLATFORM?.trim().equals('arm')) ? '-arm' : ''
        retryWithSleep(retries: 3, seconds: 15, backoff: true) {
          sh "make -C go -f ${MAKEFILE} build${platform}"
        }
        sh(label: 'list Docker images', script: 'docker images --format "table {{.Repository}}:{{.Tag}}\t{{.Size}}" --filter=reference="docker.elastic.co/beats-dev/golang-crossbuild"')
      }
    }
  }
}

def publishImages(){
  log(level: 'INFO', text: "publish with ${MAKEFILE} for ${PLATFORM}")
  dockerLogin(secret: "${env.DOCKER_REGISTRY_SECRET}", registry: "${env.REGISTRY}")
  dir("${env.BASE_DIR}"){
    def platform = (PLATFORM?.trim().equals('arm')) ? '-arm' : ''
    retryWithSleep(retries: 3, seconds: 15, backoff: true) {
      sh(label: "push docker image to ${env.REPOSITORY}", script: "make -C go -f ${MAKEFILE} push${platform}")
    }
  }
}

def isNewRelease() {
  def releases = listGithubReleases()
  log(level: 'INFO', text: "isNewRelease: ${releases}")
  if (env.GO_VERSION?.trim()) {
    def existsRelease = releases.containsKey(env.GO_VERSION)
    log(level: 'INFO', text: "isNewRelease: look for the GO_VERSION if matches any tag release in the project = ${existsRelease}")
    return !existsRelease
  }
  return false
}

def postRelease(){
  deleteDir()
  unstash 'source'
  dockerLogin(secret: "${env.DOCKER_REGISTRY_SECRET}", registry: "${env.REGISTRY}")
  dir("${env.BASE_DIR}"){
    sh(label: 'Set branch', script: """#!/bin/bash
      git checkout -b ${BRANCH_NAME}
    """)
    try {
      gitCreateTag(tag: "${env.GO_VERSION}", pushArgs: '--force')
      withCredentials([string(credentialsId: '2a9602aa-ab9f-4e52-baf3-b71ca88469c7', variable: 'GREN_GITHUB_TOKEN')]) {
        sh(label: 'Creating Release Notes', script: '.ci/scripts/release-notes.sh')
      }
      gh(command: "release create ${env.GO_VERSION}", flags: [ "notes-file": ['CHANGELOG.md'], title: "${env.GO_VERSION}" ])
    } catch (e) {
      // Probably the tag already exists
      log(level: 'WARN', text: "postRelease failed with message : ${e?.message}")
    }
  }
}
