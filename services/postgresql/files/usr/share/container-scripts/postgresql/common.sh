
function usage() {
	if [ $# == 1 ]; then
		echo >&2 "error: $1"
	fi

	cat >&2 <<- EOF
	For general container run, you must either specify the following environment variables:
	  POSTGRESQL_USER POSTGRESQL_PASSWORD POSTGRESQL_DATABASE
	EOF
	exit 1
}

function check_env_vars() {
	if [[ ! -v POSTGRESQL_USER || ! -v POSTGRESQL_PASSWORD || ! -v POSTGRESQL_DATABASE ]]; then
		usage
	fi

	if [[ ! ${#POSTGRESQL_USER} -le 63 ]]; then
		usage "PostgreSQL username too long (maximum 63 characters)"
	fi

	if [[ ! ${#POSTGRESQL_DATABASE} -le 63 ]]; then
		usage "Database name too long (maximum 63 characters)"
	fi
}

function unset_env_vars() {
	unset POSTGRESQL_{DATABASE,USER,PASSWORD}
}

function set_pgdata() {
	# Create a subdirectory that the user owns
	mkdir -p "$PGDATA"
	
	# Ensure sane perms for postgresql startup
	chmod 700 "$PGDATA"
}

function initdb_wrapper() {
	LANG=${LANG:-en_US.utf8} "$@"
}

function initialize_database() {
	initdb_wrapper initdb
}

function auto_tuning_postgresql_settings() {
	# Parsing cgroup information and export variables.
	export $(cgroup-limits)

	if [[ "${NO_MEMORY_LIMIT:-}" == "true" || -z "${MEMORY_LIMIT_IN_BYTES:-}" ]]; then
		export POSTGRESQL_SHARED_BUFFERS=${POSTGRESQL_SHARED_BUFFERS:-32MB}
		export POSTGRESQL_EFFECTIVE_CACHE_SIZE=${POSTGRESQL_EFFECTIVE_CACHE_SIZE:-128MB}

	else
		# Use 1/4 of given memory for shared buffers.
		shared_buffers_computed="$(($MEMORY_LIMIT_IN_BYTES / 1024 / 1024 / 4))MB"

		# Setting effective_cache_size to 1/2 of total memory would be a normal conservative setting.
		effective_cache="$(($MEMORY_LIMIT_IN_BYTES / 1024 / 1024 / 2))MB"

		export POSTGRESQL_SHARED_BUFFERS=${POSTGRESQL_SHARED_BUFFERS:-$shared_buffers_computed}
		export POSTGRESQL_EFFECTIVE_CACHE_SIZE=${POSTGRESQL_EFFECTIVE_CACHE_SIZE:-$effective_cache}
	fi
}

function generate_custom_config() {
	export POSTGRESQL_MAX_CONNECTIONS=${POSTGRESQL_MAX_CONNECTIONS:-100}
	export POSTGRESQL_MAX_PREPARED_TRANSACTIONS=${POSTGRESQL_MAX_PREPARED_TRANSACTIONS:-0}

	auto_tuning_postgresql_settings
	
	envsubst \
		< "${CONTAINER_SCRIPTS_PATH}/postgresql.conf.template" \
		> "${POSTGRESQL_CONFIG_FILE}"

}

function generate_config() {
	# PostgreSQL configuration
	cat >> "$PGDATA/postgresql.conf" <<- EOF
	include '${POSTGRESQL_CONFIG_FILE}'
	EOF

	# Access control configuration
	cat >> "$PGDATA/pg_hba.conf" <<- EOF
	# Allow connections from all hosts.
	host all all all md5

	# Allow replication connections from all hosts.
	host replication all all md5
	EOF
}

function fix_passwd_file() {
	local FIX_UID=$(id -u)
	local FIX_GID=$(id -g)

	grep -v -e ^postgres -e ^$FIX_UID /etc/passwd > "$HOME/passwd"
	echo "postgres:x:${FIX_UID}:${FIX_GID}:PostgreSQL Server:${HOME}:/bin/bash" >> "$HOME/passwd"
	
	export LD_PRELOAD=libnss_wrapper.so
	export NSS_WRAPPER_PASSWD=${HOME}/passwd
	export NSS_WRAPPER_GROUP=/etc/group
}

function create_user() {
	# Create PostgreSQL user
	createuser "$POSTGRESQL_USER"

	# Create PostgreSQL database
	createdb --owner="$POSTGRESQL_USER" "$POSTGRESQL_DATABASE"

	# grant all privileges on database terraform to terraform;
}

function set_password() {
	echo "ALTER USER :\"username\" WITH ENCRYPTED PASSWORD :'password';" | \
	psql --quiet --set ON_ERROR_STOP=1 "$@" \
	--set=username="$POSTGRESQL_USER" \
	--set=password="$POSTGRESQL_PASSWORD"
}
