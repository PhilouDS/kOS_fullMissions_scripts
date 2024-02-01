global function computeVelocity {
  parameter per, apo, shipAlt.
  local bMu is ship:body:mu.
  local bRadius is ship:body:radius.
  local SA is shipAlt + bRadius.
  local RP is bRadius + per.
  local RA is bRadius + apo.
  local SMA is (RP + RA) / 2.

  return sqrt(bMu * (2 / SA - 1 / SMA)).
}

global function hTrans {
  parameter shipAlt, targetAlt.
  local initialVel is 0.
  local finalVel is 0.
  local deltaVneeded is 0.

  set initialVel to computeVelocity(ship:orbit:periapsis, ship:orbit:apoapsis, shipAlt).
  if shipAlt < targetAlt {
    set finalVel to computeVelocity(shipAlt, targetAlt, shipAlt).
  }
  else {
    set finalVel to computeVelocity(targetAlt, shipAlt, shipAlt).
  }

  set deltaVneeded to finalVel - initialVel.

  print "---".
  print "initial vel: " + round(initialVel, 2) + " m/s ".
  print "  final vel: " + round(finalVel, 2) + " m/s ".
  print "    delta-v: " + round(deltaVneeded, 5) + " m/s ".
  print "---".

  return deltaVneeded.
}

global function goToFrom {
  parameter targetAlt.
  parameter fromAlt is "AP".
  local newDV is 0.
  local newNode is node(0,0,0,0).

  if fromAlt = "AP" {
    set newDV to hTrans(ship:orbit:apoapsis, targetAlt).
    set newNode to node(time:seconds + ETA:apoapsis, 0, 0, newDV).
  }
  else {
    set newDV to hTrans(ship:orbit:periapsis, targetAlt).
    set newNode to node(time:seconds + ETA:periapsis, 0, 0, newDV).
  }
  add newNode.
}


global function exeMnv { 
  parameter deltaTime is 20. 
  if hasNode {
    set myNode to nextNode.
    set tset to 0.
    lock throttle to tset.

    set max_acc to ship:maxthrust/ship:mass.
    set burn_duration to myNode:deltav:mag/max_acc.

    kuniverse:timewarp:warpto(time:seconds + myNode:ETA - burn_duration/2 - deltaTime).
    wait until kuniverse:timewarp:issettled.

    lock steering to myNode:deltav.
    wait until vAng(ship:facing:vector, myNode:deltaV) < 1.

    until myNode:eta <= (burn_duration/2)
      {print "Maneuver in: " + round(myNode:ETA - burn_duration/2, 2) + " s      " at (0,2).}

    set done to False.
    //initial deltav
    set dv0 to myNode:deltav.
    until done
    {
      set max_acc to ship:maxthrust/ship:mass.
      set tset to min(myNode:deltav:mag/max_acc, 1).
      if vdot(dv0, myNode:deltav) < 0
      {
          print "End burn, remain dv " + round(myNode:deltav:mag,1) + "m/s, vdot: " + round(vdot(dv0, myNode:deltav),1).
          lock throttle to 0.
          break.
      }
      if myNode:deltav:mag < 0.1
      {
          print "Finalizing burn".
          wait until vdot(dv0, myNode:deltav) < 0.5.

          lock throttle to 0.
          print "End burn".
          set done to True.
      }
    }
  wait 0.
  remove myNode.
  }
  else {
    print("No existing maneuver").
  }

  unlock steering.
  unlock throttle.
  wait 0.
  set ship:control:pilotMainThrottle to 0.
}

global function limitThrust {
  parameter perc.
  for eng in ship:engines {
    if eng:stage = stage:number {set eng:thrustLimit to perc.}
  }
  print ("Thrust power at ") + perc + (" %.            ") at (0,25).
}