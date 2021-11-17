FROM node:lts-alpine

RUN apk add git python3 build-base --no-cache 

COPY . /app

WORKDIR /app

RUN npm i && npm run build

EXPOSE 8080

CMD npm start