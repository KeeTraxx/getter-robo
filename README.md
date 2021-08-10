# getter-robo

## Usage

### docker-compose

```yaml
version: '3.4'

services:
  k-torrent:
    image: keetraxx/getter-robo:2
    ports:
      - 8080:8080
    volumes:
      - ./data:/app/data
    logging:
      options:
        max-size: 10m
    networks:
      - web
networks:
  web:
    external: true
```

### Initialize DB

`docker-compose run npx prisma db push`
