#set -x
ENVIRONMENT=$1

#### Change these values
OS_URL='https://do-prd-okp-m0.do.viaa.be:8443'
OS_PROJECT_NAME='shared-components'
APP_NAME='hello-viaa'
GITLAB_SPACE='viaa-code/hello-viaa'
# Stable git tag for prd ImageStream
STABLE_TAG='v0.1'
APP_PORT=4567
####

create_template()
{
  TEMPLATE=$1
  shift
  EXTRA_PARAMS=$@
  printf '%s\n' "Creating $TEMPLATE for app $APP_NAME in $ENVIRONMENT env, with params $EXTRA_PARAMS"
  oc process -f $TEMPLATE $EXTRA_PARAMS -p APP_NAME=$APP_NAME -p OS_ENV=$ENVIRONMENT | oc create -f -
}

init_config_maps(){
  create_template init_config_maps.yml --param-file=params/${ENVIRONMENT}.config
}

init_secrets(){
  create_template init_secrets.yml --param-file=params/${ENVIRONMENT}.secrets
}

init_image_streams(){
  create_template init_image_streams.yml -p GITLAB_SPACE=$GITLAB_SPACE -p STABLE_TAG=$STABLE_TAG
}

init_deployment_config(){
  create_template init_deployment_config.yml -p APP_PORT=$APP_PORT -p OS_NAMESPACE=$OS_PROJECT_NAME
}

init_service(){
  create_template init_service.yml -p APP_PORT=$APP_PORT
}

if [ "$ENVIRONMENT" = "" ]; then
  printf '%s\n' "No environment given, e.g. sh init.sh qas" >&2
  exit 1
fi

oc login $OS_URL
oc project $OS_PROJECT_NAME

init_config_maps
init_secrets
init_image_streams
init_deployment_config
init_service

