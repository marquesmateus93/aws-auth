#!/bin/bash

export AWS_ACCESS_KEY_ID=""     && \
export AWS_SECRET_ACCESS_KEY="" && \
export AWS_SESSION_TOKEN=""     && \
export AWS_EXPIRATION=""        && \
export AWS_REGION=""            && \
export AWS_PROFILE=""

# Load functions from read-aws-config.sh
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "${SCRIPT_DIR}/read-aws-config.sh"

function sso_login() {
  aws \
  sso \
  login > /dev/null 2>&1
  
  if [ $? -eq 0 ]; then
    export SSO_LOGIN_ERROR=0
    return 0
  else
    export SSO_LOGIN_ERROR=1
    return 1
  fi
}

function caller_identity() {
  IDENTIFY=$(aws \
  sts \
  get-caller-identity)
}

function export_credentials() {
  CREDENTIALS=$(aws \
  configure \
  export-credentials)
}

function variables_exporter() {
  export AWS_ACCOUNT_ID=$(echo        ${IDENTIFY}     | jq -r '.Account') && \
  export AWS_ACCESS_KEY_ID=$(echo     ${CREDENTIALS}  | jq -r '.AccessKeyId') && \
  export AWS_SECRET_ACCESS_KEY=$(echo ${CREDENTIALS}  | jq -r '.SecretAccessKey')&& \
  export AWS_SESSION_TOKEN=$(echo     ${CREDENTIALS}  | jq -r '.SessionToken' )&& \
  export AWS_EXPIRATION=$(echo        ${CREDENTIALS}  | jq -r '.Expiration')
}

function docker_login() {
  aws ecr get-login-password \
  --region ${AWS_REGION} | docker login \
  --username AWS \
  --password-stdin ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com > /dev/null 2>&1
  
  if [ $? -eq 0 ]; then
    echo "🐳 Docker ECR Login Successful!"
    return 0
  else
    echo "❌ Error Performing Docker ECR Login"
    return 1
  fi
}

function helm_login() {
  aws ecr get-login-password \
  --region ${AWS_REGION} | helm registry login \
  --username AWS \
  --password-stdin ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com > /dev/null 2>&1
  
  if [ $? -eq 0 ]; then
    echo "⚓️ Helm Registry Login Successful!"
    echo ""
    return 0
  else
    echo "❌ Error Performing Helm Registry Login"
    echo ""
    return 1
  fi
}

main(){
  loop_menu           && \
  sso_login           && \
  caller_identity     && \
  export_credentials  && \
  variables_exporter  && \
  show_profile_info   && \
  docker_login        && \
  helm_login
}

main