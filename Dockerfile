FROM klakegg/hugo:alpine AS build

RUN apk add git

WORKDIR /app

COPY . .

RUN hugo --minify

FROM nginx:latest AS server

COPY --from=build /app/public /usr/share/nginx/html