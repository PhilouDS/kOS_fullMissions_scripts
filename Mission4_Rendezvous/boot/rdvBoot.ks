wait until ship:unpacked.

set terminal:width to 45.
set terminal:height to 26.

wait 0.
core:part:getModule("kOSProcessor"):doEvent("Open Terminal").

clearScreen.
wait 0.5.

runOncePath("0:/missions/rdv.ks").
