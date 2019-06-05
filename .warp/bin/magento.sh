#!/bin/bash

    # IMPORT HELP

    . "$PROJECTPATH/.warp/bin/magento_help.sh"

function magento_command() 
{

    if [ "$1" = "-h" ] || [ "$1" = "--help" ]
    then
        magento_help_usage 
        exit 1
    fi;

    if [ "$1" = "--download" ]
    then
        shift 1
        magento_download $*
        exit 1
    fi;

    if [ $(warp_check_is_running) = false ]; then
        warp_message_error "The containers are not running"
        warp_message_error "please, first run warp start"

        exit 1;
    fi

    if [ "$1" = "--install" ]
    then
        magento_install
        exit 1
    fi;

    FRAMEWORK=$(warp_env_read_var FRAMEWORK)
    if [ "$FRAMEWORK" = "m1" ]
    then
        MAGENTOBIN='./n98-magerun'
    else
        MAGENTOBIN='bin/magento'
    fi

    if [ "$1" = "--root" ]
    then
        shift 1
        docker-compose -f $DOCKERCOMPOSEFILE exec -uroot php bash -c "$MAGENTOBIN $*"
    elif [ "$1" = "-T" ] ; then
        shift 1
        docker-compose -f $DOCKERCOMPOSEFILE exec -T php bash -c "$MAGENTOBIN $*"
    else

        docker-compose -f $DOCKERCOMPOSEFILE exec php bash -c "$MAGENTOBIN $*"
    fi
}

function magento_install()
{
    if ! warp_check_env_file ; then
        warp_message_error "file not found $(basename $ENVIRONMENTVARIABLESFILE)"
        exit
    fi; 

    VIRTUAL_HOST=$(warp_env_read_var VIRTUAL_HOST)
    DATABASE_NAME=$(warp_env_read_var DATABASE_NAME)
    DATABASE_USER=$(warp_env_read_var DATABASE_USER)
    DATABASE_PASSWORD=$(warp_env_read_var DATABASE_PASSWORD)
    USE_DOCKER_SYNC=$(warp_env_read_var USE_DOCKER_SYNC)
    REDIS_CACHE_VERSION=$(warp_env_read_var REDIS_CACHE_VERSION)
    REDIS_FPC_VERSION=$(warp_env_read_var REDIS_FPC_VERSION)
    REDIS_SESSION_VERSION=$(warp_env_read_var REDIS_SESSION_VERSION)

    case "$(uname -s)" in
      Darwin)
        if [ "$USE_DOCKER_SYNC" = "Y" ] || [ "$USE_DOCKER_SYNC" = "y" ] ; then 
            warp_message "Copying all files from host to container..."
            warp sync push --all
        fi
      ;;
    esac

    # Permissions
    warp fix --owner

    warp_message "Forcing reinstall of composer deps to ensure perms & reqs..."
    warp composer install

    warp magento setup:install \
        --backend-frontname=admin \
        --db-host=mysql \
        --db-name=$DATABASE_NAME \
        --db-user=$DATABASE_USER \
        --db-password=$DATABASE_PASSWORD \
        --base-url=https://$VIRTUAL_HOST/ \
        --admin-firstname=Admin \
        --admin-lastname=Admin \
        --admin-email=admin@admin.com \
        --admin-user=admin \
        --admin-password=password123 \
        --language=es_AR \
        --currency=ARS \
        --timezone=America/Argentina/Buenos_Aires \
        --use-rewrites=1

    warp_message "Turning on developer mode.."
    warp magento deploy:mode:set developer

    warp_message "Reindex all indexers"
    warp magento indexer:reindex

    warp_message "Forcing deploy of static content to speed up initial requests..."
    warp magento setup:static-content:deploy -f 

    if [ ! -z "$REDIS_CACHE_VERSION" ]
    then
        warp_message "Enabling redis for cache..."
        warp magento setup:config:set --no-interaction --cache-backend=redis --cache-backend-redis-server=redis-cache --cache-backend-redis-db=0
    fi

    if [ ! -z "$REDIS_FPC_VERSION" ]
    then
        warp_message "Enabling redis for full page cache..."
        warp magento setup:config:set --no-interaction --page-cache=redis --page-cache-redis-server=redis-fpc --page-cache-redis-db=1
    fi

    if [ ! -z "$REDIS_SESSION_VERSION" ]
    then
        warp_message "Enabling Redis for session..."
        warp magento setup:config:set --no-interaction --session-save=redis --session-save-redis-host=redis-session --session-save-redis-log-level=4 --session-save-redis-db=1
    fi

    warp_message "Clearing the cache for good measure..."
    warp magento cache:flush

    case "$(uname -s)" in
      Darwin)
        if [ "$USE_DOCKER_SYNC" = "Y" ] || [ "$USE_DOCKER_SYNC" = "y" ] ; then 
            warp_message "Copying files from container to host after install..."
            warp sync pull app
            warp sync pull vendor
        fi
      ;;
    esac

    warp_message "Restarting containers with host bind mounts for dev..."
    warp restart

    warp_message "Docker development environment setup complete."
    warp_message "You may now access your Magento instance at https://${VIRTUAL_HOST}/"
}

function magento_download()
{
    # Download Magento Community

    [ -z "$1" ] && echo "Please specify the version to download (ex. 2.0.0)" && exit
    curl -L http://pubfiles.nexcess.net/magento/ce-packages/magento2-$1.tar.gz | tar xzf - -o -C .

    # Add include/exclude files to gitignore
    warp_check_gitignore
}

function magento_main()
{
    case "$1" in
        magento)
            shift 1
            magento_command $*
        ;;

        -h | --help)
            magento_help_usage
        ;;

        *)            
            magento_help_usage
        ;;
    esac
}