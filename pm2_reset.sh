#!/bin/bash
rm -rf ./nodes/1
rm -rf ./nodes/2
rm -rf ./nodes/3
rm -rf ./nodes/4
rm -rf ./nodes/5
docker exec -it dba304a6565c mongo --eval "db.dropDatabase()" tomodex
pm2 stop all && pm2 delete -f all
