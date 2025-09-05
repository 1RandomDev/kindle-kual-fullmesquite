#!/bin/sh
# Name: FullMesquite
# Author: slyhype & 1RandomDev
# DontUseFBInk

HANDLER_ID="com.lab126.browser" # Default system browser

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

set_screen_brightness(){
    echo $1 > /sys/devices/platform/imx-i2c.0/i2c-0/0-003c/max77696-bl.0/backlight/max77696-bl/brightness
}

prevent_screensaver(){
    lipc-set-prop com.lab126.powerd preventScreenSaver $1
}

stop_system_gui(){
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
}

start_system_gui(){
    echo "Starting gui"
    ## Check if using framework or labgui, then start ui
    if [ "${INIT_TYPE}" = "sysv" ]; then
        cd / && /etc/init.d/framework start
    else
        cd / && start lab126_gui
        usleep 1250000
    fi
    eips 1 1 "Please wait while Kindle UI is starting"

    lipc-set-prop com.lab126.powerd preventScreenSaver 0
}

# Stop Kindle UI to save ressources and remove all menu bars
stop_system_gui
# Disable screensaver/standby mode
prevent_screensaver 1
# Disable backlight
set_screen_brightness 0

# Start actual app
lipc-set-prop com.lab126.appmgrd start "app://$HANDLER_ID"

# Wait for power button press
script -f /dev/null -c "evtest /dev/input/event0" | while read line; do
    case "$line" in
        *"code 116 (Power), value 1"*)
            # Kill app before restoring system UI to prevent it from freezing in fullscreen mode
            echo "Power button pressed";
            browserPid=$(gdbus call -y -d org.freedesktop.DBus -o / -m org.freedesktop.DBus.GetConnectionUnixProcessID "$HANDLER_ID" | sed -E 's/.* ([0-9]+),.*/\1/')
            echo "Killing PID $browserPid"
            kill $browserPid

            start_system_gui
            prevent_screensaver 0
            exit
            ;;
    esac
done
