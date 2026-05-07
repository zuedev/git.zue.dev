# git.zue.dev

> Server configuration for my git server, powered by Docker.

## Abstract

This repository contains the necessary configuration files and instructions to set up an opinionated self-hosted git server using Docker. The server is designed to be secure, efficient, and easy to manage, allowing users to host their git repositories without relying on third-party services.

## Development

To start the development environment, run the following command:

```bash
docker compose -f docker-compose.dev.yaml up --build --remove-orphans --watch
```
