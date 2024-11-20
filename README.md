# AWS Auth

## Motivation

AWS DevOps administrators commonly manages at least three accounts: development, staging and production.
Although all environment profile configuration stay in **~/.aws/**, switch between then via AWS CLI **--profile** argument cloud might be boring.
Terraform and Terragrunt need AWS variable values for AWS Provider authentication, which AWS CLI does not export.

## Supported Authentication Types

| Name | Description                             |
|------|-----------------------------------------|
| IAM  | Assume Role credentials provided by IAM |
| SSO  | Credentials provided by Identity Center |

## How to Use

### Requirements(Unix/Bash)

- [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)
- [JQ](https://jqlang.github.io/jq/download/)
- [Docker](https://docs.docker.com/engine/install/)
- [Helm](https://helm.sh/docs/intro/install/)

### Setup

1 - Create the AWS folder exists

```
$ mkdir ~/.aws
```

2 - Configure the **~/.aws/config** file

2.1 - Create the file

```
$ touch ~/.aws/config
```

#### For SSO
2.2 - Create the **~/.aws/config** content 

```
##### SSO Credentials Configuration #####
#### General Session ####
[sso-session piperoad]
sso_start_url = https://d-0000000000.awsapps.com/start
sso_region = us-east-1
sso_registration_scopes = 111111111111
#### General Session ####

############################################################

### Account ###
## Profiles ##
[profile account-role]
sso_session = account-role
sso_account_id = 111111111111
sso_role_name = role
region = us-east-1
output = json
## Profiles ##

## Sessions ##
[sso-session account-role]
sso_start_url = https://d-0000000000.awsapps.com/start
sso_region = us-east-1
sso_registration_scopes = 111111111111
## Sessions ##
### Account ###
```

#### For IAM
2.2 - Create the **~/.aws/config** content

```
##### Assume Role Credentials Configuration #####
[default]
region = us-east-2
output = json

[profile dev]
role_arn = arn:aws:iam::111111111111:role/Administrator
source_profile = default
region = us-east-2

[profile stg]
role_arn = arn:aws:iam::222222222222:role/Administrator
source_profile = default
region = us-east-2

[profile prod]
role_arn = arn:aws:iam::333333333333:role/Administrator
source_profile = default
region = us-east-2
##### Assume Role Credentials Configuration #####
```

2.3 - Create the **~/.aws/credentials** content

```
[default]
aws_access_key_id = DUMMY000DUMMY111DUMM
aws_secret_access_key = dumMmY000dumMmY111dumMmY222dumMmY333dumM
```

## Install

1 - For SSO

```
mkdir $HOME/sso && \
curl --output $HOME/sso/aws-sso.sh "https://raw.githubusercontent.com/marquesmateus93/aws-auth/refs/heads/master/sso/aws-sso.sh" && \
curl --output $HOME/sso/auth.config "https://raw.githubusercontent.com/marquesmateus93/aws-auth/refs/heads/master/sso/auth.config" && \
chmod -R +x $HOME/sso && \
echo 'export PATH="$HOME/sso/:$PATH"' >> $HOME/.bash_profile && \
echo 'alias sso-aws="source $HOME/sso/sso-aws"' >> $HOME/.bash_profile
```

2 - For IAM

```
mkdir $HOME/iam && \
curl --output $HOME/iam/aws-iam.sh "https://raw.githubusercontent.com/marquesmateus93/aws-auth/refs/heads/master/iam/aws-iam.sh" && \
curl --output $HOME/iam/auth.config "https://raw.githubusercontent.com/marquesmateus93/aws-auth/refs/heads/master/iam/auth.config" && \
chmod -R +x $HOME/iam && \
echo 'export PATH="$HOME/iam/:$PATH"' >> $HOME/.bash_profile && \
echo 'alias iam-aws="source $HOME/iam/iam-aws"' >> $HOME/.bash_profile
```