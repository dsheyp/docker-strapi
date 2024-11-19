#!/bin/sh
set -ea


echo "file start"


if [ "$*" = "strapi" ]; then


  echo "first block"


  #if [ ! -f "package.json" ]; then
  if [ 1 -gt 0 ]; then

    echo "second block"

    DATABASE_CLIENT=${DATABASE_CLIENT:-sqlite}

    EXTRA_ARGS=${EXTRA_ARGS}

    echo "Using strapi v$STRAPI_VERSION"
    echo "No project found at /srv/app. Creating a new strapi project ..."

      DOCKER=true npx create-strapi-app@${STRAPI_VERSION} . --no-run \
        --js \
        --install \
        --no-git-init \
        --no-example \
        --skip-cloud \
        --skip-db \
        $EXTRA_ARGS
  fi

  BUILD="true"

  if [ "$BUILD" = "true" ]; then
    echo "Building Strapi admin..."
    if [ -f "yarn.lock" ]; then
      yarn build
    else
      npm run build
    fi
  fi

  if [ "$NODE_ENV" = "production" ]; then
    STRAPI_MODE="start"
  elif [ "$NODE_ENV" = "development" ]; then
    STRAPI_MODE="develop"
  fi

  echo "Starting your app (with ${STRAPI_MODE:-develop})..."

  if [ -f "yarn.lock" ]; then
    exec yarn "${STRAPI_MODE:-develop}"
  else
    echo "ls"
    exec more yarn-error.log
    echo "done debug"
    #exec npm run "${STRAPI_MODE:-develop}"
  fi

else
  exec "$@"
fi
