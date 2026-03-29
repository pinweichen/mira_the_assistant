#!/bin/bash
cd "$(dirname "$0")"
exec claude --channels plugin:discord@claude-plugins-official {{SKIP_PERMISSIONS_FLAG}}
