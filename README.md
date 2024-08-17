# docker-seafile-client
Run a seafile client inside docker which can sync files from seafile repositories

See docker-compose how to use.

## Environment variables:
 - `context` 
    - The path to the directory containing `Dockerfile` and `start.sh`
 - LIBRARY_ID
    - Can be multiple library ids separated with colon :
 - SERVER_URL
    - The url used to access your server, eg: https://example.seafile.com
 - SERVER_PORT
    - Which port the server is hosted on: usually 443 (https) or 80 (http)
 - USERNAME & PASSWORD
    - Your seafile's account username and password (credentials)
 - CONNECT_RETRIES (optional)
    - How many times try to connect to daemon. Higher value is useful on slow boxes. Default is 5
 - DISABLE_VERIFY_CERTIFICATE (optional)
    - (Default: false) Disable certificate validation. In case you connect to a server with a self-signed certificate. ! Do not use to connect to public server on the internet ! Use a trusted certificate provider instead.
 - `<library-host-volume-path>`
    - The path to the directory containing the libraries to sync
 - `<sync-state-host-volume-path>` (optional)
    - (Recommended, use a persistent docker volume. If unused, delete the line.) The path to the directory where seafile-client saves state (so that you can re-instantiate/move the container and client should avoid having conflicts in the library because of attempting to sync an existing local library that is different than the server)

## How to find library id:

<img src="imgs/help.png"/>
