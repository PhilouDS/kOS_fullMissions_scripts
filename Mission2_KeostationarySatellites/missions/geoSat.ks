runOncePath("lib/system.ks").
runOncePath("lib/mnv.ks").
runOncePath("lib/launch.ks").
runOncePath("lib/geostationary.ks").

wait 1.

print core:tag + " ready and waiting".
wait 1.
core:part:getModule("kOSProcessor"):doEvent("Close Terminal").

local finalPeriod is body("Kerbin"):rotationPeriod.

wait until ship:mass < 1.

if ship:orbit:period >= 0.99 * finalPeriod {
  clearScreen.
  print "Satellite in position.".
}
else {
  local motherShip is "full-mission-2".
  set kuniverse:activevessel to ship.
  wait until kuniverse:activevessel = ship.
  core:part:getModule("kOSProcessor"):doEvent("Open Terminal").

  wait 0.5.
  rcs off.
  sas off.
  print " ".
  print ship:name + " deployed and active.".
  wait 0.5.
  print "Going to position.".
  print " ".

  goToFrom(ship:orbit:apoapsis, "AP").
  wait 1.
  exeMnv().
  wait 0.5.

  if ship:orbit:period > finalPeriod {
    lock steering to retrograde.
    wait until vAng(ship:facing:vector, retrograde:vector) < 2.5.
    rcs on.
    until ship:orbit:period <= finalPeriod {
      set ship:control:fore to 0.5.
    }
  }
  else {
    lock steering to prograde.
    wait until vAng(ship:facing:vector, prograde:vector) < 2.5.
    rcs on.
    until ship:orbit:period >= finalPeriod {
      set ship:control:fore to 0.5.
    }
  }
  rcs off.

  wait 0.5.

  lock steering to body:position.
  wait until vAng(ship:facing:vector, body:position) < 2.5.
  wait 1.
  unlock steering.
  sas on.
  set ship:control:pilotMainThrottle to 0.
  local antList is list().
  for part in ship:parts {if part:TAG = "antenna" {antList:add(part).}}
  for part in antList {
    part:getModule("ModuleDeployableAntenna"):doEvent("extend antenna").
  }
  hudText("Antenna extended", 1, 2, 30, rgb(1,1,0.5), false).
  print ship:name + " in position and fully operational.".
  wait 1.

  core:part:getModule("kOSProcessor"):doEvent("Close Terminal").

  kuniverse:forceActive(vessel(motherShip)).
}