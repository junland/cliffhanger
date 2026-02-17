pipeline {
    agent any

    parameters {
        choice(name: 'TARGET_ARCH', choices: ['x86_64'], description: 'Target CPU architecture')
    }

    stages {
        stage('Install Dependencies') {
            steps {
                sh '''
                    sudo apt-get update
                    sudo apt-get install -y \
                        autoconf \
                        autoconf2.69 \
                        automake \
                        autopoint \
                        bison \
                        build-essential \
                        byacc \
                        flex \
                        gawk \
                        gettext \
                        gperf \
                        help2man \
                        libssl-dev \
                        libtool \
                        m4 \
                        make \
                        meson \
                        ninja-build \
                        perl \
                        pkg-config \
                        tree \
                        unzip \
                        zlib1g-dev
                '''
            }
        }

        stage('Reconfigure sh to use bash') {
            steps {
                sh '''
                    echo 'dash dash/sh boolean false' | sudo debconf-set-selections
                    sudo dpkg-reconfigure -f noninteractive dash
                    sudo ln -sf bash /bin/sh
                '''
            }
        }

        stage('Prepare Scripts') {
            steps {
                sh 'chmod +x ./scripts/*.sh'
            }
        }

        stage('Version Check') {
            steps {
                sh './scripts/version_check.sh'
            }
        }

        stage('Get Sources') {
            steps {
                sh 'mkdir -p rootfs/tmp/sources'
                sh 'wget -nv --tries=15 --waitretry=15 -i scripts/data/bootstrap-sources.list -P rootfs/tmp/sources'
            }
        }

        stage('Verify Sources') {
            steps {
                dir('rootfs/tmp/sources') {
                    sh "sha512sum -c ${env.WORKSPACE}/scripts/data/bootstrap-sources.list.sha512sum"
                }
                sh 'ls -lah rootfs/tmp/sources'
            }
        }

        stage('Bootstrap') {
            steps {
                sh """
                    set -o pipefail
                    TARGET_ARCH=${params.TARGET_ARCH} ${env.WORKSPACE}/scripts/bootstrap.sh > ${env.WORKSPACE}/scripts/bootstrap.log 2>&1 &
                    BOOTSTRAP_PID=\$!

                    tail -F ${env.WORKSPACE}/scripts/bootstrap.log | grep --line-buffered -E '^ ==>' &

                    wait \$BOOTSTRAP_PID

                    if [ \$? -ne 0 ]; then
                        echo '❌ Build failed! Showing last 50 lines:'
                        tail -n 50 ${env.WORKSPACE}/scripts/bootstrap.log
                        exit 1
                    fi
                """
            }
        }

        stage('Archive rootfs') {
            steps {
                sh "tar -czf ${env.WORKSPACE}/rootfs.tar.gz -C ${env.WORKSPACE} rootfs"
                archiveArtifacts artifacts: 'rootfs.tar.gz', fingerprint: true
            }
        }
    }

    post {
        failure {
            script {
                if (fileExists("${env.WORKSPACE}/scripts/bootstrap.log")) {
                    sh "tail -n 100 ${env.WORKSPACE}/scripts/bootstrap.log"
                }
            }
        }
        cleanup {
            cleanWs()
        }
    }
}
