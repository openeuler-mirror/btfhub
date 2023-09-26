pipeline {
    agent any

    options {
        disableConcurrentBuilds(abortPrevious: true)
        parallelsAlwaysFailFast()
    }

    triggers {
        cron('H H(0-6) * * *')
    }

    parameters {
        string(name: 'BTFHUB_ARCHIVE_REPO_URL',
            description: 'URL of the archive repository',
            defaultValue: 'https://gitee.com/openeuler/btfhub-archive.git')
        string(name: 'BTFHUB_ARCHIVE_BUILD_BRANCH',
            description: 'Branch of the archive repository to build upon',
            defaultValue: 'next')
        string(name: 'BTFHUB_GIT_AUTHOR_NAME_CREDENTIAL_ID',
            description: 'Credential ID for author name in commits',
            defaultValue: 'openeuler-btfhub-git-author-name')
        string(name: 'BTFHUB_GIT_AUTHOR_EMAIL_CREDENTIAL_ID',
            description: 'Credential ID for author email in commits',
            defaultValue: 'openeuler-btfhub-git-author-email')
        string(name: 'BTFHUB_GITEE_CREDENTIAL_ID',
            description: 'Credentail ID for authentication with Gitee',
            defaultValue: 'BTFHub-robot')
    }

    environment {
        // Override the default locale to avoid some locale-related issues,
        // such as inconsistent sort order of strings
        LC_ALL = 'C.UTF-8'
    }

    stages {
        stage('Check out repositories') {
            parallel {
                stage('Check out BTFHub') {
                    steps {
                        dir('btfhub') {
                            checkout scm
                        }
                    }
                }

                stage('Check out BTFHub Archive') {
                    steps {
                        dir('btfhub-archive') {
                            checkout scmGit(
                                branches: [[name: "*/${params.BTFHUB_ARCHIVE_BUILD_BRANCH}"]],
                                userRemoteConfigs: [[
                                    name: 'origin',
                                    url: params.BTFHUB_ARCHIVE_REPO_URL]],
                                extensions: [ localBranch() ])
                        }
                    }
                }
            }
        }

        stage('Build builder image') {
            steps {
                sh 'btfhub/tools/ci/build-builder.sh'
            }
        }

        stage('Prepare build environment') {
            steps {
                withCredentials([
                    string(
                        credentialsId: params.BTFHUB_GIT_AUTHOR_NAME_CREDENTIAL_ID,
                        variable: 'BTFHUB_GIT_AUTHOR_NAME'),
                    string(
                        credentialsId: params.BTFHUB_GIT_AUTHOR_EMAIL_CREDENTIAL_ID,
                        variable: 'BTFHUB_GIT_AUTHOR_EMAIL') ]) {
                    sh '''
                    btfhub/tools/ci/run-in-builder.sh env \
                        BTFHUB_GIT_AUTHOR_NAME="$BTFHUB_GIT_AUTHOR_NAME" \
                        BTFHUB_GIT_AUTHOR_EMAIL="$BTFHUB_GIT_AUTHOR_EMAIL" \
                        BTFHUB_ARCHIVE_BUILD_BRANCH="$BTFHUB_ARCHIVE_BUILD_BRANCH" \
                        btfhub/tools/ci/prepare-environment.sh
                    '''
                }
            }
        }

        stage('Generate BTF files (openEuler)') {
            steps {
                sh 'btfhub/tools/ci/run-in-builder.sh btfhub/tools/ci/generate-btf.sh -distro openEuler'
            }
        }

        stage('Validate BTF files') {
            steps {
                sh 'btfhub/tools/ci/run-in-builder.sh btfhub/tools/ci/validate-btf.sh'
            }
        }

        stage('Commit, push & create PR') {
            steps {
                withCredentials([ usernamePassword(
                    credentialsId: params.BTFHUB_GITEE_CREDENTIAL_ID,
                    usernameVariable: 'BTFHUB_GIT_USERNAME',
                    passwordVariable: 'BTFHUB_GIT_PASSWORD') ]) {
                    sh '''
                    btfhub/tools/ci/run-in-builder.sh env \
                        BTFHUB_GIT_USERNAME="$BTFHUB_GIT_USERNAME" \
                        BTFHUB_GIT_PASSWORD="$BTFHUB_GIT_PASSWORD" \
                        BUILD_URL="$BUILD_URL" \
                        btfhub/tools/ci/commit-push.sh
                    '''
                }

                withCredentials([ usernamePassword(
                    credentialsId: params.BTFHUB_GITEE_CREDENTIAL_ID,
                    usernameVariable: '_UNUSED',
                    passwordVariable: 'BTFHUB_GITEE_API_TOKEN') ]) {
                    sh '''
                    btfhub/tools/ci/run-in-builder.sh env \
                        BTFHUB_GITEE_API_TOKEN="$BTFHUB_GITEE_API_TOKEN" \
                        JOB_NAME="$JOB_NAME" \
                        JOB_URL="$JOB_URL" \
                        btfhub/tools/ci/create-pr.sh
                    '''
                }
            }
        }
    }

    post {
        cleanup {
            cleanWs()
        }
    }
}
