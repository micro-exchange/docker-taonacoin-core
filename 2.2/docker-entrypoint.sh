#!/bin/sh
set -e

if [ $(echo "$1" | cut -c1) = "-" ]; then
  echo "$0: assuming arguments for taonad"

  set -- taonad "$@"
fi

if [ $(echo "$1" | cut -c1) = "-" ] || [ "$1" = "taonad" ]; then
  mkdir -p "$TAONACOIN_DATA"
  chmod 700 "$TAONACOIN_DATA"
  chown -R taona "$TAONACOIN_DATA"

  echo "$0: setting data directory to $TAONACOIN_DATA"

  set -- "$@" -datadir="$TAONACOIN_DATA"
fi

if [ "$1" = "taonad" ] || [ "$1" = "taona-cli" ] || [ "$1" = "taona-tx" ]; then
  echo
  exec su-exec taona "$@"
fi

echo
exec "$@"