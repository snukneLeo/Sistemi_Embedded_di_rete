#!/bin/bash

sent=$(grep "SEND" $1 | wc -l);
received=$(grep "RECEIVE" $1 | wc -l);

lost=$(bc -l <<< $sent-$received);
PLR=$(bc -l <<< $lost/$sent);
PLR=$(bc -l <<< $PLR*100);
echo "PLR = $PLR %";
