FROM node:lts

COPY . /app

WORKDIR /app

RUN npm i && npm run build

EXPOSE 8080

CMD npm start