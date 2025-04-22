#!/bin/sh
# Name: FullMesquite
# Author: slyhype
# DontUseFBInk

## CONFIG HERE
GO_FULLSCREEN=false # Set to false if you want keyboard access (note, kindle UI is still running and takes up at least 1/4th or more of the screen.)
FULLSCREEN_SITE="https://example.com" # Set to the URL you want to open in fullscreen mode
EXTRACHROMEARGS="" # Extra stuff, mainly for debugging
## END CONFIG

### DO NOT MODIFY PAST THIS POINT UNLESS YOU KNOW WHAT YOU'RE DOING ###

## Thanks KOReader! I'll be borrowing this :)
if [ -d /etc/upstart ]; then
    export INIT_TYPE="upstart"
    if [ -f /etc/upstart/functions ]; then
        . /etc/upstart/functions
    fi
else
    export INIT_TYPE="sysv"
    if [ -f /etc/rc.d/functions ]; then
        . /etc/rc.d/functions
    fi
fi
refresh_screen(){
    eips -c &> /dev/null
    eips -c &> /dev/null
}

stop_gui(){
    if [ "$GO_FULLSCREEN" = true ]; then
        echo "Stopping gui"
        ## Check if using framework or labgui, then stop ui
        if [ "${INIT_TYPE}" = "sysv" ]; then
            /etc/init.d/framework stop
        else
            trap "" TERM
            stop lab126_gui
            usleep 1250000
            trap - TERM
        fi
        refresh_screen
    fi
}

start_gui(){
    if [ "$GO_FULLSCREEN" = true ]; then
        echo "Starting gui"
        ## Check if using framework or labgui, then start ui
        if [ "${INIT_TYPE}" = "sysv" ]; then
            cd / && /etc/init.d/framework start
        else
            cd / && start lab126_gui
            usleep 1250000
        fi
        refresh_screen
        eips 1 1 "Please wait while UI is reset"
    fi
}

stop_gui

lipc-set-prop com.lab126.appmgrd start app://com.lab126.browser

browser_pid=$!
# Watching for a keypress on the power button and exits
unset LD_LIBRARY_PATH
lipc-wait-event com.lab126.powerd PowerButtonQuickPress
kill -9 $browser_pid

start_gui

exit