#!/bin/bash
set -eou pipefail

source ../../config/conjur.config
source ../../bin/conjur_utils.sh
source ../jenkins-demo.config

# This script enables authn-jwt in a running Conjur node (Master or Follower) running in Docker.
# It's useful for enabling authn-jwt after standing the node up.
# It must be run on the host where the Conjur node is running.

#################
main() {
  configure_authn_jwt
  wait_till_node_is_responsive
  curl -k $CONJUR_LEADER_URL/info
  set_authn_jwt_variables
}

###################################
configure_authn_jwt() {
  echo "Initializing Conjur JWT authentication policy..."

  cat ./templates/$JWT_POLICY_TEMPLATE			\
  | sed -e "s#{{ SERVICE_ID }}#$SERVICE_ID#g"		\
  > ./policy/$PROJECT_NAME-authn-jwt.yml
  conjur_append_policy root ./policy/$PROJECT_NAME-authn-jwt.yml delete

  $DOCKER exec $CONJUR_LEADER_CONTAINER_NAME				\
        evoke variable set CONJUR_AUTHENTICATORS authn-jwt/$SERVICE_ID

}

############################
wait_till_node_is_responsive() {
  set +e
  node_is_healthy=""
  while [[ "$node_is_healthy" == "" ]]; do
    sleep 2
    node_is_healthy=$(curl -sk $CONJUR_LEADER_URL/health | grep "ok" | tail -1 | grep "true")
  done
  set -e
}

############################
set_authn_jwt_variables() {
  conjur_set_variable conjur/authn-jwt/$SERVICE_ID/issuer $JWT_ISSUER
  conjur_set_variable conjur/authn-jwt/$SERVICE_ID/jwks-uri  $JWKS_URI
  conjur_set_variable conjur/authn-jwt/$SERVICE_ID/enforced-claims $ENFORCED_CLAIMS
  conjur_set_variable conjur/authn-jwt/$SERVICE_ID/token-app-property $TOKEN_APP_PROPERTY
  conjur_set_variable conjur/authn-jwt/$SERVICE_ID/identity-path $IDENTITY_PATH
}

main "$@"
