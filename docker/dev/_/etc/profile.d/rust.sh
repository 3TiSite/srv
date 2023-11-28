#!/usr/bin/env bash
export CARGO_HOME=/opt/rust
export RUSTUP_HOME=$CARGO_HOME

[ -f "/opt/rust/env" ] && source /opt/rust/env
