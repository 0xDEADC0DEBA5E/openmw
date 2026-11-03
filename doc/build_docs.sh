#!/bin/bash

pushd $( dirname -- "$0"; )
docker run --user "$(id -u)":"$(id -g)" --volume "$PWD/..":/openmw openmw_doc \
    sphinx-build /openmw/doc/source /openmw/doc/build
popd
