# git@github.com:eossf/postgresql.git
FROM postgres:12.11-alpine

# user id postgres. 26 or 70 or ...?
ARG POSTGRESQL_UID=70

# version
ARG POSTGRESQL_VERSION=12

RUN apk update && apk add openssl bash python3 gettext

# Copy files
COPY files /
RUN mkdir -p /var/lib/postgresql/tls
COPY server.* /var/lib/postgresql/tls/

ENV PATH=/usr/libexec:${PATH} \
  CONTAINER_SCRIPTS_PATH=/usr/share/container-scripts/postgresql \
  POSTGRESQL_UID=${POSTGRESQL_UID}

# Make directories and set permissions echo $? ==> 0 for true, 1 for false.
RUN test "$(id postgres)" = "uid=${POSTGRESQL_UID}(postgres) gid=${POSTGRESQL_UID}(postgres) groups=${POSTGRESQL_UID}(postgres),${POSTGRESQL_UID}(postgres)" && \
     mkdir -p /var/lib/postgresql/data && \
     /usr/libexec/fix-permissions --uid=${POSTGRESQL_UID} /var/lib/postgresql/data /var/run/postgresql  && \
     /usr/libexec/fix-permissions-tls --uid=${POSTGRESQL_UID} /var/lib/postgresql/tls

USER $POSTGRESQL_UID}
CMD ["run-postgresql"]