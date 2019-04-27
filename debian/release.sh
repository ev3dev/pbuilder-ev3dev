#!/bin/bash

set -e

source=$(dpkg-parsechangelog -S Source)
version=$(dpkg-parsechangelog -S Version)

debuild -S
debuild -- clean

dput ppa:ev3dev/tools ../${source}_${version}_source.changes

gbp buildpackage --git-tag-only
