function sysCall_init()
    -- This is executed exactly once, the first time this script is executed
    bubbleRobBase = sim.getObjectAssociatedWithScript(sim.handle_self) -- this is bubbleRob's handle
    leftMotor = sim.getObjectHandle("bubbleRob_leftMotor#0") -- Handle of the left motor
    rightMotor = sim.getObjectHandle("bubbleRob_rightMotor#0") -- Handle of the right motor
    noseSensor = sim.getObjectHandle("bubbleRob_sensingNose#0") -- Handle of the proximity sensor
    frontSensor = sim.getObjectHandle("bubbleRob_sensingNose#1") 
    frontRight = sim.getObjectHandle("bubbleRob_frontRightSensor#0")
    rearRight = sim.getObjectHandle("bubbleRob_rearRightSensor#0")
    frontLeft = sim.getObjectHandle("bubbleRob_frontLeftSensor#0")
    rearLeft = sim.getObjectHandle("bubbleRob_rearLeftSensor#0")

    wheelRadius = 0.01
    cellSize = 0.5
    turnSpeed = 0.05
    curveSpeed = 0.05
    bodyDistanceToWheel = 0.1
    distanceToOffcenterKinematicController = 0.2
    wallCorrectionCoefficient = 5

    robotDrivingState = 1 -- 1 is follow wall, 2 is turn and 3 is curve
    direction = "right" -- should follow left or right wall

    distanceBetweenLaserSensors = sim.getObjectPosition(frontRight, -1)[1] - sim.getObjectPosition(rearRight, -1)[1]
    dWallSide = 0.15 -- Distance to keep from wall

    -- left wheel turn speed, right wheel turn speed, minimum turning time
    wTurnL, wTurnR, minTurnTime = precomputeTurn()
    wCurveL, wCurveR, minCurveTime = precomputeCurve()

    robotSpeed = 0.1

    active = false
    moveBackwards = false
end

function sysCall_actuation()
    active = sim.getStringSignal("wakeUp")

    if (active) then
        if(moveBackwards) then
            goBackward()
        else
            goForward()
        end
    end
end

function sysCall_sensing()

    if(active) then

        moveBackwards = sim.readProximitySensor(frontSensor) > 0

        if(not moveBackwards) then 
            rotations()
        end
    end
end

function goBackward()
    local leftMotorSpeed, rightMotorSpeed

    if (robotDrivingState == 1) then
        leftMotorSpeed, rightMotorSpeed = followWall()
    elseif (robotDrivingState == 2) then
        leftMotorSpeed = -wTurnL
        rightMotorSpeed = -wTurnR
    elseif (robotDrivingState == 3) then
        leftMotorSpeed = -wCurveL
        rightMotorSpeed = -wCurveR
    else
        leftMotorSpeed = 0
        rightMotorSpeed = 0
    end
    sim.setJointTargetVelocity(leftMotor, -leftMotorSpeed)
    sim.setJointTargetVelocity(rightMotor, -rightMotorSpeed)
end

function goForward()
    local leftMotorSpeed, rightMotorSpeed

    if (robotDrivingState == 1) then
        leftMotorSpeed, rightMotorSpeed = followWall()
    elseif (robotDrivingState == 2) then
        leftMotorSpeed = wTurnL
        rightMotorSpeed = wTurnR
    elseif (robotDrivingState == 3) then
        leftMotorSpeed = wCurveL
        rightMotorSpeed = wCurveR
    else
        leftMotorSpeed = 0
        rightMotorSpeed = 0
    end
    sim.setJointTargetVelocity(leftMotor, leftMotorSpeed)
    sim.setJointTargetVelocity(rightMotor, rightMotorSpeed)
end

function rotations()
    wallFront = sim.readProximitySensor(noseSensor) > 0
    if (direction == "right") then
        isWallInFront = wallDetected(getDistance(frontRight, 1.21), 0.25, 0.25)
        isWallInRear = wallDetected(getDistance(rearRight, 1.21), 0.25, 0.25)
    else
        isWallInFront = wallDetected(getDistance(frontLeft, 1.21), 0.25, 0.25)
        isWallInRear = wallDetected(getDistance(rearLeft, 1.21), 0.25, 0.25)
    end
    wallSide = isWallInFront and isWallInRear
    if (robotDrivingState == 1) then
        lastTime = sim.getSimulationTime()
        if wallFront then
            robotDrivingState = 2
        end
        if not wallSide then
            robotDrivingState = 3
        end
    elseif (robotDrivingState == 2) then
        local timeElapsed = ((sim.getSimulationTime() - lastTime) > minTurnTime)
        if (timeElapsed) then
            print("Is turning done?", timeElapsed)
        end
        if (wallSide and timeElapsed) then
            robotDrivingState = 1
        end
    elseif (robotDrivingState == 3) then
        local timeElapsed = ((sim.getSimulationTime() - lastTime) > minCurveTime)
        if (timeElapsed) then
            print("Is curving done?", timeElapsed)
        end
        if (wallFront) then
            robotDrivingState = 1
        end
        if (wallSide and timeElapsed) then
            robotDrivingState = 1
        end
    end
end

function getDistance(sensor, maxDistance)
    local detected, distance
    detected, distance = sim.readProximitySensor(sensor)
    if (detected < 1) then
        distance = maxDistance
    end
    return distance
end

function followWall()
    dFR = getDistance(frontRight, 0.5)
    dRR = getDistance(rearRight, 0.5)
    dFL = getDistance(frontLeft, 0.5)
    dRL = getDistance(rearLeft, 0.5)
    local phi, d, alpha, gamma, wL, wR
    if (direction == "right") then
        phi = math.atan((dFR - dRR) / distanceBetweenLaserSensors)
        d = 0.5 * (dFR + dRR) - dWallSide
    else
        phi = math.atan((dRL - dFL) / distanceBetweenLaserSensors)
        d = dWallSide - 0.5 * (dFL + dRL)
    end
    gamma = wallCorrectionCoefficient * d
    alpha = phi + gamma
    wL = (robotSpeed / wheelRadius) * (math.cos(alpha) + (bodyDistanceToWheel / distanceToOffcenterKinematicController) * math.sin(alpha))
    wR = (robotSpeed / wheelRadius) * (math.cos(alpha) - (bodyDistanceToWheel / distanceToOffcenterKinematicController) * math.sin(alpha))
    return wL, wR
end

function wallDetected(distance, expectedDistance, tolerance)
    return math.abs(distance - expectedDistance) < tolerance
end

function precomputeTurn()
    local wL, wR, t, sign
    if (direction == "right") then
        sign = 1
    else
        sign = -1
    end
    wL = -sign * turnSpeed / wheelRadius
    wR = sign * turnSpeed / wheelRadius
    -- 0.1 * 90 / 0.01 = 15.7
    t = cellSize / 2 * (bodyDistanceToWheel * math.pi / 2) / turnSpeed
    return wL, wR, t
end

function precomputeCurve()
    if (direction == "right") then
        sign = 1
    else
        sign = -1
    end
    local wref, wL, wR, t
    wref = curveSpeed / (cellSize / 2)
    wL = (curveSpeed + bodyDistanceToWheel * sign * wref) / wheelRadius
    wR = (curveSpeed - bodyDistanceToWheel * sign * wref) / wheelRadius
    t = (cellSize / 2 * math.pi / 2) / wref
    return wL, wR, t
end