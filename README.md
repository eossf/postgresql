# PostgreSql security enabled

This project implements all security layers available in postgresql.

    PostgreSQL offers encryption at several levels, and provides flexibility in protecting data from disclosure due to database server theft, unscrupulous administrators, and insecure networks. Encryption might also be required to secure sensitive data such as medical records or financial transactions.
    - Password Encryption
    - Encryption For Specific Columns
    - Data Partition Encryption
    - Encrypting Data Across A Network
    - SSL Host Authentication
    - Client-Side Encryption

see [general documentation](https://www.postgresql.org/docs/14/encryption-options.html)

List of useful tools for postgresql :

  - [pgadmin](https://www.pgadmin.org/download/)

## Setup

### Encrypting Data Across A Network
see [ssl-tcp](https://www.postgresql.org/docs/14/ssl-tcp.html)
see docker-compose file in this project

Setup with Servers Key and Cert

    Enable by setting the parameter ssl = on in postgresql.conf
    
    Set parameters ssl_cert_file and ssl_key_file 
    
    chmod 0600 server.key.
    
    Alternatively, the file can be owned by root and have group read access (that is, 0640 permissions The user under which the PostgreSQL server runs should then be made a member of the group that has access to those certificate and key files. If the data directory allows group read access then certificate files may need to be located outside of the data directory

Certificates rotation
    
    If the private key is protected with a passphrase, the server will prompt for the passphrase and will not start until it has been entered. Using a passphrase by default disables the ability to change the server's SSL configuration without a server restart, but see ssl_passphrase_command_supports_reload. 

Passphrase on windows
    
    Passphrase-protected private keys cannot be used at all on Windows.

Certificate

    The first certificate in server.crt must be the server's certificate because it must match the server's private key. The certificates of “intermediate” certificate authorities can also be appended to the file. Doing this avoids the necessity of storing intermediate certificates on clients, assuming the root and intermediate certificates were created with v3_ca extensions. (This sets the certificate's basic constraint of CA to true.) This allows easier expiration of intermediate certificates.

    It is not necessary to add the root certificate to server.crt. Instead, clients must have the root certificate of the server's certificate chain.

OpenSSL

    PostgreSQL reads the system-wide OpenSSL configuration file. By default, this file is named openssl.cnf and is located in the directory reported by openssl version -d. This default can be overridden by setting environment variable OPENSSL_CONF to the name of the desired configuration file.

## Docker run

Simple postres db

    docker run --name postgres --rm -d -e POSTGRES_USER=postgres -e POSTGRES_PASSWORD=0123456789012345 -e PGDATA=/var/lib/postgresql/data/pgdata -v /tmp:/var/lib/postgresql/data -p 5432:5432 -it postgres:12.11-alpine


Generate keys and conf
Run the script in the project repository /tmp "createkeys.sh" which creates keys in project tmp

    docker build . -t postgres
    docker run --rm -it -v "/mnt/c/DevOps/postgresql/tmp:/tmp/postgres" postgres bash
