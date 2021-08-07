# k-torrent

k-torrent is a webfrontend for webtorrent.
Its main use case is to be able to run it in a docker container.

## Usage

### docker-compose

```yaml
version: "3.4"

services:
  k-torrent:
    image: keetraxx/k-torrent
    ports:
      - 8080:8080
    volumes:
      - .config:/app/.config
      - /downloads:/downloads
    environment:
      - PORT: 8080
      - CONF_DIR: ./config:/app/.config
      - UPLOAD_LIMIT: 512000
      - DOWNLOAD_LIMIT: -1
      - DOWNLOAD_FOLDER: /downloads
    logging:
      options:
        max-size: 10m
    labels:
      - "traefik.enable=true"
      - "traefik.backend=deluge"
      - "traefik.docker.network=web"
      - "traefik.frontend.rule=Host:k-torrent.compile.ch"
      - "traefik.port=8080"
      - "traefik.frontend.whiteList.sourceRange=192.168.0.0/24"
    networks:
      - web
networks:
  web:
    external: true
```