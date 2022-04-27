#!/usr/bin/env bash

#IMAGE_NAME='travisci/ubuntu-2004:packer-minimal-1642788366-31a09d16'
IMG='travisci/ci-sardonyx:packer-1641367644-6e87acce'
TRAVIS_SSH_KEY="$HOME/.ssh/id_travis_test"
SSH_OPT=false

SCRIPTDIR="$(dirname $([ -L $0 ] && readlink -f $0 || echo $0))"
TRAVIS_HOME='/home/travis'
while getopts "p:i:s:" OPTION; do
  case $OPTION in
  p) PROJECT_PATH=$OPTARG ;;
  i) IMG=$OPTARG ;;
  s) SSH_OPT=true && TRAVIS_SSH_KEY=$OPTARG ;;
  *) echo "Incorrect options provided" && exit 1 ;;
  esac
done
[ -z "$PROJECT_PATH" ] && { echo '-p [project_path] option is required' && exit 1; }
[ -d "$PROJECT_PATH" ] || { echo "-p [project_path] ${PROJECT_PATH} does not exist" && exit 1; }
[ -f "$PROJECT_PATH/.travis.yml" ] || { echo "-p [project_path] ${PROJECT_PATH} does not contain '.travis.yml" && exit 1; }
[[ "$SSH_OPT" = false || -f "$TRAVIS_SSH_KEY" ]] || { echo "-s [ssk_key] '${TRAVIS_SSH_KEY}' does not exist." && exit 1; }

PROJECT_NAME=$(basename $PROJECT_PATH)
TRAVIS_TEST_DIR=$TRAVIS_HOME/builds/$PROJECT_NAME

IMG_NAME=$(echo ${IMG} | awk 'BEGIN{FS="[:,/]"}{print $2}')
CONTAINER_NAME="travis-test-${IMG_NAME}"
echo 'docker container name: ' $CONTAINER_NAME
echo 'docker image: '$IMG
echo 'docker image name: '$IMG_NAME

function setup() {
  echo 'setting up container..'
  docker run --privileged --name $CONTAINER_NAME -dit $IMG /sbin/init
  docker cp $TRAVIS_SSH_KEY $CONTAINER_NAME:$TRAVIS_HOME/.ssh/id_rsa
  docker cp $SCRIPTDIR/container_scripts $CONTAINER_NAME:$TRAVIS_HOME/scripts
  [ -f "$TRAVIS_SSH_KEY" ] && docker exec -u travis $CONTAINER_NAME bash -cl "sudo chown -R travis:travis $TRAVIS_HOME/.ssh"
  docker exec -u travis $CONTAINER_NAME bash -cl "sudo chown -R travis:travis $TRAVIS_HOME/scripts"
  docker exec -u travis -w $TRAVIS_HOME $CONTAINER_NAME bash -cl scripts/setup.sh
}

# start container if it exists else create and setup
docker start $CONTAINER_NAME 2>/dev/null || setup
# remove existing test dir from the container and copy the dir from host to container
docker exec -u travis $CONTAINER_NAME bash -cl "rm -r $TRAVIS_TEST_DIR 2>/dev/null"
docker cp $PROJECT_PATH $CONTAINER_NAME:$TRAVIS_HOME/builds || exit 1
docker exec -u travis $CONTAINER_NAME bash -cl "sudo chown -R travis:travis $TRAVIS_TEST_DIR"
# compile and edit ci.sh
docker exec -u travis -w $TRAVIS_TEST_DIR $CONTAINER_NAME bash -cl "$TRAVIS_HOME/scripts/compile_ci.sh"
# run tests
docker exec -u travis -w $TRAVIS_TEST_DIR $CONTAINER_NAME bash -cl "sudo chmod +x ci.sh"
docker exec -u travis -w $TRAVIS_TEST_DIR $CONTAINER_NAME bash -cl "./ci.sh"

#docker exec -it -u travis -w $TRAVIS_TEST_DIR $CONTAINER_NAME bash -l
