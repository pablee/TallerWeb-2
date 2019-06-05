#!/bin/bash


##
# Read a variable from .env file located in root folder
# Use:
#    my_var=$(warp_env_read_var REDIS_CACHE_VERSION)
#    echo $my_var
#
# Globals:
#   PROJECTPATH
# Arguments:
#   $1 Var to read. Ex. REDIS_CACHE_VERSION
# Returns:
#   string
##
function warp_env_read_var()
{
    _VAR=$(grep "^$1=" $ENVIRONMENTVARIABLESFILE | cut -d '=' -f2)
    echo $_VAR
}

# Generate RANDOM Password
# Globals:
#   PROJECTPATH
# Arguments:
#   $1 number long password to generate.
# Returns:
#   string
function warp_env_random_password()
{
    set="abcdefghijklmonpqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    n=$1
    rand=""
    for i in `seq 1 $n`; do
        char=${set:$RANDOM % ${#set}:1}
        rand+=$char
    done
    echo $rand
}