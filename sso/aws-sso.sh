#!/bin/bash

export AWS_ACCESS_KEY_ID="" && \
export AWS_SECRET_ACCESS_KEY="" && \
export AWS_SESSION_TOKEN="" && \
export AWS_EXPIRATION="" && \

. auth.config

function sso_login() {
  aws \
  sso \
  login
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
  --password-stdin ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com
}

function helm_login() {
  aws ecr get-login-password \
  --region ${AWS_REGION} | helm registry login \
  --username AWS \
  --password-stdin ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com
}

main(){
  sso_login           && \
  caller_identity     && \
  export_credentials  && \
  variables_exporter  && \
  docker_login        && \
  helm_login
}

main