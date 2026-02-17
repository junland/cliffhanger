pipeline {
    agent any

    parameters {
        choice(name: 'TARGET_CPU_ARCH', choices: ['x86_64', 'aarch64'], description: 'Target CPU architecture')
    }

    stages {
        stage('Prepare') {
            steps {
                git branch: 'mock', url: 'https://github.com/junland/cliffhanger.git'
                sh 'chmod +x ${env.WORKSPACE}/scripts/*.sh'
                sh 'chmod +x ${env.WORKSPACE}/scripts/*.sh'
                sh 'mkdir -p ${env.WORKSPACE}/rootfs'
                sh 'mkdir -p ${env.WORKSPACE}/rootfs/tmp/sources'
            }
        }

        stage('Version Check') {
            steps {
                sh '${env.WORKSPACE}/scripts/version_check.sh'
            }
        }

        stage('Get Sources') {
            steps {
                sh 'wget -nv --tries=15 --waitretry=15 -i ${env.WORKSPACE}/scripts/data/bootstrap-sources.list -P ${env.WORKSPACE}/rootfs/tmp/sources'
            }
        }

        stage('Verify Sources') {
            steps {
                dir('${env.WORKSPACE}/rootfs/tmp/sources') {
                    sh "sha512sum -c ${env.WORKSPACE}/scripts/data/bootstrap-sources.list.sha512sum"
                }
                sh 'ls -lah ${env.WORKSPACE}/rootfs/tmp/sources'
            }
        }

        stage('Bootstrap Stage 1') {
            steps {
                sh """
                    set -o pipefail
                    TARGET_ARCH=${params.TARGET_ARCH} ${env.WORKSPACE}/scripts/bootstrap.sh > ${env.WORKSPACE}/scripts/bootstrap_stage1.log 2>&1 &
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

        stage('Archive Stage 1') {
            steps {
                sh "tar -czpf ${env.WORKSPACE}/rootfs-stage1-${env.TARGET_CPU_ARCH}-${env.BUILD_NUMBER}.tar.gz -C ${env.WORKSPACE}/rootfs"
                archiveArtifacts artifacts: "rootfs-stage1-${env.TARGET_CPU_ARCH}-${env.BUILD_NUMBER}.tar.gz", fingerprint: true
            }
        }
        
        stage('Bootstrap Stage 2') {
            steps {
                sh """
                    set -o pipefail
                    sudo ${env.WORKSPACE}/scripts/chroot_bootstrap.sh ${env.WORKSPACE}/rootfs 2 > ${env.WORKSPACE}/scripts/chroot_bootstrap_stage2.log 2>&1 &
                    BOOTSTRAP_PID=\$!
    
                    tail -F ${env.WORKSPACE}/scripts/chroot_bootstrap_stage2.log | grep --line-buffered -E '^ ==>' &
    
                    wait \$BOOTSTRAP_PID
    
                    if [ \$? -ne 0 ]; then
                        echo '❌ Build failed! Showing last 50 lines:'
                        tail -n 50 ${env.WORKSPACE}/scripts/chroot_bootstrap_stage2.log
                        exit 1
                    fi
                """
            }
        }

        stage('Archive Stage 2') {
            steps {
                sh "tar -czpf ${env.WORKSPACE}/rootfs-stage2-${env.TARGET_CPU_ARCH}-${env.BUILD_NUMBER}.tar.gz -C ${env.WORKSPACE}/rootfs"
                archiveArtifacts artifacts: "rootfs-stage2-${env.TARGET_CPU_ARCH}-${env.BUILD_NUMBER}.tar.gz", fingerprint: true
            }
        }
        
    }

    post {
        cleanup {
            cleanWs()
        }
    }
}
