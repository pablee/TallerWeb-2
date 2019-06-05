#!/bin/bash

    # IMPORT HELP

    . "$PROJECTPATH/.warp/bin/sync_help.sh"

function push_to_container() {

  if [ "$1" = "-h" ] || [ "$1" = "--help" ] ; then      
      push_help_usage
      exit 0;
  fi

  if [ $(warp_check_is_running) = false ]; then
    warp_message_error "The containers are not running"
    warp_message_error "please, first run warp start"

    exit 1;
  fi

  case "$(uname -s)" in
    Linux)
      warp_message_error "these commands are available only on mac"
      exit 1;
    ;;
  esac

  [ -z "$1" ] && warp_message_error "Please specify a directory or file to copy to container (ex. vendor, --all)" && exit

  if [ "$1" == "--all" ]; then
    docker cp ./ $(docker-compose -f $DOCKERCOMPOSEFILE ps|grep php|awk '{print $1}'):/var/www/html 2>/dev/null 
    warp_message "Completed copying all files from host to container"
    warp fix --owner
  else
    docker cp ./$1 $(docker-compose -f $DOCKERCOMPOSEFILE ps|grep php|awk '{print $1}'):/var/www/html
    warp_message "Completed copying $1 from host to container"

    # fix permissions
    warp fix --owner $1
  fi  
}

function pull_from_container() {

  if [ "$1" = "-h" ] || [ "$1" = "--help" ] ; then      
      pull_help_usage
      exit 0;
  fi

  if [ $(warp_check_is_running) = false ]; then
    warp_message_error "The containers are not running"
    warp_message_error "please, first run warp start"

    exit 1;
  fi

  case "$(uname -s)" in
    Linux)
      warp_message_error "these commands are available only on mac"
      exit 1;
    ;;
  esac

  [ -z "$1" ] && warp_message_error "Please specify a directory or file to copy from container (ex. vendor, --all)" && exit

  if [ "$1" == "--all" ]; then
    docker cp $(docker-compose -f $DOCKERCOMPOSEFILE ps|grep php|awk '{print $1}'):/var/www/html/./ ./
    warp_message "Completed copying all files from container to host"
  else
    docker cp $(docker-compose -f $DOCKERCOMPOSEFILE ps|grep php|awk '{print $1}'):/var/www/html/$1 ./
    warp_message "Completed copying $1 from container to host"
  fi  
}

function warp_clean_volume()
{
  if [ "$1" = "-h" ] || [ "$1" = "--help" ] ; then      
      clean_help_usage
      exit 0;
  fi

  docker-sync -f $DOCKERSYNCMAC clean
}

function sync_main()
{
    case "$1" in
        push)
		      shift 1
          push_to_container $*  
        ;;

        pull)
		      shift 1
          pull_from_container $*  
        ;;

        clean)
          warp_clean_volume
        ;;

        *)
		      sync_help_usage
        ;;
    esac
}
