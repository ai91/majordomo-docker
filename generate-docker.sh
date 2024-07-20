#!/usr/bin/env bash
set -Eeuo pipefail

envsubst < Dockerfile.template > Dockerfile