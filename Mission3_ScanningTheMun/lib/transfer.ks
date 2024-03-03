runOncePath("0:/lib/launch.ks").
runOncePath("0:/lib/mnv.ks").

global function transferToBody{
  parameter targetBody.
  parameter doWarp is false.
  set target to targetBody.

  local targetAngle is 180 - computeTargetAngle(target).
  lock phaseAngle to computePhaseAngle(target).
  
  until abs(targetAngle - phaseAngle) < 30 {
    set warp to 3.
    print ("Target angle: ") + round(targetAngle, 2) + ("°") at (0,8).
    print (" Phase angle: ") + round(phaseAngle, 2) + ("°") at (0,9).
    wait 0.1.
  }
  set warp to 0.
  wait until kuniverse:timewarp:rate = 1.

  local deltaAngle is abs(targetAngle - phaseAngle).
  local deltaTime is deltaAngle * ship:orbit:period / 360.
  clearScreen.

  local deltaV is hTrans(ship:altitude, targetBody:orbit:apoapsis - targetBody:radius - 30000).
  add node(time:seconds + deltaTime, 0, 0, deltaV).
  
  exeMnv().

  if orbit:nextpatch:periapsis < 2000 {
    lock steering to retrograde.
    set canStage to false.
    local lim is max(0.5, abs(orbit:nextpatch:periapsis/50_000)).
    limitThrust(lim).
    wait 0.
    wait until vAng(ship:facing:vector, retrograde:vector) < 1.
    until orbit:nextpatch:periapsis > 10000 {
      lock throttle to 1.
    }
  }
  lock throttle to 0.
  limitThrust(100).
  set canStage to true.

  wait 2.

  if doWarp {
    warpto(time:seconds + ETA:transition + 120).
    wait until kuniverse:timewarp:rate = 1.
  }
}

function computeTargetAngle {
  parameter targetBody.
  local nextPe is ship:apoapsis.
  local semiMajorAxis is (body:radius + nextPe + body:radius + targetBody:orbit:apoapsis) / 2.
  local semiPeriod is constant:pi * sqrt(semiMajorAxis^3 / body:mu).
  local targetBodyPeriod is targetBody:orbit:period.
  return semiPeriod * 360 / targetBodyPeriod.  
}

function computePhaseAngle {
  parameter targetBody.
  
  local shipAngle is vernalAngle().
  local targetAngle is vernalAngle(targetBody).

  local diffAngle is targetAngle - shipAngle.
  return diffAngle - 360 * floor(diffAngle/360).
}

function vernalAngle {
  parameter Obj is ship.
  local angle is Obj:orbit:lan + Obj:orbit:argumentofperiapsis + Obj:orbit:trueanomaly.
  return angle - 360*floor(angle / 360).
}