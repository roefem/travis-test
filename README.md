This script automates the setup of
a [travis-ci worker](https://github.com/travis-ci/worker/tree/858cb91994a513269f2fe9782c15fc113e966231)
docker container, configured to run travis builds locally.

### Setup

* create ssh key
  pair: `ssh-keygen -f id_travis_test -t ed25519 -C "your_email@example.com"`
* add public key to [github ssh keys](https://github.com/settings/keys)
* checkout the project and add the script to PATH or create an alias:
    ```shell
    git clone git@github.com:roefem/travis-test.git
    cd travis-test
    # add to PATH
    ln -s $PWD/travis-test.sh $HOME/.local/bin/travis-test
    # create alias
    cat << EOF >> ~/.bash_aliases
    alias travis-test='$PWD/travis-test.sh'
    EOF
    ```

### Usage

find the name of a travis worker instance name in the Job log of a previous travis build
at [https://app.travis-ci.com/](https://app.travis-ci.com/): \
The name you need is preceded by `travis-` and starts with `ci-`. The image name in the
example below is `ci-sardonyx`.

  ```properties
Worker information
    hostname:b0284835-9e0a-4f83-b729-11b81e3d6dcf@1.worker-com-77564c74fb-htkvz.gce-production-2
    version:6.2.22 https://github.com/travis-ci/worker/tree/858cb91994a513269f2fe9782c15fc113e966231
    instance:travis-job-f77e7b68-8bc1-4a67-b683-8c73fdf2e143 travis-ci-sardonyx-xenial-1643096237-31a09d16 (via amqp)
    startup:6.42850099s
  ```

Find the latest available image for the worker instance name at [https://hub.docker.com/u/travisci/](https://hub.docker.com/u/travisci/)

run tests: `travis-test -p /path/to/project -i 'travisci/ci-sardonyx:packer-1641367644-6e87acce'`

#### options:

* **-p**: the path to a project, will be copied to the travis docker container. [required]
* **-s**: the path to an ssh private key, will be copied to the travis docker container if
  it exists. [default: `$HOME/.ssh/id_travis_test`]
* **-i**: the travisci docker image
  name. [default: `travisci/ci-sardonyx:packer-1641367644-6e87acce`]

### Limitations

addon packages defined in .travis.yml are not installed automatically for now, if testst
fail because of missing addon packages, eg `postgresql-9.6-postgis-2.4`, these need to be
installed manually:

* login to container: `docker exec -u travis -it <travis-test-container> bash -l`
* install package: `sudo apt install postgresql-9.6-postgis-2.4`
* exit container and rerun the `travis-test` command