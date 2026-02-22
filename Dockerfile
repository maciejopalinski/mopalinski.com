FROM ghcr.io/gohugoio/hugo:v0.155.3 AS build

COPY . .

RUN hugo build --minify

FROM nginx:latest AS server

COPY --from=build /project/public /usr/share/nginx/html