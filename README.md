# Kindle Google Photos Picture Frame
The idea is to turn a Kindle Paperwhite into an eInk digital picture frame displaying photos from a shared Google Photos folder. Every 24h a new photo will be displayed.

## What's What
* `get_gphoto.py`: Downloads a random image from a shared album called `kindle`
* `kindle-gphotos.sh`: Main loop on kindle, handles kindle stuff, wifi, calls `get_gphoto.py`, suspend to RAM etc.
* `wifi.sh`: Wifi helper script
* `sync2kindle.sh`: Simple rsync helper for development

## Setup
* Create a shared album called `kindle`. I typically use black and white filtered copies of images. The "Vista" Filter in Google Photos works fine for me for enhanced contrast. Also, I use the "Light" fader to slightly overexpose images. Just using the original color images looked too dull on the eink display.

* You will need an [OAuth2](https://developers.google.com/identity/protocols/OAuth2) Client ID from Google in order to use the Photos API. Obtain OAuth 2.0 client credentials from the [Developers Console](https://console.developers.google.com/). Make sure, you add the scope `../auth/photoslibrary.readonly` to your OAuth consent screen.

* Rename your OAuth credential file to `client_secret.json` and put it next to `get_gphoto.py`. Call `get_gphoto.py` to debug. This should result in a downloaded `photo.jpg`.

* Edit `wifi.sh`, add SSID and PW for your wifi.

* Edit `FBROTATE`and  `BACKLIGHT` in `kindle-gphotos.sh` according to your hardware.

## Credits
I am using code, especially for authorization and the REST api, from https://github.com/gilesknap/gphotos-sync
