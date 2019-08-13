#!/usr/bin/env bash

# QLC+ helper script, to be used when starting QLC+ system service

set_static()
{
    IFS="," read -r -a staticparts <<<"$1"
    if [ ${#staticparts[@]} != 5 ]; then
        return
    fi
    INTERFACE="interface ${staticparts[0]}"
    IP="static ip_address=${staticparts[1]}"
    ROUTERS="static routers=${staticparts[2]}"
    DNS="static domain_name_servers=${staticparts[3]}"
    # If no previous STATIC interface has been set then remove any existing QLC+ config
    if [ "$2" == "false" ]; then
        sed -i '/######### QLC+ parameters. Do not edit #########/Q' /etc/dhcpcd.conf
        # Put the QLC+ line back for web config compatability
        echo "######### QLC+ parameters. Do not edit #########" >> /etc/dhcpcd.conf
    fi
    # TODO: Make this less destructive, currently it will remove any previous config
    {
        echo "$INTERFACE"
        echo "$IP"
        echo "$ROUTERS"
        echo "$DNS"
    } >> /etc/dhcpcd.conf
    # Restart the interface for the changes to take effect
    if [ "${staticparts[4]}" == "true" ]; then
        ip link set "${staticparts[0]}" down
        ip link set "${staticparts[0]}" up
    fi
}

CONFIG_PATH=/data/qlcplus.conf
ASSETS_PATH=/data/
ASSETS=( "Fixtures" "InputProfiles" "MidiTemplates" "ModifiersTemplates" "RGBScripts" )

AUTOSTART=false
GPIO=false
UART=false
DMX_USB=false
STATIC=false

# Reset changes made for web kiosk mod
cp /usr/share/qlcplus/web/common.css.normal /usr/share/qlcplus/web/common.css

# Option to override kiosk mode set from config file
NO_KIOSK=false
if [ -e "$ASSETS_PATH/qlcplus.no-kiosk" ]; then
    rm "$ASSETS_PATH/qlcplus.no-kiosk"
    NO_KIOSK=true
fi

# IPtables rules to redirect standard HTTP port 80 trafic to QLC+ port 9999
iptables -A INPUT -i wlan0 -p tcp --dport 80 -j ACCEPT
iptables -A INPUT -i wlan0 -p tcp --dport 9999 -j ACCEPT
iptables -A PREROUTING -t nat -i wlan0 -p tcp --dport 80 -j REDIRECT --to-port 9999
iptables -A INPUT -i eth0 -p tcp --dport 80 -j ACCEPT
iptables -A INPUT -i eth0 -p tcp --dport 9999 -j ACCEPT
iptables -A PREROUTING -t nat -i eth0 -p tcp --dport 80 -j REDIRECT --to-port 9999

# Remove old asses and copy new assets to correct place
for ASSET in "${ASSETS[@]}"; do
    if [ -e "/root/.qlcplus/$ASSET" ]; then
        rm -r "/root/.qlcplus/$ASSET"
    fi
    mkdir "/root/.qlcplus/$ASSET"
    cp -a "$ASSETS_PATH/$ASSET/." "/root/.qlcplus/$ASSET/"
done

# Start the GPIO input and output plugin lines with spaces for indentation
GPIO_INPUT_PLUGIN_LINE="    <Input Plugin=\"GPIO\" Line=\"0\">\\n     <PluginParameters"
GPIO_OUTPUT_PLUGIN_LINE="    <Output Plugin=\"GPIO\" Line=\"0\">\\n     <PluginParameters"

QLCPLUS_OPTS="--nowm"

while read -r line; do
    IFS="=" read -a lineparts <<<"$line"
    case "${lineparts[0]}" in
        OPERATE)
            if [ "${lineparts[1]}" == "true" ]; then
                QLCPLUS_OPTS="$QLCPLUS_OPTS --operate"
            fi
            ;;
        KIOSK)
            if [ "${lineparts[1]}" == "true" ] && [ "$NO_KIOSK" == "false" ]; then
                QLCPLUS_OPTS="$QLCPLUS_OPTS --kiosk"
                cp /usr/share/qlcplus/web/common.css.kiosk /usr/share/qlcplus/web/common.css
            fi
            ;;

        WEB)
            if [ "${lineparts[1]}" == "true" ]; then
                QLCPLUS_OPTS="$QLCPLUS_OPTS --web --web-auth"
            fi
            ;;
        AUTOSTART)
            AUTOSTART="${lineparts[1]}"
            ;;
        UART)
            if [ "${lineparts[1]}" == "true" ]; then
                UART=true
                gpio -g mode 18 out
                gpio -g write 18 1
            fi
            ;;
        DMX_USB)
            if [ "${lineparts[1]}" == "true" ]; then
                DMX_USB=true
            fi
            ;;
        GPIO_INPUT)
            # Set GPIO input
            # Option -g to use BCM numbers, same as QLC+
            gpio -g mode "${lineparts[1]}" in
            # Use interneal pull up resistors
            gpio -g mode "${lineparts[1]}" up
            # Add the pin number to the GPIO input plugin
            # line for later insertion to the QLC+ workspace
            GPIO_INPUT_PLUGIN_LINE="$GPIO_INPUT_PLUGIN_LINE pinUsage-${lineparts[1]}=\"Input\""
            GPIO=true
            ;;
        GPIO_OUTPUT)
            # Set GPIO output
            gpio -g mode "${lineparts[1]}" out
            GPIO_OUTPUT_PLUGIN_LINE="$GPIO_OUTPUT_PLUGIN_LINE pinUsage-${lineparts[1]}=\"Output\""
            GPIO=true
            ;;
        SCREEN_WIDTH)
            # Set screen size in mm to get corrrect DPI
            export QT_QPA_EGLFS_PHYSICAL_WIDTH="${lineparts[1]}"
            ;;
        SCREEN_HEIGHT)
            export QT_QPA_EGLFS_PHYSICAL_HEIGHT="${lineparts[1]}"
            ;;
        STATIC)
            set_static "${lineparts[1]}" $STATIC
            STATIC=true
            ;;
        GPIO_RESTART)
            IFS="," read -r -a gpio_restart_parts <<<"${lineparts[1]}"
            exec nohup "$ASSETS_PATH/qlcplus_gpio_restarter.sh" "${gpio_restart_parts[0]}" "${gpio_restart_parts[1]}" "$ASSETS_PATH/qlcplus.no-kiosk" >/dev/null 2>&1 &
            ;;
        esac
done < "$CONFIG_PATH"

if [ "$AUTOSTART" != "false" ]; then

    # Check for previous AUTOSTART and move it out the way
    if [ -e /root/.qlcplus/autostart.qxw ]; then
        mv /root/.qlcplus/autostart.qxw /root/.qlcplus/autostart.qxw.bak
    fi

    # Check for a leading / in specified AUTOSTART path
    if [ "${AUTOSTART:0:1}" != "/" ]; then
        # If no leading then assume it is a file in the ASSETS_PATH
        AUTOSTART="${ASSETS_PATH}/${AUTOSTART}"
    fi

    # Check the specified AUTOSTART file exists
    if [ -e "$AUTOSTART" ]; then
        # If so copy it to the AUTOSTART location to be opened by QLC+
        cp "$AUTOSTART" /root/.qlcplus/autostart.qxw
    fi

    # If GPIO has been used try to add the GPIO plugin info to the relevant universe
    if [ "$GPIO" == "true" ]; then
        # End the input and output plugin lines
        GPIO_INPUT_PLUGIN_LINE="$GPIO_INPUT_PLUGIN_LINE/>\\n    </Input>"
        GPIO_OUTPUT_PLUGIN_LINE="$GPIO_OUTPUT_PLUGIN_LINE/>\\n    </Output>"
        # Add GPIO plugin definitions
        GPIO_UNIVERSE_LINE=">\\n$GPIO_INPUT_PLUGIN_LINE\\n$GPIO_OUTPUT_PLUGIN_LINE\\n   </Universe>"
        sed -ie "s|\(<Universe Name=\"GPIO\" .*\)/>|\1$GPIO_UNIVERSE_LINE|g" /root/.qlcplus/autostart.qxw
    fi

    # If UART has been used try to add the plugin info to the relevant universe
    if [ "$UART" == "true" ]; then
        UART_UNIVERSE_LINE=">\\n    <Output Plugin=\"UART\" Line=\"0\"/>\\n   </Universe>"
        sed -ie "s|\(<Universe Name=\"UART\" .*\)/>|\1$UART_UNIVERSE_LINE|g" /root/.qlcplus/autostart.qxw
    fi

    # If DMX-USB has been used try to add the plugin info to the relevant universe
    if [ "$DMX_USB" == "true" ]; then
        DMX_USB_UNIVERSE_LINE=">\\n    <Output Plugin=\"DMX USB\" Line=\"0\"/>\\n   </Universe>"
        sed -ie "s|\(<Universe Name=\"DMX USB\" .*\)/>|\1$DMX_USB_UNIVERSE_LINE|g" /root/.qlcplus/autostart.qxw
    fi

    # Set the file to open on QLC+ launch
    QLCPLUS_OPTS="$QLCPLUS_OPTS --open /root/.qlcplus/autostart.qxw"
fi
