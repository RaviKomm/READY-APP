#!/usr/bin/env bash
TARGET="http://localhost:8000/health"
hey -n 50 -c 10 "$TARGET"
