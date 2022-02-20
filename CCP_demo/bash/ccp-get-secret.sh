#!/bin/bash

export CCP_HOST=172.16.93.131
export APP_ID=ANSIBLE
export SAFE=CICD_Secrets
export OBJECT=AWSAccessKeys

curl -sk "https://$CCP_HOST/AIMWebService/api/Accounts?AppID=$APP_ID&Query=Safe=$SAFE;Object=$OBJECT" | jq .
