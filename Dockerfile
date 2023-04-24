FROM klakegg/hugo:latest AS build

WORKDIR /app

COPY . .

RUN hugo --minify

FROM nginx:latest AS server

COPY --from=build /app/public /usr/share/nginx/html