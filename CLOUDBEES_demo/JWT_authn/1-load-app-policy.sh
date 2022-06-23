#!/bin/bash
set -eou pipefail

source ../cloudbees-demo.config
source ../../bin/conjur_utils.sh

main() {
#  conjur_update_policy root ./delete.yml

  source ./mb-branch2-pipeline.config
  export POLICY_NAME=mb-branch2-pipeline
  gen_and_load_policy
exit 

  source ./proj1-freestyle.config
  export POLICY_NAME=proj1-freestyle
  gen_and_load_policy

  source ./proj1-pipeline.config
  export POLICY_NAME=proj1-pipeline
  gen_and_load_policy

  source ./root-pipeline.config
  export POLICY_NAME=root-pipeline
  gen_and_load_policy

  source ./root-freestyle.config
  export POLICY_NAME=root-freestyle
  gen_and_load_policy
}

##############################
gen_and_load_policy() {

  cat ./templates/$JWT_APP_POLICY_TEMPLATE			\
    | sed -e "s#{{ SERVICE_ID }}#$SERVICE_ID#g"			\
    | sed -e "s#{{ PROJECT_NAME }}#$PROJECT_NAME#g"		\
    | sed -e "s#{{ APP_IDENTITY }}#$APP_IDENTITY#g"		\
    | sed -e "s#{{ JWT_CLAIM1_NAME }}#$JWT_CLAIM1_NAME#g"	\
    | sed -e "s#{{ JWT_CLAIM1_VALUE }}#$JWT_CLAIM1_VALUE#g"	\
    | sed -e "s#{{ JWT_CLAIM2_NAME }}#$JWT_CLAIM2_NAME#g"	\
    | sed -e "s#{{ JWT_CLAIM2_VALUE }}#$JWT_CLAIM2_VALUE#g"	\
    | sed -e "s#{{ JWT_CLAIM3_NAME }}#$JWT_CLAIM3_NAME#g"	\
    | sed -e "s#{{ JWT_CLAIM3_VALUE }}#$JWT_CLAIM3_VALUE#g"	\
    > ./policy/$POLICY_NAME.yml

  conjur_update_policy root ./policy/$POLICY_NAME.yml
}

main "$@"
