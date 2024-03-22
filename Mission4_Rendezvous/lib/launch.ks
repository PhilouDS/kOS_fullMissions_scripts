global function liftoff {
  parameter count, targetInc.

  sas off. rcs off.
  lock throttle to 1.
  lock steering to heading(90, 90).  // headings(direction, pitch) // direction 90 = Est // pitch 90 = pointe vers le haut

  countdown(count).
  
  stage.
  
  hudText("Liftoff!", 2, 2, 30, rgb(1,0.498,0.208), false).
  
  wait until ship:altitude > 100.
  lock steering to heading(90 - targetInc, 90).
}

function countdown{
    parameter numberOfSeconds.
    print("Countdown started.").
    wait 1.
    from {local myCounter is numberOfSeconds.}
    until myCounter = 0
    step {set myCounter to myCounter - 1. if myCounter = 1 {stage. print("Ignition !").}}
    do {
        hudText(myCounter, 1, 2, 30, rgb(1,0.498,0.208), false).
        wait 1.
    }
}

global function gravityTurn{
  parameter targetAltitude, targetInc.
  parameter startAngle is 85.
  local directionTilt is heading(90 - targetInc, startAngle).
  lock steering to directionTilt.
  hudText("Gravity turn started.", 1, 2, 25, rgb(1,0.498,0.208), false).
  wait until vAng(facing:vector,directionTilt:vector) < 1.
  wait until vAng(srfPrograde:vector, facing:vector) < 1.
  until ship:altitude >= 36000 {
    lock steering to heading(90 - targetInc,90 - vAng(up:vector, srfPrograde:vector)).  
    showInfo(targetAltitude, "Surface").
    wait 0.
  }
  until apoapsis >= 0.98*targetAltitude {
    lock steering to heading(90 - targetInc,90 - vAng(up:vector, Prograde:vector)).
    showInfo(targetAltitude, "Orbital").
    wait 0.
  }
  local throt is max(0.1, 30/ship:maxthrust).
  lock throttle to throt.
  print ("Throttle down to " + round((throt * 100),2) + " %.") at (0,25).
  until apoapsis >= targetAltitude {
    lock steering to heading(90 - targetInc,90 - vAng(up:vector, Prograde:vector)).
    showInfo(targetAltitude, "Orbital").
    wait 0.
  }
  lock throttle to 0.
  print ("MECO.                  ") at (0,25).
  set kuniverse:timewarp:rate to 3.
  until ship:altitude >= ship:body:atm:height {
    lock steering to heading(90 - targetInc,90 - vAng(up:vector, Prograde:vector)).
    showInfo(targetAltitude, "Orbital").
    wait 0.
  }
  clearScreen.
  set kuniverse:timewarp:rate to 1.
}


function showInfo {
    parameter showValue.
    parameter vectorLocked is "Surface".
    parameter N is 2.
    print vectorLocked + (" prograde locked.              ") at (0,N).
    print ("    Actual altitude: ") + round(ship:altitude, 2) + (" m        ") at (0,N+2).
    if vectorLocked = "Surface" {
      print ("   Surface velocity: ") + round(ship:velocity:surface:mag, 2) + (" m/s        ") at (0,N+3).
    }
    else {
      print ("   Orbital velocity: ") + round(ship:velocity:orbit:mag, 2) + (" m/s        ") at (0,N+3).
    }
    print ("Angle above horizon: ") + round(90 - vAng(up:vector, facing:vector), 1) + ("°   ") at (0,N+4).
    print ("    Target apoapsis: ") + round(showValue,2) + (" m") at (0,N+6).
    print ("    Actual apoapsis: ") + round(ship:orbit:apoapsis, 2) + (" m        ") at (0,N+7).
    print ("   Actual periapsis: ") + round(ship:orbit:periapsis, 2) + (" m        ") at (0,N+8).
    wait 0.01.
}

global function triggerStaging{
  global oldThrust is ship:availableThrust.
  global canStage is true.
  print ("Autostage system operational.").
  print " ".
  when ship:availableThrust < oldThrust - 10 AND canStage = true then {
    until false {
      wait until stage:ready.
      stage.
      hudText("STAGE", 1, 2, 30, rgb(1,0.498,0.208), false).
      wait 0.1.
      if ship:maxThrust > 0 or stage:number = 0 { 
        break.
      }
    }
    set oldThrust to ship:availableThrust.
    if stage:number > 1 {preserve.}
  }
}

