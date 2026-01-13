pipeline {
  agent any
  environment {
    IMAGE_NAME = "flutter-builder:ci"
    MOBSF_URL = "http://localhost:8000"
    MOBSF_API_KEY = "47508b132990845541115d5d5e3eb5308d08d3caba3dce99b1cdb2ea236957a3"
  }

  stages {
    stage('Checkout') {
      steps {
        checkout scm
      }
    }

    stage('Build image') {
      steps {
        script {
          bat "docker build -t ${IMAGE_NAME} -f Dockerfile ."
        }
      }
    }

    stage('Build APK') {
      steps {
        script {
          bat "if exist pubspec.lock del /f /q pubspec.lock"

          bat """
            docker run --rm ^
              --user root ^
              -v "%WORKSPACE%:/work" ^
              -w /work ^
              -v gradle-cache:/root/.gradle ^
              -v flutter-pub-cache:/root/.pub-cache ^
              ${IMAGE_NAME} ^
              /bin/bash -lc "flutter pub get && flutter build apk --release && cp build/app/outputs/flutter-apk/app-release.apk /work/"
          """
        }
      }
    }

    stage('Upload to MobSF (SAST)') {
      steps {
        powershell '''
          Write-Warning "MobSF upload dijalankan manual atau via Linux agent"
        '''
      }
    }

    stage('Evaluate & Archive') {
      steps {
        archiveArtifacts artifacts: 'build/app/outputs/**/*.apk', fingerprint: true, allowEmptyArchive: false
      }
    }
  }
}
