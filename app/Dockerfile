# Build the app
FROM node:8.14.0-alpine

ARG custom_params

WORKDIR /app

COPY . /app

RUN npm install $custom_params

EXPOSE 3000

CMD ["node", "app.js"]