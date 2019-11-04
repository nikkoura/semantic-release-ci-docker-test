#!/usr/bin/env bash
set -eo nounset

#Required env variables
if [ -z ${IMAGE_BASE_NAME:=""} ] ; then
  >&2 echo "IMAGE_BASE_NAME must be set"
  exit 1
fi

#Default values, if not already set externally
: ${TARGET_ARCH:=$(docker version -f '{{.Server.Arch}}')}
: ${DOCKER_BUILD_FOLDER:="."}
: ${DOCKERFILE_FOLDER:="."}
if [ -z ${DOCKERFILE:=""} ] ; then
  #DOCKERFILE is not set: checking existence of TARGET_ARCH specific Dockerfile
  if [ -f ${DOCKERFILE_FOLDER}/Dockerfile.${TARGET_ARCH} ] ; then
    #Use TARGET_ARCH specific Dockerfile
    DOCKERFILE=Dockerfile.${TARGET_ARCH}
  else
    #Use default Dockerfile
    DOCKERFILE=Dockerfile
  fi
fi
: ${IMAGE_VERSION:="devel"}
: ${BUILD_OPTIONS:=""}

echo "Building image ${IMAGE_BASE_NAME}:${IMAGE_VERSION}-${TARGET_ARCH}" 
docker build --tag ${IMAGE_BASE_NAME}:${IMAGE_VERSION}-${TARGET_ARCH} \
             ${BUILD_OPTIONS} \
             --file ${DOCKERFILE_FOLDER}/${DOCKERFILE} \
             ${DOCKER_BUILD_FOLDER}

echo "Writing image to archive for cross-stage reuse: image-${TARGET_ARCH}.tar"
docker image save ${IMAGE_BASE_NAME}:${IMAGE_VERSION}-${TARGET_ARCH} \
                  -o image-${TARGET_ARCH}.tar
