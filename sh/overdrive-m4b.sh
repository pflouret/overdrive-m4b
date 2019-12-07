#!/bin/bash

cwd=`readlink -f .`
dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
cd "$cwd/.."

RBENV_VERSION=2.3.1 rbenv exec ruby "$dir/bin/overdrive-m4b" "$@"
