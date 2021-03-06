#!/bin/bash

export TMPDIR=/tmp
export FAUCET_CONFIG=$TMPDIR/faucet.yaml
export FAUCET_LOG=$TMPDIR/faucet.log
export FAUCET_EXCEPTION_LOG=$TMPDIR/faucet_exception.log

cat >$FAUCET_CONFIG <<EOC
dps:
  ovs:
    dp_id: 0x1
    hardware: Open vSwitch
    interfaces:
        0xfffffffe:
            native_vlan: 100
            opstatus_reconf: false
    interface_ranges:
        1-10:
            native_vlan: 100
EOC

/usr/local/bin/faucet --version || exit 1
nohup /usr/local/bin/faucet &
FAUCETPID=$!

while true ; do
	wget -q -O/dev/null localhost:9302
	if [ $? -eq 0 ] ; then break ; fi
	echo waiting for faucet...
	sleep 1
done

docker-compose build && docker-compose up -d || exit 1
docker network create testnet -d ovs -o ovs.bridge.mode=nat -o ovs.bridge.dpid=0x1 -o ovs.bridge.controller=tcp:127.0.0.1:6653 || exit 1
# github test runner can't use ping.
docker run -t --net=testnet --rm busybox wget -q -O- bing.com || exit 1
docker network rm testnet || exit 1
docker-compose stop

kill $FAUCETPID
