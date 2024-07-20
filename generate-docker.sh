#!/usr/bin/env bash
set -Eeuo pipefail

gawk -f "$jqt" Dockerfile.template > Dockerfile