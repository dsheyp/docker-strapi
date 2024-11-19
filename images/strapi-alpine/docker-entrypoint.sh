#!/bin/sh
set -ea


echo "file start"


if [ "$*" = "strapi" ]; then


  echo "first block"


  if [ ! -f "package.json" ]; then


    echo "second block"

    DATABASE_CLIENT=${DATABASE_CLIENT:-sqlite}

    EXTRA_ARGS=${EXTRA_ARGS}

    echo "Using strapi v$STRAPI_VERSION"
    echo "No project found at /srv/app. Creating a new strapi project ..."


      DOCKER=true npx create-strapi-app@${STRAPI_VERSION} . --no-run \
        --dbclient=$DATABASE_CLIENT \
        --dbhost=$DATABASE_HOST \
        --dbport=$DATABASE_PORT \
        --dbname=$DATABASE_NAME \
        --dbusername=$DATABASE_USERNAME \
        --dbpassword=$DATABASE_PASSWORD \
        --dbssl=$DATABASE_SSL \
        $EXTRA_ARGS
    
    echo "" >| 'config/server.js'
    echo "" >| 'config/admin.js'
    echo "" >| 'config/middlewares.js'

    cat <<-EOT >> 'config/server.js'
module.exports = ({ env }) => ({
  host: env('HOST', '0.0.0.0'),
  port: env.int('PORT', 1337),
  url: env('PUBLIC_URL', 'http://localhost:1337'),
  app: {
    keys: env.array('APP_KEYS'),
  },
  webhooks: {
    populateRelations: env.bool('WEBHOOKS_POPULATE_RELATIONS', false),
  },
});
EOT

    cat <<-EOT >> 'config/admin.js'
module.exports = ({ env }) => ({
  url: env('ADMIN_URL', 'http://localhost:1337/admin'),
  auth: {
    secret: env('ADMIN_JWT_SECRET'),
  },
  apiToken: {
    salt: env('API_TOKEN_SALT'),
  },
  transfer: {
    token: {
      salt: env('TRANSFER_TOKEN_SALT'),
    },
  },
});
EOT

    cat <<-EOT >> 'config/middlewares.js'
module.exports = ({env}) => ([
  'strapi::logger',
  'strapi::errors',
  {
    name: 'strapi::security',
    config: {
      contentSecurityPolicy: {
        useDefaults: true,
        directives: {
          'connect-src': ["'self'", 'http:', 'https:'],
          'img-src': env('IMG_ORIGIN', "'self',data:,blob:,market-assets.strapi.io").split(','),
          upgradeInsecureRequests: null,
        },
      },
    },
  },
  {
    name: 'strapi::cors',
    config: {
      origin: env('CORS_ORIGIN', '*').split(','),
      methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'HEAD', 'OPTIONS'],
      headers: ['Content-Type', 'Authorization', 'Origin', 'Accept'],
      keepHeaderOnError: true,
    }
  },
  'strapi::poweredBy',
  'strapi::query',
  'strapi::body',
  'strapi::session',
  'strapi::favicon',
  'strapi::public',
]);
EOT

  elif [ ! -d "node_modules" ] || [ ! "$(ls -qAL node_modules 2>/dev/null)" ]; then
    echo "Node modules not installed. Installing ..."
    if [ -f "yarn.lock" ]; then
      yarn install --prod
    else
      #npm install --only=prod
      npm install
    fi
  fi

  if ! grep -q "\"react\"" package.json; then
    echo "Adding React and Styled Components..."
    if [ -f "yarn.lock" ]; then
      yarn add "react@^18.0.0" "react-dom@^18.0.0" "react-router-dom@^5.3.4" "styled-components@^5.3.3" --prod || { echo "Adding React and Styled Components failed"; exit 1; }
    else
      npm install react@"^18.0.0" react-dom@"^18.0.0" react-router-dom@"^5.3.4" styled-components@"^5.3.3" --only=prod || { echo "Adding React and Styled Components failed"; exit 1; }
    fi
  fi

  #BUILD=${BUILD:-false}"

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
