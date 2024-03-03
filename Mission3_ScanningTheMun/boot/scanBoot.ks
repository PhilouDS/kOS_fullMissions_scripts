wait until ship:unpacked.

set terminal:width to 45.
set terminal:height to 26.

wait 0.
core:part:getModule("kOSProcessor"):doEvent("Open Terminal").

clearScreen.
wait 0.5.

if ship:body:name = "Mun" {
  print "Scanning the Mun.".
  print " ".
  print "Ship above the biome ~ " + addons:scansat:currentbiome() + " ~.".
  print " ".
  print "AltimetryHiRes: " + round(addons:scansat:GETCOVERAGE(ship:body,"AltimetryHiRes"),1) + " % scanned".
  print "         Biome: " + round(addons:scansat:GETCOVERAGE(ship:body,"Biome"),1) + " % scanned".
}
else {
  runOncePath("0:/missions/munScan.ks").
}
