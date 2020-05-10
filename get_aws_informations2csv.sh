#!/bin/sh

##############################################
# Please prepare in advance!
# 1. aws-vault install
# https://github.com/99designs/aws-vault
#
# 2. $ aws-vault add test_env
# Enter Access Key ID: AKXXXXXXXXXXXXXXXXXX
# Enter Secret Access Key: xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
# Added credentials to profile "test_env" in vault
#
# 3. $ pip install csvkit
###################################################

if [ $# -ne 2 ]; then
	echo "第1引数:aws-vaultに登録しているenv"
	echo "第2引数:region 1:日本 2:北米 3:中国 4:豪州 5 欧州"
	exit 1
fi

env=$1
reg=$2

if [ $reg -eq 1 ]; then
region="ap-northeast-1"
elif [ $reg -eq 2 ]; then
region="us-east-1"
elif [ $reg -eq 3 ]; then
region="cn-north-1"
elif [ $reg -eq 4 ]; then
region="ap-southeast-2"
elif [ $reg -eq 5 ]; then
region="eu-central-1"
fi

mkdir -p "output_csv"
cd output_csv

 # ec2
 `aws-vault exec ${env} --no-session -- aws ec2 describe-instances --region ${region} --filter Name=instance-state-name,Values=running --query Reservations[].Instances[] |\
 in2csv --format json > ec2.csv`

 # lb
 `aws-vault exec ${env} --no-session -- aws elbv2 describe-load-balancers --region ${region} --query LoadBalancers[] |\
 in2csv --format json > lb.csv`

 # subnet
 `aws-vault exec ${env} --no-session -- aws ec2 describe-subnets --region ${region} --query Subnets[] |\
 in2csv --format json > subnet.csv`

 # vpc
 `aws-vault exec ${env} --no-session -- aws ec2 describe-vpcs --region ${region} --query Vpcs[] |\
 in2csv --format json > vpc.csv`

 # securityGroup
 `aws-vault exec ${env} --no-session -- aws ec2 describe-security-groups --region ${region} --query SecurityGroups[] |\
 in2csv --format json > securityGroup.csv`

 # VpcEndpoints
 `aws-vault exec ${env} --no-session -- aws ec2 describe-vpc-endpoints --region ${region} --query VpcEndpoints[] |\
 in2csv --format json > VpcEndpoints.csv`

 # VpcPeeringConnections
 `aws-vault exec ${env} --no-session -- aws ec2 describe-vpc-peering-connections --region ${region} --query VpcPeeringConnections[] |\
 in2csv --format json > VpcPeeringConnections.csv`

 # CertificateSummaryList
 `aws-vault exec ${env} --no-session -- aws acm list-certificates --query CertificateSummaryList[] |\
 in2csv --format json > CertificateSummaryList.csv`

 # elasticbeanstalk Environments
 `aws-vault exec ${env} --no-session -- aws elasticbeanstalk describe-environments --region ${region} --query Environments[] |\
 in2csv --format json > elasticbeanstalk_Environments.csv`

 # elasticbeanstalk Applications
 `aws-vault exec ${env} --no-session -- aws elasticbeanstalk describe-applications --region ${region} --query Applications[] |\
 in2csv --format json > elasticbeanstalk_Applications.csv`

 # rds
 `aws-vault exec ${env} --no-session -- aws rds describe-db-instances --region ${region} --query DBInstances[] |\
 in2csv --format json > rds.csv`

 # TargetGroups
 `aws-vault exec ${env} --no-session -- aws elbv2 describe-target-groups --region ${region} --query TargetGroups[] |\
 in2csv --format json > TargetGroups.csv`

  # lambda
 `aws-vault exec ${env} --no-session -- aws lambda list-functions --region ${region} --query Functions[] |\
 in2csv --format json > lambda.csv`

 # s3
 `aws-vault exec ${env} --no-session -- aws s3api list-buckets --region ${region} --query Buckets[] |\
 in2csv --format json > buckets.csv`

 # Route53
 `aws-vault exec ${env} --no-session -- aws route53 list-hosted-zones --region ${region} --query HostedZones[] |\
 in2csv --format json > route53.csv`

 # AutoScalingGroups
 `aws-vault exec ${env} --no-session -- aws autoscaling describe-auto-scaling-groups --region ${region} --query AutoScalingGroups[] |\
 in2csv --format json > AutoScalingGroups.csv`

 # cloudfront
 `aws-vault exec ${env} --no-session -- aws cloudfront list-distributions --query DistributionList.Items[] |\
 in2csv --format json > cloudfront.csv`

 # Policies
 `aws-vault exec ${env} --no-session -- aws iam list-policies --scope Local --region ${region} --query Policies[] |\
 in2csv --format json > Policies.csv`

 # Roles
 `aws-vault exec ${env} --no-session -- aws iam list-roles --region ${region} --query Roles[] |\
 in2csv --format json > Roles.csv`

 # Users
 `aws-vault exec ${env} --no-session -- aws iam list-users --region ${region} --query Users[] |\
 in2csv --format json > Users.csv`

# ECS
ecs=$(aws-vault exec ${env} --no-session -- aws ecs list-clusters --query clusterArns[])
len=$(echo $ecs | jq length)
for i in $( seq 0 $(($len - 1)) ); do
  clusterArn=`echo ${ecs} | jq -r .[${i}]`
	`aws-vault exec ${env} --no-session -- aws ecs describe-clusters --cluster "${clusterArn}" --query clusters[] |\
	in2csv --format json > ECS_$i.csv`

  serviceArn=$(aws-vault exec former --no-session -- aws ecs list-services --cluster "${clusterArn}" --query serviceArns[] | jq -r .[${i}])
	`aws-vault exec ${env} --no-session -- aws ecs describe-services --cluster "${clusterArn}" --services "${serviceArn}" --query services[]|\
	in2csv --format json > ECS_SERVICE_$i.csv`
done
