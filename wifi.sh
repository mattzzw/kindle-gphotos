#!/bin/sh  
id="`wpa_cli add_network | sed -n '2p'`" 
echo $id

exec="`wpa_cli << EOF
set_network $id ssid \"Your SSID\"
set_network $id psk \"Your PW\"
set_network $id key_mgmt WPA-PSK
set_network $id group CCMP TKIP
set_network $id proto RSN WPA
set_network $id pairwise CCMP TKIP
select_network $id
enable_network $id
quit
EOF
`"
echo $exec
udhcpc -i wlan0

