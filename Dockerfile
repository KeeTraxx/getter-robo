FROM node:lts-alpine

COPY . /app

RUN ls /app

RUN cd /app/client && npm install && npm build
RUN cd /app/server && npm install && ln -s ../client/dist public

WORKDIR /app/server

CMD node server.js