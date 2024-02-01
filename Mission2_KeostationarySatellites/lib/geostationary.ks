function geoAltitude {
  parameter nameOfBody.
  local bodyMass is body(nameOfBody):mass.
  local bodyRadius is body(nameOfBody):radius.
  local bodyRotationPeriod is body(nameOfBody):rotationPeriod.
  return ((constant:G * bodyMass * (bodyRotationPeriod^2))/(4 * (constant:pi)^2))^(1/3) - bodyRadius.
}

function geoVelocity {
  parameter nameOfBody.
  local wantedAlt is body(nameOfBody):radius + geoAltitude(nameOfBody).
  return (2 * constant:pi * wantedAlt)/(body(nameOfBody):rotationPeriod).
}

function geoPhase {
  parameter nameOfBody.
  parameter phase is 2/3.
  local wantedPeriod is phase * body(nameOfBody):rotationPeriod.
  local SMA is body(nameOfBody):mu^(1/3) * (wantedPeriod / (2 * constant:pi))^(2/3).
  local theApo is geoAltitude(nameOfBody) + body(nameOfBody):radius.
  return 2 * SMA - theApo - body(nameOfBody):radius.
}