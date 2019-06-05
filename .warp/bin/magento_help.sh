#!/bin/bash

function magento_help_usage()
{
    warp_message ""
    warp_message_info "Usage:"
    warp_message      " warp magento [options] [arguments]"
    warp_message ""

    warp_message ""
    warp_message_info "Options:"
    warp_message_info   " -h, --help         $(warp_message 'display this help message')"
    warp_message_info   " -T                 $(warp_message 'disable pseudo TTY. Useful for Jenkins integration')"
    warp_message_info   " --root             $(warp_message 'execute bin/magento with root privileges')"
    warp_message_info   " --download         $(warp_message 'Download Magento Community')"
    warp_message_info   " --install          $(warp_message 'Install Magento with setup previously configured in wizard')"
    warp_message ""

    warp_message ""
    warp_message_info "Help:"
    warp_message " Allow run bin/magento inside the container "
    warp_message ""

    warp_message_info "Example:"
    warp_message " warp magento cache:clean"
    warp_message " warp magento --download 2.3.1"
    warp_message " warp magento install"
    warp_message ""    
}

function magento_help()
{
    warp_message_info   " magento            $(warp_message 'execute bin/magento inside the container')"
}
