#!/bin/bash
ROLENAME=$2
ENVNAME=$1
REQUIREDARGS=2
NUMOFARGS=$#

# Get AWS creds injected
. /home/centos/.aws-config
# Bring in functions from jenkinslib scripts
. /home/centos/socorro-infra/bin/jenkinslib/identify_role.sh

####################################
## PROGRAM FUNCTIONS
# Make the log more readable
function log_format() {
    echo " ";echo "========================================="
    echo "=========================================";echo " ";echo " "
}
# Show usage instructions for noobs
function show_usage() {
    echo " =================== ";echo " ";
    echo " Syntax "
    echo " ./terraform-apply.sh env(stage or prod) rolename"
    echo " "
    echo " Example: ./terraform-apply.sh stage collector"
}

# Check if you are asking for halp or passing the wrong number of args
function check_syntax() {
    if [ "$1" = "-h" ] || [ "$1" = "--help" ];then
        show_usage
    fi
    if [ ${NUMOFARGS} -ne ${REQUIREDARGS} ];then
        echo "`date` -- ERROR, ${REQUIREDARGS} arguments required and ${NUMOFARGS} is an invalid number of args"
        exit 1
    fi
}

# Set variable so we can lookup the role and app and know what to point at
ROLEENVNAME="${ROLENAME}-${ENVNAME}"
# Get the relevant info about the infra we're applying to
identify_role ${ROLEENVNAME}
CURRENTCAPACITY=`aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names ${AUTOSCALENAME}| grep -A3 ${AUTOSCALENAME} | grep -C 3 ARN|grep DesiredCapacity | sed 's/,//g'|awk '{print $2}'`
CURRENTLAUNCHCONFIG=`aws autoscaling describe-auto-scaling-groups --auto-scaling-group as-stage-socorroweb|grep LaunchConfigurationName|sed 's/"/ /g' | head -n1 | awk '{print $3}'`
CURRENTAMI=`aws autoscaling describe-launch-configurations --launch-configuration terraform-VIEyKUpAFs2ylVbOBofHU1pZvkk=|grep ImageId|sed 's/"/ /g'|awk '{print $3}'`

####################################
## PROGRAM RUN
cd /home/centos/socorro-infra/terraform
log_format
echo "`date` -- Terraform Plan for ${ROLENAME} ${ENVNAME}"
# First, run a plan to verify this isn't hosed
/home/centos/socorro-infra/terraform/wrapper.sh "plan -var base_ami.us-west-2=${CURRENTAMI}" ${ENVNAME} ${ROLENAME} 2>&1 | grep -v s3
    RETURNCODE=$?;if [ ${RETURNCODE} -ne 0 ];then
      echo "`date` -- Plan failed, not continuing!";exit 1
    fi
log_format
echo "`date` -- Terraform Apply for ${ROLENAME} ${ENVNAME}"
/home/centos/socorro-infra/terraform/wrapper.sh "apply -var base_ami.us-west-2=${CURRENTAMI}" ${ENVNAME} ${ROLENAME} 2>&1 | grep -v s3
  RETURNCODE=$?
echo "`date` -- Terraform Apply for ${ROLENAME} ${ENVNAME} exited with return code ${RETURNCODE}"


