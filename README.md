### This image is built to run on s390x architecture
-    [build source](https://github.com/korpx-z/postgres)
-    [original source code](https://github.com/docker-library/postgres)

### Tags
10, 11, 12, 13
# PostgreSQL
![logo](https://raw.githubusercontent.com/docker-library/docs/01c12653951b2fe592c1f93a13b4e289ada0e3a1/postgres/logo.png)
<br />
PostgreSQL, often simply "Postgres", is an object-relational database management system (ORDBMS) with an emphasis on extensibility and standards-compliance. As a database server, its primary function is to store data, securely and supporting best practices, and retrieve it later. It can handle workloads ranging from small single-machine applications to large Internet-facing applications with many concurrent users. Recent versions also provide replication of the database itself for security and scalability.

> [wikipedia.org/wiki/PostgreSQL](https://en.wikipedia.org/wiki/PostgreSQL)


# How to use this image

**start a postgres instance**

```console
$ docker run --name some-postgres -e POSTGRES_PASSWORD=mysecretpassword -d quay.io/ibm/postgres:xx
```

The default `postgres` user and database are created in the entrypoint with `initdb`.
_**Note you can also use -u psql in your docker run statement to enter the container as user psql**_

## Environment Variables

The PostgreSQL image uses several environment variables which are easy to miss. The only variable required is `POSTGRES_PASSWORD`, the rest are optional.

**Warning**: the Docker specific variables will only have an effect if you start the container with a data directory that is empty; any pre-existing database will be left untouched on container startup.

### `POSTGRES_PASSWORD`

This environment variable is required for you to use the PostgreSQL image. It must not be empty or undefined. This environment variable sets the superuser password for PostgreSQL. The default superuser is defined by the `POSTGRES_USER` environment variable.

**Note 1:** The PostgreSQL image sets up `trust` authentication locally so you may notice a password is not required when connecting from `localhost` (inside the same container). However, a password will be required if connecting from a different host/container.

**Note 2:** This variable defines the superuser password in the PostgreSQL instance, as set by the `initdb` script during initial container startup. It has no effect on the `PGPASSWORD` environment variable that may be used by the `psql` client at runtime, as described at [https://www.postgresql.org/docs/10/static/libpq-envars.html](https://www.postgresql.org/docs/10/static/libpq-envars.html). `PGPASSWORD`, if used, will be specified as a separate environment variable.

### `POSTGRES_USER`

This optional environment variable is used in conjunction with `POSTGRES_PASSWORD` to set a user and its password. This variable will create the specified user with superuser power and a database with the same name. If it is not specified, then the default user of `postgres` will be used.

Be aware that if this parameter is specified, PostgreSQL will still show `The files belonging to this database system will be owned by user "postgres"` during initialization. This refers to the Linux system user (from `/etc/passwd` in the image) that the `postgres` daemon runs as, and as such is unrelated to the `POSTGRES_USER` option. See the section titled "Arbitrary `--user` Notes" for more details.

### `POSTGRES_DB`

This optional environment variable can be used to define a different name for the default database that is created when the image is first started. If it is not specified, then the value of `POSTGRES_USER` will be used.

### `POSTGRES_INITDB_ARGS`

This optional environment variable can be used to send arguments to `postgres initdb`. The value is a space separated string of arguments as `postgres initdb` would expect them. This is useful for adding functionality like data page checksums: `-e POSTGRES_INITDB_ARGS="--data-checksums"`.

### `POSTGRES_INITDB_WALDIR`

This optional environment variable can be used to define another location for the Postgres transaction log. By default the transaction log is stored in a subdirectory of the main Postgres data folder (`PGDATA`). Sometimes it can be desireable to store the transaction log in a different directory which may be backed by storage with different performance or reliability characteristics.

**Note:** on PostgreSQL 9.x, this variable is `POSTGRES_INITDB_XLOGDIR` (reflecting [the changed name of the `--xlogdir` flag to `--waldir` in PostgreSQL 10+](https://wiki.postgresql.org/wiki/New_in_postgres_10#Renaming_of_.22xlog.22_to_.22wal.22_Globally_.28and_location.2Flsn.29)).

### `POSTGRES_HOST_AUTH_METHOD`

This optional variable can be used to control the `auth-method` for `host` connections for `all` databases, `all` users, and `all` addresses. If unspecified then [`md5` password authentication](https://www.postgresql.org/docs/current/auth-password.html) is used. On an uninitialized database, this will populate `pg_hba.conf` via this approximate line:

```console
echo "host all all all $POSTGRES_HOST_AUTH_METHOD" >> pg_hba.conf
```

See the PostgreSQL documentation on [`pg_hba.conf`](https://www.postgresql.org/docs/current/auth-pg-hba-conf.html) for more information about possible values and their meanings.

**Note 1:** It is not recommended to use [`trust`](https://www.postgresql.org/docs/current/auth-trust.html) since it allows anyone to connect without a password, even if one is set (like via `POSTGRES_PASSWORD`). For more information see the PostgreSQL documentation on [*Trust Authentication*](https://www.postgresql.org/docs/current/auth-trust.html).

**Note 2:** If you set `POSTGRES_HOST_AUTH_METHOD` to `trust`, then `POSTGRES_PASSWORD` is not required.

### `PGDATA`

This optional variable can be used to define another location - like a subdirectory - for the database files. The default is `/var/lib/postgresql/data`. If the data volume you're using is a filesystem mountpoint (like with GCE persistent disks) or remote folder that cannot be chowned to the `postgres` user (like some NFS mounts), Postgres `initdb` recommends a subdirectory be created to contain the data. 

<br />

**On ZCX**, we will need to create a volume instead, and mount said volume within the created container.

For example:

```console
$ docker volume create <your_volume>
```
```console
$ docker run -d \
	--name some-postgres \
	-e POSTGRES_PASSWORD=mysecretpassword \
	-e PGDATA=/var/lib/postgresql/data/pgdata \
	-v <your_volume>:/var/lib/postgresql/data \
	quay.io/ibm/postgres:xx
```

This is an environment variable that is not Docker specific. Because the variable is used by the `postgres` server binary (see the [PostgreSQL docs](https://www.postgresql.org/docs/11/app-postgres.html#id-1.9.5.14.7)), the entrypoint script takes it into account.

## Docker Secrets

As an alternative to passing sensitive information via environment variables, `_FILE` may be appended to some of the previously listed environment variables, causing the initialization script to load the values for those variables from files present in the container. In particular, this can be used to load passwords from Docker secrets stored in `/run/secrets/<secret_name>` files. 
<br />
**Again, it's important to note** that the contents of this directory will be blank by default and that bind mounts do *not* work presently in ZCX. Please place password/environmental values within a volume using `docker cp`, and mount said volume within the container - mapping it to the path `/run/secrets/<name>`. <br />
EX: <br />

```console
$ docker volume create psgrs
$ mkdir -p run/secrets
```

_then place any environmental values as their own named files within /run/secrets/<your_env_value_file>_

<br />
**We will point to this file during our docker run statement, and pass it as an environment variable to be used by postgres.** 
Now move the contents of `/run/secrets*` over to the volume you've created by using a temporary container to populate the volume. <br />

 _Keep in mind that `tail -f /dev/null` can be replaced with any command that doesn't return an exit code._

``` context
$ echo $PWD
/root/
$ ls
run/
```
```console
$ docker run -d --rm --name temp -v <your_volume>:/root/ quay.io/ibm/alpine:3.12 tail -f /dev/null
$ docker cp run/. temp:/root
$ docker stop temp
```
Then run the postgres container using this new volume to populate `/run/secrets` with the needed files to pass as environment variables.

```console
$ docker run --name some-postgres -v <your_volume>:/run/ -e POSTGRES_PASSWORD_FILE=/run/secrets/<postgres_passwd_file> -d quay.io/ibmz/postgres:xx
```

Currently, this is only supported for `POSTGRES_INITDB_ARGS`, `POSTGRES_PASSWORD`, `POSTGRES_USER`, and `POSTGRES_DB`.

## Where to Store Data

**NOTE:** On ZCX, it is recommended that you use Docker Volumes to maintain the data used by postgres:

-	Let Docker manage the storage of your database data [by writing the database files to disk on the host system using its own internal volume management](https://docs.docker.com/engine/tutorials/dockervolumes/#adding-a-data-volume). This is the default and is easy and fairly transparent to the user. The downside is that the files may be hard to locate for tools and applications that run directly on the host system, i.e. outside containers.

Create a volume, create a data directory, mount this volume in a temporary container to fill with contents from host (/data/*). Content should persist.
```console
$ docker run -d --rm --name temp -v <your_volume>:/root/ quay.io/ibm/alpine:3.12 tail -f /dev/null
$ docker cp data/. temp:/root
$ docker stop temp
```
Start your `postgres` container like this:

```console
$ docker run --name some-postgres -v <your_volume>:/var/lib/postgresql/data -e POSTGRES_PASSWORD=mysecretpassword -d quay.io/ibm/postgres:xx
```

The `-v <your_volume>:/var/lib/postgresql/data` part of the command mounts your (volume)data directory from the underlying host system as `/var/lib/postgresql/data` inside the container, where PostgreSQL by default will write its data files.


## Initialization scripts

If you would like to do additional initialization in an image derived from this one, add one or more `*.sql`, `*.sql.gz`, or `*.sh` scripts under `/docker-entrypoint-initdb.d` (creating the directory if necessary). After the entrypoint calls `initdb` to create the default `postgres` user and database, it will run any `*.sql` files, run any executable `*.sh` scripts, and source any non-executable `*.sh` scripts found in that directory to do further initialization before starting the service.

**Warning**: scripts in `/docker-entrypoint-initdb.d` are only run if you start the container with a data directory that is empty; any pre-existing database will be left untouched on container startup. One common problem is that if one of your `/docker-entrypoint-initdb.d` scripts fails (which will cause the entrypoint script to exit) and your orchestrator restarts the container with the already initialized data directory, it will not continue on with your scripts.

For example, to add an additional user and database, add the following to `/docker-entrypoint-initdb.d/init-user-db.sh`:

```bash
#!/bin/bash
set -e

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
	CREATE USER docker;
	CREATE DATABASE docker;
	GRANT ALL PRIVILEGES ON DATABASE docker TO docker;
EOSQL
```

These initialization files will be executed in sorted name order as defined by the current locale, which defaults to `en_US.utf8`. Any `*.sql` files will be executed by `POSTGRES_USER`, which defaults to the `postgres` superuser. It is recommended that any `psql` commands that are run inside of a `*.sh` script be executed as `POSTGRES_USER` by using the `--username "$POSTGRES_USER"` flag. This user will be able to connect without a password due to the presence of `trust` authentication for Unix socket connections made inside the container.

# Arbitrary `--user` Notes

The main caveat to note is that `postgres` doesn't care what UID it runs as (as long as the owner of `/var/lib/postgresql/data` matches), but `initdb` *does* care (and needs the user to exist in `/etc/passwd`):

```console
$ docker run -it --rm --user www-data -e POSTGRES_PASSWORD=mysecretpassword quay.io/ibm/postgres:xx
The files belonging to this database system will be owned by user "www-data".
...

$ docker run -it --rm --user 1000:1000 -e POSTGRES_PASSWORD=mysecretpassword quay.io/ibm/postgres:xx
initdb: could not look up effective user ID 1000: user does not exist
```
# License

View [license information](https://www.postgresql.org/about/licence/) for the software contained in this image.

As with all Docker images, these likely also contain other software which may be under other licenses (such as Bash, etc from the base distribution, along with any direct or indirect dependencies of the primary software being contained).

Some additional license information which was able to be auto-detected might be found in [the `repo-info` repository's `postgres/` directory](https://github.com/docker-library/repo-info/tree/master/repos/postgres).

As for any pre-built image usage, it is the image user's responsibility to ensure that any use of this image complies with any relevant licenses for all software contained within.
