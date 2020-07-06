# Preparing images

This briefly describes how we prepared the images to be used in our implementation.
Pre-configured archives of images we used can be found at [releases](https://github.com/blead/live-migration/releases/).

## Prerequisites

- [Docker](https://docs.docker.com/get-docker/)
- [Skopeo](https://github.com/containers/skopeo/blob/master/install.md)
- [umoci](https://github.com/opencontainers/umoci)

## Steps

In this example we will use MySQL and WordPress images.

1. Pull Docker images.

```sh
docker pull mysql:5.7 && docker pull wordpress:latest
```

2. Use Skopeo to copy images from Docker daemon to local OCI directory.

```sh
skopeo --insecure-policy copy docker-daemon:mysql:5.7 oci:mysql:5.7
skopeo --insecure-policy copy docker-daemon:wordpress:latest oci:wordpress:5.0.3
```

3. Use umoci to unpack the images.

```sh
umoci unpack --image mysql:5.7 mysql
umoci unpack --image wordpress:5.0.3 wordpress
```

4. Edit `config.json` in each directory to add volumes, environment variables, and network namespaces.

- `"terminal": false`
- `{ "destination": "/var/lib/mysql", "type": "bind", "source": "rootfs/var/lib/mysql", "options": ["rw", "rbind", "rprivate"] }`
- `{ "type":"network", "path":"/run/netns/<ns name>" }`
- `"MYSQL_ROOT_PASSWORD=criu", "MYSQL_DATABASE=criu", "MYSQL_USER=criu", "MYSQL_PASSWORD=criu"` (mysql)
- `"WORDPRESS_DB_HOST=vpeermysql:3306", "WORDPRESS_DB_USER=criu", "WORDPRESS_DB_PASSWORD=criu", "WORDPRESS_DB_NAME=criu"` (wordpress)

5. The directories are ready to be used as OCI images. An additional step we did was using `tar` to create archives of images to be moved around.
