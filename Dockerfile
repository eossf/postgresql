# git@github.com:eossf/postgresql.git
FROM postgres:12.11-alpine

RUN apk update && apk add openssl bash
RUN mkdir -p /tmp/postgres
#COPY ./create_keys.sh .
WORKDIR /tmp/postgres
CMD bash