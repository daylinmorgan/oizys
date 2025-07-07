#!/usr/bin/env bash

restic \
  backup \
  -r rclone:g:thinkbak \
  --exclude-file "$HOME/.config/restic/excludes.txt" \
  --exclude-file "$HOME/.conda/environments.txt" \
  --verbose \
  "$HOME"
