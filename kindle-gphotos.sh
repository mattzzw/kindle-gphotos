#!/bin/sh

PWD=$(pwd)
LOG="/mnt/us/gphotos.log"
SLEEP_MINUTES=1440 #24h
FBINK="fbink -q"
FONT="regular=/usr/java/lib/fonts/Palatino-Regular.ttf"

### uncomment/adjust according to your hardware
#PW3
FBROTATE="/sys/devices/platform/imx_epdc_fb/graphics/fb0/rotate"
BACKLIGHT="/sys/devices/platform/imx-i2c.0/i2c-0/0-003c/max77696-bl.0/backlight/max77696-bl/brightness"

#PW2
#FBROTATE="/sys/devices/platform/mxc_epdc_fb/graphics/fb0/rotate"
#BACKLIGHT="/sys/devices/system/fl_tps6116x/fl_tps6116x0/fl_intensity"

wait_wlan_connected() {
  return `lipc-get-prop com.lab126.wifid cmState | grep CONNECTED | wc -l`
}

wait_wlan_ready() {
  return `lipc-get-prop com.lab126.wifid cmState | grep -e READY -e PENDING -e CONNECTED | wc -l`
}

### Dim Backlight
echo -n 0 > $BACKLIGHT

### Prepare Kindle, shutdown framework etc.
echo "------------------------------------------------------------------------" >> $LOG
echo "`date '+%Y-%m-%d_%H:%M:%S'`: Starting up, killing framework et. al." >> $LOG

### stop processes that we don't need
stop lab126_gui
### give an update to the outside world...
echo 0 > $FBROTATE
$FBINK -w -c -f -m -t $FONT,size=20,top=410,bottom=0,left=0,right=0 "Starting gphotos..." > /dev/null 2>&1
#echo 3 > $FBROTATE
sleep 1
### keep stopping stuff
stop otaupd
stop phd
stop tmd
stop x
stop todo
stop mcsd
stop archive
stop dynconfig
stop dpmd
stop appmgrd
stop stackdumpd
#stop powerd  ### otherwise the pw3 is not going to suspend to RAM?
sleep 2

# At this point we should be left with a more or less Amazon-free environment
# I leave
# - powerd & deviced
# - lipc-daemon
# - rcm
# running.

### If we have a wan module installed...
#if [ -f /usr/sbin/wancontrol ]
#then
#    wancontrol wanoffkill
#fi

### Disable Screensaver
lipc-set-prop com.lab126.powerd preventScreenSaver 1

echo "`date '+%Y-%m-%d_%H:%M:%S'`: Entering main loop..." >> $LOG

while true; do

	NOW=$(date +%s)

	let SLEEP_SECONDS=60*SLEEP_MINUTES
	let WAKEUP_TIME=$NOW+SLEEP_SECONDS
	echo `date '+%Y-%m-%d_%H:%M:%S'`: Wake-up time set for  `date -d @${WAKEUP_TIME}` >> $LOG

    ### Dim Backlight
    echo -n 0 > $BACKLIGHT

	### Disable CPU Powersave
	echo ondemand > /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor

    echo 0 > $FBROTATE

    lipc-set-prop com.lab126.cmd wirelessEnable 1
    ### Wait for wifi interface to come up
    echo `date '+%Y-%m-%d_%H:%M:%S'`: Waiting for wifi interface to come up... >> $LOG
    while wait_wlan_ready; do
        sleep 1
    done

    ### Wifi interface is up, connect to access point.
    ./wifi.sh

	### Wait for WIFI connection
    TRYCNT=0
    NOWIFI=0
    echo `date '+%Y-%m-%d_%H:%M:%S'`: Waiting for wifi interface to become ready... >> $LOG
	while wait_wlan_connected; do
        if [ ${TRYCNT} -gt 30 ]; then
            ### waited long enough
            echo "`date '+%Y-%m-%d_%H:%M:%S'`: No Wifi... ($TRYCNT)" >> $LOG
            NOWIFI=1
            $FBINK -x 5 "No Wifi..."
            break
        fi
	  sleep 1
      let TRYCNT=$TRYCNT+1
	done

	echo `date '+%Y-%m-%d_%H:%M:%S'`: WIFI connected! >> $LOG

    BAT=$(gasgauge-info -c)
    $FBINK -x 20 "Getting new image..."
    ./get_gphoto.py
    fbink -q -c -f -i photo.jpg -g w=-1,h=-1,dither=PASSTHROUGH
    fbink -q $BAT

    echo `date '+%Y-%m-%d_%H:%M:%S'`: Battery level: $BAT >> $LOG

    ### Enable powersave
    echo powersave > /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor

    ### flight mode on...
    lipc-set-prop com.lab126.cmd wirelessEnable 0

	sleep 2

    ### set wake up time to one hour
    echo `date '+%Y-%m-%d_%H:%M:%S'`: Sleeping now... >> $LOG
	rtcwake -d /dev/rtc0 -m mem -s $SLEEP_SECONDS
	### Go into Suspend to Memory (STR)
done
