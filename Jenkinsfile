#!/usr/bin/env groovy
// Licensed to Elasticsearch B.V. under one or more contributor
// license agreements. See the NOTICE file distributed with
// this work for additional information regarding copyright
// ownership. Elasticsearch B.V. licenses this file to you under
// the Apache License, Version 2.0 (the "License"); you may
// not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations
// under the License.

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
    DOCKER_REGISTRY = 'docker.elastic.co'
    STAGING_IMAGE = "${env.DOCKER_REGISTRY}/observability-ci"
    GO_VERSION = '1.19.2'
    BUILDX = "1"
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
          withDockerEnv(secret: "${env.DOCKER_REGISTRY_SECRET}", registry: "${env.DOCKER_REGISTRY}") {
            sh "make -C go -f ${MAKEFILE} build${platform}"
          }
        }
        sh(label: 'list Docker images staging', script: """docker images --format "table {{.Repository}}:{{.Tag}}\t{{.Size}}" --filter=reference="${STAGING_IMAGE}/golang-crossbuild" """)
        sh(label: 'list Docker images production', script: """docker images --format "table {{.Repository}}:{{.Tag}}\t{{.Size}}" --filter=reference="${env.DOCKER_REGISTRY}/beats-dev/golang-crossbuild" """)
      }
    }
  }
}

def publishImages(){
  log(level: 'INFO', text: "publish with ${MAKEFILE} for ${PLATFORM}")
  dockerLogin(secret: "${env.DOCKER_REGISTRY_SECRET}", registry: "${env.DOCKER_REGISTRY}")
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
  dir("${env.BASE_DIR}"){
    sh(label: 'Set branch', script: "git checkout -b ${BRANCH_NAME}")
    try {
      gitCreateTag(tag: "v${env.GO_VERSION}", pushArgs: '--force')
    } catch (e) {
      // Probably the tag already exists
      log(level: 'WARN', text: "postRelease failed with message : ${e?.message}")
    }
  }
}
