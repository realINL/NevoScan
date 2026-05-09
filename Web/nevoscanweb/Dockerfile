FROM node:20 AS build

WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
RUN npm run build


FROM caddy:2

COPY --from=build /app/dist /usr/share/caddy