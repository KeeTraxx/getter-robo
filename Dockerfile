FROM node:9-alpine

COPY server /app

WORKDIR /app

CMD node server.js