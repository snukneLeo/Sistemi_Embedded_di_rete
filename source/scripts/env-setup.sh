#!/bin/bash

##################################################
# Simple script to easily export env vars.
##################################################
# @author Francesco Stefanni

#### Settings:

SYSTEMC_DIR=/usr/local/systemc-2.3.0/

#### Exporting:

if [ "$#" == "0" ]; then
    # 32
    export PATH=$PATH:$SYSTEMC_DIR/include:$SYSTEMC_DIR/lib-linux64
elif [ "$1" == "32" ]; then
    # 32
    export PATH=$PATH:$SYSTEMC_DIR/include:$SYSTEMC_DIR/lib-linux
else
    # 64
    export PATH=$PATH:$SYSTEMC_DIR/include:$SYSTEMC_DIR/lib-linux64
fi
#### Showing the new Path:

echo "PATH = $PATH"
