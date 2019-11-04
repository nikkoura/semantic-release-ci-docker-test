#!/usr/bin/env bash

# Memorize current dir, and change dir to the current script's
CALLPATH=`pwd`
cd "${BASH_SOURCE%/*}/"

# Run semantic release, which require .releaserc in the current dir
npx semantic-release

# Restore initial dir
cd "${CALLPATH}"
