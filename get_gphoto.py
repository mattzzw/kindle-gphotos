#!/usr/bin/env python3
# coding: utf8

from pathlib import Path
import requests
import json
import logging
from random import randrange

from gphotos.authorize import Authorize
from gphotos.restclient import RestClient

log = logging.getLogger()
logging.basicConfig(level=logging.WARNING)
#log.setLevel(logging.NOTSET)


### Main app class
class KindleGphotos:
    def __init__(self):
        self.auth: Authorize = None

    def setup(self):
        credentials_file = Path(".gphotos.token")
        secret_file = Path("client_secret.json")
        scope = [
            "https://www.googleapis.com/auth/photoslibrary.readonly",
            "https://www.googleapis.com/auth/photoslibrary.sharing",
        ]
        photos_api_url = (
            "https://photoslibrary.googleapis.com/$discovery" "/rest?version=v1"
        )

        self.auth = Authorize(
            scope, credentials_file, secret_file, 3)

        self.auth.authorize()
        self.google_photos_client = RestClient(photos_api_url, self.auth.session)

    def start(self):
        log.debug("Starting up...")
        ### Get album list
        mylist = self.google_photos_client.sharedAlbums.list.execute(pageSize=50).json()

        ### Get album ID
        items_count = 0
        for album in mylist['sharedAlbums']:
            if 'title' in album.keys():
                log.debug('"'+album['title']+'"')
                if album['title'] == 'kindle':
                    print(album['title'], album['mediaItemsCount'])
                    items_count = int(album['mediaItemsCount'])
                    album_id = album['id']

        if not items_count:
            quit()

        ### get list of images
        body = {
                "pageSize": 50,
                "albumId": album_id,
#                "filters": {
#                    "mediaTypeFilter": {"mediaTypes":  ["PHOTO"]},
#                },
            }
        photo_list = self.google_photos_client.mediaItems.search.execute(body).json()
        notfound = 1
        while(notfound):
            idx = randrange(items_count)
            log.debug(idx)
            if "image/jpeg"  in photo_list['mediaItems'][idx]['mimeType']:
                notfound = 0
                media_item = photo_list['mediaItems'][idx]
        print(media_item['filename'], media_item['mimeType'])

        ### download photo
        url = str(media_item['baseUrl'])+'=w2048-h1024'
        photo = requests.get(url)
        open('photo.jpg', 'wb').write(photo.content)

    def main(self):
        self.setup()
        self.start()

if __name__ == '__main__':
    KindleGphotos().main()
