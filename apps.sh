#!/bin/bash
_interupt() { 
    echo "Shutdown $child_proc"
    kill -TERM $child_proc
    exit
}

TOMOSCAN_PROJECT_DIR="${HOME}/projects/tomoscan"
TOMOMASTER_PROJECT_DIR="${HOME}/projects/tomomaster"

cd $TOMOSCAN_PROJECT_DIR/client && PORT=3002 npm run dev &
child_proc="$child_proc $!"

cd $TOMOSCAN_PROJECT_DIR/server && npm run server-dev &
child_proc="$child_proc $!"
cd $TOMOSCAN_PROJECT_DIR/server && npm run crawl-dev &
child_proc="$child_proc $!"
cd $TOMOSCAN_PROJECT_DIR/server && npm run subscribe-pending-tx-dev &
child_proc="$child_proc $!"

cd $TOMOMASTER_PROJECT_DIR && npm run client-dev &
child_proc="$child_proc $!"
cd $TOMOMASTER_PROJECT_DIR && npm run crawl-dev &
child_proc="$child_proc $!"
cd $TOMOMASTER_PROJECT_DIR && npm run server-dev
