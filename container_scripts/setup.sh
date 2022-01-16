#!/bin/bash

cat << 'EOF' >> ~/.bashrc
alias ls='ls --color=auto'
alias ll='ls -laF'

export TRAVIS_HOME=/home/travis
EOF

# docker + systemd is a PITA
sudo mv /bin/systemctl /bin/systemctl.bak

git clone https://github.com/travis-ci/travis-build.git
cd travis-build || exit
mkdir -p ~/.travis
ln -s $PWD ~/.travis/travis-build
gem install bundler
bundle update --bundler
bundle install --gemfile ~/.travis/travis-build/Gemfile
bundler binstubs travis
