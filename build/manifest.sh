#!/usr/bin/env bash
set -eo nounset

function buildAndPushManifestList() {
  TARGET_MANIFEST=$1
  echo Creating manifest list: ${TARGET_MANIFEST}

  #Incrementally build a space-separated list of all tags with architecture suffix
  ARCH_MANIFESTS=""
  for CURRENT_ARCH in ${ALL_TARGET_ARCHS}; do
    ARCH_MANIFESTS="${ARCH_MANIFESTS} ${TARGET_MANIFEST}-${CURRENT_ARCH}"
  done

  #For each architecture-suffixed tag, pull the image
  for CURRENT_ARCH in ${ALL_TARGET_ARCHS}; do
    docker pull ${TARGET_MANIFEST}-${CURRENT_ARCH}
  done

  #Create a manifest list, grouping all architecture-suffixed tags under a single name (without architecture suffix)
  #The amend flag allows to overwrite an existing manifest.
  docker manifest create --amend  ${TARGET_MANIFEST} ${ARCH_MANIFESTS}

  #For each architecture-suffixed tag, modify the manifest to mention the architecture
  for CURRENT_ARCH in ${ALL_TARGET_ARCHS}; do
    docker manifest annotate ${TARGET_MANIFEST} ${TARGET_MANIFEST}-${CURRENT_ARCH} --arch ${CURRENT_ARCH}
  done

  #Push manifest to registry
  echo Pushing manifest list to registry: ${TARGET_MANIFEST}
  docker manifest push ${TARGET_MANIFEST}
}

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
: ${IMAGE_VERSION:="devel"}
: ${ALL_TARGET_ARCHS:="amd64 arm64"}

#Enable docker experimental features
mkdir -p $HOME/.docker
echo '{"experimental": "enabled"}'>$HOME/.docker/config.json

#Login to docker hub
echo ${DOCKER_PASSWORD} | docker login --username ${DOCKER_USERNAME} --password-stdin

if [ ${IMAGE_VERSION} != "devel" -a ${IMAGE_VERSION} != "latest" ] ; then
  #Semver version
  SEMVER_MAJOR=0
  SEMVER_MINOR=0
  SEMVER_PATCH=0
  SEMVER_PRERELEASE=""
  semverParser ${IMAGE_VERSION} SEMVER_MAJOR SEMVER_MINOR SEMVER_PATCH SEMVER_PRERELEASE

  if [ -z ${SEMVER_PRERELEASE} ] ; then
    #Normal release: handle all combinations

    # For each target version number...
    ALL_TARGET_MANIFESTS="${IMAGE_BASE_NAME}:${SEMVER_MAJOR}.${SEMVER_MINOR}.${SEMVER_PATCH} \
                           ${IMAGE_BASE_NAME}:${SEMVER_MAJOR}.${SEMVER_MINOR} \
                           ${IMAGE_BASE_NAME}:${SEMVER_MAJOR} \
	                   ${IMAGE_BASE_NAME}:latest"
    for TARGET_MANIFEST in ${ALL_TARGET_MANIFESTS}; do
      #...build a manifest list and push it to registry
      buildAndPushManifestList ${TARGET_MANIFEST}
    done

  else
    #Pre-release version: push full version number but not shortened nor latest ones
    TARGET_MANIFEST=${IMAGE_BASE_NAME}:${SEMVER_MAJOR}.${SEMVER_MINOR}.${SEMVER_PATCH}${SEMVER_PRERELEASE}
    buildAndPushManifestList ${TARGET_MANIFEST}

  fi
else
  #latest / devel version
  TARGET_MANIFEST=${IMAGE_BASE_NAME}:${IMAGE_VERSION}
  docker manifest push ${TARGET_MANIFEST}

fi
