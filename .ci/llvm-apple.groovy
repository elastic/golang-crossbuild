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
    REGISTRY = 'docker.elastic.co'
    STAGING_IMAGE = "${env.REGISTRY}/observability-ci"
  }
  options {
    timeout(time: 5, unit: 'HOURS')
    buildDiscarder(logRotator(numToKeepStr: '7', artifactNumToKeepStr: '7', daysToKeepStr: '30'))
    timestamps()
    ansiColor('xterm')
    disableResume()
    durabilityHint('PERFORMANCE_OPTIMIZED')
    rateLimitBuilds(throttle: [count: 60, durationName: 'hour', userBoost: true])
    quietPeriod(10)
  }
  stages {
    stage('before checkout when changelog'){
      when {
        changelog '.ci/llvm-apple.groovy'
      }
      steps {
        echo 'before checkout when changelog'
      }
    }
    stage('before checkout when changeset'){
      when {
        changeset '.ci/llvm-apple.groovy'
      }
      steps {
        echo 'before checkout when changeset'
      }
    }
    stage('before checkout when isGitRegionMatch'){
      when {
        expression {  return isGitRegionMatch(patterns: ['^\\.ci/llvm-apple.groovy', '^/go/llvm-apple'], shouldMatchAll: false) }
      }
      steps {
        echo 'before checkout when isGitRegionMatch'
      }
    }
    stage('Checkout') {
      options { skipDefaultCheckout() }
      steps {
          printChangelog()
          deleteDir()
          gitCheckout(basedir: BASE_DIR)
          stash name: 'source', useDefaultExcludes: false
          printChangelog()
      }
    }
    stage('when changelog'){
      when {
        changelog '.ci/llvm-apple.groovy'
      }
      steps {
        echo 'when changelog'
      }
    }
    stage('when changeset'){
      when {
        changeset '.ci/llvm-apple.groovy'
      }
      steps {
        echo 'when changeset'
      }
    }
    stage('when isGitRegionMatch'){
      steps {
        dir(BASE_DIR){
          echo 'when isGitRegionMatch: ' + isGitRegionMatch(patterns: ['^\\.ci/llvm-apple.groovy', '^/go/llvm-apple'], shouldMatchAll: false)
        }
      }
    }
    stage('when isGitRegionMatch 2'){
      when {
        expression {
          return  dir(BASE_DIR){isGitRegionMatch(patterns: ['^\\.ci/llvm-apple.groovy', '^/go/llvm-apple'], shouldMatchAll: false)}
        }
      }
      steps {
        dir(BASE_DIR){
          echo 'when isGitRegionMatch'
        }
      }
    }
    stage('Check changes'){
      when {
        anyOf {
          // changelog '/go/llvm-apple/*'
          // changelog '.ci/llvm-apple.groovy'
          // changeset '/go/llvm-apple/**'
          // changeset '.ci/llvm-apple.groovy'
          expression {  return isGitRegionMatch(patterns: ['^\\.ci/llvm-apple.groovy', '^/go/llvm-apple'], shouldMatchAll: false) }
          expression { return isUserTrigger() }
        }
      }
      stages {
        stage('Build Matrix') {
          matrix {
            agent { label 'ubuntu-20 && immutable' }
            axes {
              axis {
                name 'DEBIAN_VERSION'
                values '10', '11'
              }
            }
            stages {
              stage('Build'){
                environment {
                    MAKEFILE = "go/llvm-apple"
                    TAG_EXTENSION = "-debian${env.DEBIAN_VERSION}"
                }
                options { skipDefaultCheckout() }
                steps {
                  stageStatusCache(id: "Build ${MAKEFILE}") {
                    whenTrue(isPR()){
                      setEnvVar("REPOSITORY", "${env.STAGING_IMAGE}")
                    }
                    withGithubNotify(context: "Build ${MAKEFILE}") {
                      deleteDir()
                      unstash 'source'
                      buildImages()
                    }
                    withGithubNotify(context: "Staging ${MAKEFILE}") {
                      publishImages()
                    }
                  }
                }
              }
            }
          }
        }
      }
    }
  }
}

def buildImages() {
  withGoEnv {
    dir("${env.BASE_DIR}") {
        retryWithSleep(retries: 3, seconds: 15, backoff: true) {
            sh(label: 'Build Docker image', script: "make -C ${MAKEFILE} build")
        }
        sh(label: 'list Docker images', script: 'docker images --format "table {{.Repository}}:{{.Tag}}\t{{.Size}}" --filter=reference="docker.elastic.co/beats-dev"')
    }
  }
}

def publishImages() {
  dockerLogin(secret: "${env.DOCKER_REGISTRY_SECRET}", registry: "${env.REGISTRY}")
  dir("${env.BASE_DIR}") {
    retryWithSleep(retries: 3, seconds: 15, backoff: true) {
      sh(label: "push docker image to ${env.REPOSITORY}", script: "make -C ${MAKEFILE} push")
    }
  }
}

def printChangelog(){
  currentBuild.changeSets.each { changeLogSet ->
    changeLogSet.items.each { entry ->
      echo "${entry?.commitId} by ${entry?.author} on ${new Date(entry?.timestamp)}: ${entry?.msg}"
      def files = new ArrayList(entry.affectedFiles)
      files.each { file ->
        echo "  ${file?.editType.name} ${file?.path}"
      }
    }
  }
}
