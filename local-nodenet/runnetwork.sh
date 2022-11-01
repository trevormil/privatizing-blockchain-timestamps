sudo ls;
sudo rm -rf blkchain*
geth --datadir blkchain1 init genesis.json;
geth --datadir blkchain2 init genesis.json;
geth --datadir blkchain3 init genesis.json;
geth --datadir blkchain4 init genesis.json;
geth --datadir blkchain5 init genesis.json;
geth --datadir blkchain6 init genesis.json;
geth --datadir blkchain7 init genesis.json;
geth --datadir blkchain8 init genesis.json;
geth --datadir blkchain9 init genesis.json;
geth --datadir blkchain10 init genesis.json;

# geth --datadir blkchain1 --nodiscover --networkid 12345 --verbosity 3 console
# geth --datadir blkchain2 --nodiscover --networkid 12345 --port 30304 --authrpc.port 8552 --verbosity 3 console
# geth --datadir blkchain3 --nodiscover --networkid 12345 --port 30305 --authrpc.port 8553 --verbosity 3 console
# geth --datadir blkchain4 --nodiscover --networkid 12345 --port 30306 --authrpc.port 8554 --verbosity 3 console
# geth --datadir blkchain5 --nodiscover --networkid 12345 --port 30307 --authrpc.port 8555 --verbosity 3 console
# geth --datadir blkchain6 --nodiscover --networkid 12345 --port 30308 --authrpc.port 8556 --verbosity 3 console
# geth --datadir blkchain7 --nodiscover --networkid 12345 --port 30309 --authrpc.port 8557 --verbosity 3 console
# geth --datadir blkchain8 --nodiscover --networkid 12345 --port 30310 --authrpc.port 8558 --verbosity 3 console
# geth --datadir blkchain9 --nodiscover --networkid 12345 --port 30311 --authrpc.port 8559 --verbosity 3 console
# geth --datadir blkchain10 --nodiscover --networkid 12345 --port 30312 --authrpc.port 8560 --verbosity 3 console