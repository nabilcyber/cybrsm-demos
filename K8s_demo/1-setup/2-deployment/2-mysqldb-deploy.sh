#!/bin/bash

source ../../../config/conjur.config

main() {
  if [[ "$PLATFORM" == "openshift" ]]; then
    $CLI login -u $CLUSTER_ADMIN
  fi
  clean_mysql
  if [[ "$1" == "clean" ]]; then
    exit 0
  fi
  deploy_mysql_db 
  echo "Waiting for MySQL DB to become available..."
  sleep 30
  init_mysql
}

########################
clean_mysql() {
  $CLI delete -f ./manifests/mysql-manifest.yaml -n $CYBERARK_NAMESPACE_NAME --ignore-not-found
  rm -f ./manifests/mysql-manifest.yaml
}

########################
deploy_mysql_db() {
  if [[ "$PLATFORM" == "openshift" ]]; then
    $CLI adm policy add-scc-to-user anyuid -z mysql-db -n $CYBERARK_NAMESPACE_NAME
  fi
  cat ./templates/mysql-manifest.template.yaml				\
  | sed "s#{{ MYSQL_IMAGE_NAME }}#$MYSQL_IMAGE#g"			\
    | sed "s#{{ CYBERARK_NAMESPACE_NAME }}#$CYBERARK_NAMESPACE_NAME#g"  \
    | sed "s#{{ MYSQL_ROOT_PASSWORD }}#$MYSQL_ROOT_PASSWORD#g"		\
    | sed "s#{{ MYSQL_USERNAME }}#$MYSQL_USERNAME#g"			\
    | sed "s#{{ MYSQL_PASSWORD }}#$MYSQL_PASSWORD#g"			\
    | sed "s#{{ MYSQL_DBNAME }}#$MSQL_DB_NAME#g"			\
    > ./manifests/mysql-manifest.yaml
  $CLI apply -f ./manifests/mysql-manifest.yaml -n $CYBERARK_NAMESPACE_NAME
}

################################
init_mysql() {
  echo "Initializing MySQL database..."
  # create db
  cat db_create_petclinic.sql          				\
  | $CLI -n $CYBERARK_NAMESPACE_NAME exec -i pod/mysql-db-0 --	\
        mysql -h $DB_URL -u root --password=$MYSQL_ROOT_PASSWORD
  # load data
  cat db_load_petclinic.sql            				\
  | $CLI -n $CYBERARK_NAMESPACE_NAME exec -i pod/mysql-db-0 --	\
        mysql -h $DB_URL -u root --password=$MYSQL_ROOT_PASSWORD
  # grant user access
  quoted_pwd=\'$MYSQL_PASSWORD\'
  echo "DROP USER $MYSQL_USERNAME; CREATE USER $MYSQL_USERNAME IDENTIFIED BY $quoted_pwd REQUIRE NONE; GRANT ALL PRIVILEGES ON $MYSQL_DBNAME.* TO $MYSQL_USERNAME;"		\
  | $CLI -n $CYBERARK_NAMESPACE_NAME exec -i pod/mysql-db-0 --	\
        mysql -h $DB_URL -u root --password=$MYSQL_ROOT_PASSWORD
}

main "$@"
