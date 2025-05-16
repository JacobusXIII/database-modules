#!/bin/bash
set -Eeuo pipefail

# Change current directory to directory of script so it can be called from everywhere
SCRIPT_PATH=$(readlink -f "${0}")
SCRIPT_DIR=$(dirname "${SCRIPT_PATH}")
cd "${SCRIPT_DIR}"

# Database-Build versions
IMAGE_VERSIONS=(
  "1.4.0-psql_15-pgis_3.4"
  "1.4.0-psql_17-pgis_3.5"
)

# Read in current version of the script
BUILD_VERSION=$(<VERSION)

for DATABASE_BUILD_VERSION in "${IMAGE_VERSIONS[@]}"; do
  echo "# Processing - Database-build: ${DATABASE_BUILD_VERSION}"
  IMAGE_TAG="${BUILD_VERSION}-database-build_${DATABASE_BUILD_VERSION}"

  # Create directory if it doesn't exist yet
  if [[ ! -d "${IMAGE_TAG}" ]]; then
    mkdir -p "docker/${IMAGE_TAG}"
  fi

  # Copy over files and process templates
  sed -e 's/%%DATABASE_BUILD_VERSION%%/'"${DATABASE_BUILD_VERSION}"'/g;' \
      docker/Dockerfile.template > "docker/${IMAGE_TAG}/Dockerfile"
done
