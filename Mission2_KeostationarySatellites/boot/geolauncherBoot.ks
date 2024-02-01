wait until ship:unpacked.

set terminal:width to 45.
set terminal:height to 26.

core:part:getModule("kOSProcessor"):doEvent("Open Terminal").

clearScreen.
wait 0.5.

if ship:status <> "Orbiting" {
cd("0:/lib").

list files in myFiles.

local nbFiles is myFiles:length.
local perc is 100 / nbFiles.
print nbFiles + " files found..." at (0,0).
wait 0.2.


for f in myFiles {
  print "loading file " + f:name + "                       " at (0,2).
  local progress is (myFiles:indexOf(f) + 1)*perc.
  print round(progress, 2) + "% / 100%     " at (0,3).
  loadLibrary(f).
  wait 0.2.
}

print "All files loaded." at (0,5).
print "Starting main program." at (0,6).

if not exists("1:/geoSat_launcher.ks") {
    copyPath("0:/missions/geoSat_launcher.ks", "1:/geoSat_launcher.ks").
  }

wait 0.5.
clearScreen.
}

set actualSituation to ship:status.

kUniverse:quicksaveto("geosat_" + actualSituation).

switch to 1.
runPath("geoSat_launcher.ks").

function loadLibrary {
  parameter aFile.
  local completePath is "1:/lib/" + aFile.
  if not exists(completePath) {
    copyPath("0:/lib/" + aFile, completePath).
  }
  wait 0.1.
}
