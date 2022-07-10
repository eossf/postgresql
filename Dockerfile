# git@github.com:eossf/postgresql.git
FROM postgres:12.11-alpine

RUN apk update && apk add openssl bash
RUN mkdir -p /tmp/postgres
#COPY ./create_keys.sh .
WORKDIR /tmp/postgres
RUN chown 70:70 /var/lib/postgresql/data
RUN chmod 0640 /var/lib/postgresql/data
CMD bash

USER 70
RUN initdb -D /var/lib/postgresql/data
# pg_ctl -D /var/lib/postgresql/data -l logfile start