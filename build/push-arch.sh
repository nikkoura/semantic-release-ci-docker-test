#!/usr/bin/env bash
set -eo nounset

# Memorize current dir, and change dir to the current script's
CALLPATH=`pwd`
cd "${BASH_SOURCE%/*}/"

source semver_parser.sh

#Required env variables
if [ -z ${IMAGE_BASE_NAME:=""} ] ; then
  >&2 echo "IMAGE_BASE_NAME must be set"
  exit 1
fi
if [ -z ${DOCKER_USERNAME:=""} ] ; then
  >&2 echo "DOCKER_USERNAME must be set"
  exit 1
fi
if [ -z ${DOCKER_PASSWORD:=""} ] ; then
  >&2 echo "DOCKER_PASSWORD must be set"
  exit 1
fi

#Default values, if not already set externally
: ${TARGET_ARCH:=$(docker version -f '{{.Server.Arch}}')}
: ${IMAGE_VERSION:="devel"}

#Login to docker hub
echo ${DOCKER_PASSWORD} | docker login --username ${DOCKER_USERNAME} --password-stdin


if [ ${IMAGE_VERSION} != "devel" -a ${IMAGE_VERSION} != "latest" ] ; then
  #Semver version
  SEMVER_MAJOR=0
  SEMVER_MINOR=0
  SEMVER_PATCH=0
  SEMVER_PRERELEASE=""
  semverParser ${IMAGE_VERSION} \
               SEMVER_MAJOR SEMVER_MINOR SEMVER_PATCH SEMVER_PRERELEASE

  if [ -z ${SEMVER_PRERELEASE} ] ; then
    #Normal release: push all combinations
    docker tag \
      ${IMAGE_BASE_NAME}:${IMAGE_VERSION}-${TARGET_ARCH} \
      ${IMAGE_BASE_NAME}:${SEMVER_MAJOR}.${SEMVER_MINOR}.${SEMVER_PATCH}-${TARGET_ARCH}
    docker push \
      ${IMAGE_BASE_NAME}:${SEMVER_MAJOR}.${SEMVER_MINOR}.${SEMVER_PATCH}-${TARGET_ARCH}

    docker tag \
      ${IMAGE_BASE_NAME}:${IMAGE_VERSION}-${TARGET_ARCH} \
      ${IMAGE_BASE_NAME}:${SEMVER_MAJOR}.${SEMVER_MINOR}-${TARGET_ARCH}
    docker push \
      ${IMAGE_BASE_NAME}:${SEMVER_MAJOR}.${SEMVER_MINOR}-${TARGET_ARCH}

    docker tag \
      ${IMAGE_BASE_NAME}:${IMAGE_VERSION}-${TARGET_ARCH} \
      ${IMAGE_BASE_NAME}:${SEMVER_MAJOR}-${TARGET_ARCH}
    docker push \
      ${IMAGE_BASE_NAME}:${SEMVER_MAJOR}-${TARGET_ARCH}

    docker tag \
      ${IMAGE_BASE_NAME}:${IMAGE_VERSION}-${TARGET_ARCH} \
      ${IMAGE_BASE_NAME}:latest-${TARGET_ARCH}
    docker push \
      ${IMAGE_BASE_NAME}:latest-${TARGET_ARCH}

  else
    #Pre-release version: push full version number but not shortened nor latest ones
    docker tag \
      ${IMAGE_BASE_NAME}:${IMAGE_VERSION}-${TARGET_ARCH} \
      ${IMAGE_BASE_NAME}:${SEMVER_MAJOR}.${SEMVER_MINOR}.${SEMVER_PATCH}${SEMVER_PRERELEASE}-${TARGET_ARCH}
    docker push \
      ${IMAGE_BASE_NAME}:${SEMVER_MAJOR}.${SEMVER_MINOR}.${SEMVER_PATCH}${SEMVER_PRERELEASE}-${TARGET_ARCH}
  fi
else
  #latest / devel version
  docker push ${IMAGE_BASE_NAME}:${IMAGE_VERSION}-${TARGET_ARCH}
fi

#Restore initial dir
cd "${CALLPATH}"
