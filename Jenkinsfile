pipeline {
  agent { label 'linux' }
  environment {
    IMAGE_NAME = "flutter-builder:ci"
    MOBSF_URL = "http://localhost:8000"
    MOBSF_API_KEY = '47508b132990845541115d5d5e3eb5308d08d3caba3dce99b1cdb2ea236957a3'
  }
  stages {
    stage('Checkout') {
      steps { checkout scm }
    }

    stage('Build image') {
      steps {
        sh "docker build -t ${IMAGE_NAME} -f Dockerfile ."
      }
    }

    stage('Build APK') {
      steps {
        sh '''
          docker run --rm \
            -v ${WORKSPACE}:/work -w /work \
            -v gradle-cache:/home/builder/.gradle \
            -v flutter-pub-cache:/home/builder/.pub-cache \
            ${IMAGE_NAME} \
            /bin/bash -lc "flutter pub get && flutter build apk --release && cp build/app/outputs/flutter-apk/app-release.apk /work/"
        '''
      }
    }

    stage('Upload to MobSF (SAST)') {
      steps {
        sh '''
          APK=$(ls build/app/outputs/**/*.apk | head -n1)
          echo "Uploading $APK to MobSF..."
          UPLOAD_RES=$(curl -s -X POST "${MOBSF_URL}/api/v1/upload" -H "Authorization: ${MOBSF_API_KEY}" -F "file=@${APK}")
          HASH=$(echo "$UPLOAD_RES" | jq -r .hash)
          curl -s -X POST "${MOBSF_URL}/api/v1/scan" -H "Authorization: ${MOBSF_API_KEY}" -F "hash=${HASH}" -F "scan_type=apk" > mobsf_scan.json
          curl -s -X POST "${MOBSF_URL}/api/v1/report_json" -H "Authorization: ${MOBSF_API_KEY}" -d "hash=${HASH}" > mobsf_report.json || true
          curl -s -X POST "${MOBSF_URL}/api/v1/report_pdf" -H "Authorization: ${MOBSF_API_KEY}" -d "hash=${HASH}" > mobsf_report.pdf || true
        '''
      }
    }

    stage('Evaluate & Archive') {
      steps {
        sh '''
          HIGH=$(jq '.severity.high // 0' mobsf_report.json 2>/dev/null || echo 0)
          echo "High issues: $HIGH"
          if [ "$HIGH" -gt 0 ]; then
            echo "Failing build: high issues found"
            exit 1
          fi
        '''
        archiveArtifacts artifacts: 'build/app/outputs/**/*.apk, mobsf_report.*', fingerprint: true
      }
    }
  }
}
