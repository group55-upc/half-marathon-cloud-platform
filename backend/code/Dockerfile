FROM node:24.16-alpine

WORKDIR /api

COPY package*.json /api/

RUN npm install

COPY server.js db.js /api/

USER node
EXPOSE 5000

CMD ["npm", "start"]


