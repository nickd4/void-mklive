#!/bin/bash

# note: we cannot use $HOME/xbps/usr/bin:$PATH in the below, as it would be
# expanded as user Nick before the sudo command has set the user root's path

sudo rm -rf xbps-cache
sudo sh -c "PATH=$HOME/xbps/usr/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin ./mkrootfs.sh -r $HOME/src/void-packages/hostdir/binpkgs x86_64-musl"
