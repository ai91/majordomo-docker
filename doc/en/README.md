# Quick Start
[Quick install from scratch](firststart.md)

[Technical Description and Advanced Examples](advanced.md)

[Migrating an Existing System](migration.md)

# Description
This image is based on the official php:xxx-apache and supports the following architectures: `386`, `amd64`, `arm/v5`, `arm/v7`, `arm64`, `s390x`, `ppc64le`, `mips64le`.

Builds with php7 and php8 are currently available.

You will need to have [docker](https://docs.docker.com/engine/)/[docker compose](https://docs.docker.com/compose/install/) installed to use them.

The `majordomo-docker` image contains the php virtual machine, apache web server and [MajorDoMo](https://github.com/sergejey/majordomo) core. 
What is not included in the image: mysql database, all sorts of additional software to work with various IoT protocols. This means that mysql, mosquitto, and other network resources must be available either on the local network, on the host machine, or in neighboring docker containers. All examples are given using Docker containers.

Since `majordomo-docker` contains the latest version of the `MajorDoMo` kernel (at the time of building), there are two ways to update MajorDoMo:
- Update the docker image tag (use either the `:latest` tag or the tag with a specific version)
- Updating via the MajorDoMo control panel. In this method, to prevent the MajorDoMo version from rolling back when the container is restarted, you need to add additional parameters to the environment variables. See [advanced examples](advanced.md) for more details.

A list of available tags can be found at [docker-hub](https://hub.docker.com/r/ai91/majordomo-docker/tags).
- Stable versions:
  - `:latest` is the latest master version, based on `php:7.4.33-apache`.
  - `:latest_php8` - latest master version, based on `php:8.4.12-apache`.
  - `:latest_php7` - latest master version, based on `php:7.4.33-apache`.
  - `:master_XXXXXX_php8` - XXXXXX master versions, based on `php:8.4.12-apache`.
  - `:master_XXXXXX_php7` - Master versions of XXXXXX, based on `php:7.4.33-apache`.
- Alpha versions:
  - `:alpha` - latest alpha version, based on `php:7.4.33-apache`.
  - `:alpha_php8` - latest alpha release, based on `php:8.4.12-apache`.
  - `:alpha_php7` - latest alpha release, based on `php:7.4.33-apache`.
  - `:alpha_XXXXXX_php8` - alpha versions of XXXXXX, based on `php:8.4.12-apache`.
  - `:alpha_XXXXXX_php7` - Alpha versions of XXXXXX, based on `php:7.4.33-apache`.
