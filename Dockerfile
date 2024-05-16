FROM alpine:latest AS build

RUN apk update && apk add git && apk add --repository=https://dl-cdn.alpinelinux.org/alpine/edge/community hugo

WORKDIR /app

COPY . .

RUN hugo --minify

FROM nginx:latest AS server

COPY --from=build /app/public /usr/share/nginx/html