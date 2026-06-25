FROM node:24.16-alpine

WORKDIR /backend

ADD package.json server.js db.js /backend/
RUN npm install

EXPOSE 5000

CMD ["npm", "start"]


