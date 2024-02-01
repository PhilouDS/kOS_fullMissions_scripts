wait 1.

print core:tag + " ready and waiting".
wait 1.
core:part:getModule("kOSProcessor"):doEvent("Close Terminal").

wait until ship:mass < 1.