set dotenv-load

RELEASE_DIR := "release"

alias r := run
alias t := test_all

_default:
  @just -l

# runs the cli
run:
  cargo r

# removes the release directory and cargo cleans
clean:
  rm -r {{RELEASE_DIR}}
  cargo clean
  rm -r utd_web/pkg

# creates the release directory
_release_dir:
  mkdir -p {{RELEASE_DIR}}

# build all the crates for windows
release_windows: _release_dir
  just release x86_64-pc-windows-msvc utd_cli utd_c.exe
  just release x86_64-pc-windows-msvc utd_cli utd_t.exe
  just release x86_64-pc-windows-msvc utd_server utd_server.exe
  just release x86_64-pc-windows-msvc utd_pc utd_pc.exe
  just release_python

# build all the crates for linux
release_linux: _release_dir
  just release x86_64-unknown-linux-gnu utd_cli utd_c
  just release x86_64-unknown-linux-gnu utd_cli utd_t
  just release x86_64-unknown-linux-gnu utd_server utd_server
  just release x86_64-unknown-linux-gnu utd_pc utd_pc
  just release_python

# general release recipe
release platform project binary_name: _release_dir
  cargo build --release --package {{project}} --target {{platform}}
  cp target/{{platform}}/release/{{binary_name}} {{RELEASE_DIR}}

# build utd_web
release_web: _release_dir
  #!/bin/env bash
  cd utd_web
  wasm-pack build --release --target web
  cd ..
  mkdir -p {{RELEASE_DIR}}/utd_web
  cp utd_web/index.html {{RELEASE_DIR}}/utd_web/index.html
  cp -r utd_web/pkg {{RELEASE_DIR}}/utd_web/pkg
  
# build utd_android
release_android: _release_dir
  #!/bin/env bash
  cd utd_android
  x build -r --platform android --arch arm64 --format apk
  cd ..
  cp target/x/release/android/utd_android.apk {{RELEASE_DIR}}

# build python library
release_python: _release_dir
  maturin build -m utd-lib-python/Cargo.toml
  cp target/wheels/* release

# build all the crates for linux and windows
release_all: release_linux release_windows

# compress with tar.xz files
compress_release: _release_dir
  #!/bin/env bash
  cd {{RELEASE_DIR}}
  for el in *; do tar cvf "${el}.tar.xz" -I 'xz -9e' "$el" && rm -r "$el"; done
  for el in *; do sha256sum "$el" > "$el.sha256" ; done

# test project
test project:
  cargo test --package {{project}}

# test all the crates
test_all:
  just test utd_cli
  just test utd_server
  just test utd_lib
  just test utd_android
  just test utd_web
  just test utd_pc
