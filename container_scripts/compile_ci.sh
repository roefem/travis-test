#!/bin/bash

~/.travis/travis-build/bin/travis compile > ci.sh
REPO_SLUG=$(git config --get remote.origin.url | awk 'BEGIN{FS="[:,.]"}{print $3}')

# prevent git checkout, copy local dir instead
cat << EOF > replace_checkout.tmp
echo 'copy project to build dir'
mkdir -p \$TRAVIS_HOME/build/$REPO_SLUG
rm -rf \$TRAVIS_HOME/build/$REPO_SLUG
cp -r $PWD/. \$TRAVIS_HOME/build/$REPO_SLUG
cd \$TRAVIS_HOME/build/$REPO_SLUG
return 0
EOF
sed -ie '/function travis_run_checkout() {/r./replace_checkout.tmp' ci.sh

# skip caching
sed -ie '/function travis_run.*cache() {/aecho "skip cache"\nreturn 0' ci.sh
sed -ie '/function travis_run.*casher() {/aecho "skip casher"\nreturn 0' ci.sh

# skip network check
sed -ie 's/travis_cmd travis_wait_for_network/#travis_cmd travis_wait_for_network/' ci.sh
sed -ie 's/travis_time_finish wait_for_network/#travis_time_finish wait_for_network/' ci.sh
