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
            defaultValue: 'gitee-hanlinyang-username-password')
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

                            withCredentials([
                                string(
                                    credentialsId: params.BTFHUB_GIT_AUTHOR_NAME_CREDENTIAL_ID,
                                    variable: 'BTFHUB_GIT_AUTHOR_NAME'),
                                string(
                                    credentialsId: params.BTFHUB_GIT_AUTHOR_EMAIL_CREDENTIAL_ID,
                                    variable: 'BTFHUB_GIT_AUTHOR_EMAIL') ]) {
                                sh 'git config --local user.name "$BTFHUB_GIT_AUTHOR_NAME"'
                                sh 'git config --local user.email "$BTFHUB_GIT_AUTHOR_EMAIL"'
                            }

                            sh 'git rebase origin/master'
                            sh "git branch --set-upstream-to origin/${params.BTFHUB_ARCHIVE_BUILD_BRANCH}"
                        }
                    }
                }
            }
        }

        stage('Build builder image') {
            steps {
                dir('btfhub') {
                    sh 'docker build -t openeuler-btfhub-ci-builder - < tools/ci/Dockerfile'
                }

                script {
                    uid = sh(script: 'id -u', returnStdout: true).trim()
                    gid = sh(script: 'id -g', returnStdout: true).trim()
                    env.RUN_IN_BUILDER = """
                    docker run \
                        --rm \
                        -u ${uid}:${gid} \
                        -v ${env.WORKSPACE}:/workspace \
                        -w /workspace \
                        openeuler-btfhub-ci-builder \
                    """
                }
            }
        }

        stage('Inspect build environment') {
            steps {
                sh 'uname -a'
                sh 'docker version'
                sh 'git --version'
                sh '''
                $RUN_IN_BUILDER bash -x -c " \
                    uname -a && \
                    clang --version && \
                    find --version && \
                    git --version && \
                    go version && \
                    jq --version && \
                    make --version && \
                    pahole --version && \
                    rsync --version && \
                    xargs --version && \
                    xz --version"
                '''
            }
        }

        stage('Generate BTF files') {
            steps {
                sh '''
                $RUN_IN_BUILDER bash -x -c " \
                    cd btfhub && \
                    make bring && \
                    make && \
                    ./btfhub -distro openEuler && \
                    make take"
                '''
            }
        }

        stage('Commit, push & create PR') {
            steps {
                dir('btfhub-archive') {
                    sh 'git add -A'
                    sh 'git status'
                    sh '''
                    git diff-index --quiet HEAD || \
                    ( printf '%s\\n' \
                        "Update BTFHub Archive" \
                        "" \
                        "This commit is created by an automated build process; see also <$BUILD_URL>." \
                    | git commit -F - ) && \
                    git log -1
                    '''

                    withCredentials([
                        gitUsernamePassword(credentialsId: params.BTFHUB_GITEE_CREDENTIAL_ID) ]) {
                        sh 'git push --force-with-lease'
                    }
                }

                withCredentials([ usernamePassword(
                    credentialsId: params.BTFHUB_GITEE_CREDENTIAL_ID,
                    usernameVariable: '_UNUSED',
                    passwordVariable: 'BTFHUB_GITEE_API_TOKEN') ]) {
                    sh '''
                    $RUN_IN_BUILDER bash -x -c " \
                        cd btfhub-archive && \
                        BTFHUB_GITEE_API_TOKEN="$BTFHUB_GITEE_API_TOKEN" \
                        JOB_NAME="$JOB_NAME" \
                        JOB_URL="$JOB_URL" \
                        ../btfhub/tools/ci/create-pr.sh"
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
