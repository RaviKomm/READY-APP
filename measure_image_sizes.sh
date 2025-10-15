#!/usr/bin/env bash
echo "Image sizes:"
docker images --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}"
