FROM node:9.4.0-alpine

ARG YARN_VERSION=1.2.1
RUN npm install -g "yarn@${YARN_VERSION}"

RUN apk update \
    && apk upgrade \
    && apk add --no-cache git bash

WORKDIR /usr/src/app

COPY package.json yarn.lock /usr/src/app/
RUN yarn install --frozen-lockfile \
    && yarn check --integrity \
    && yarn cache clean

COPY . /usr/src/app

CMD ["tail", "-f", "/dev/null"]
