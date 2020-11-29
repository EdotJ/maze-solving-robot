function sysCall_init()
    -- This is executed exactly once, the first time this script is executed
    bubbleRobBase = sim.getObjectAssociatedWithScript(sim.handle_self) -- this is bubbleRob's handle
    leftMotor = sim.getObjectHandle("bubbleRob_leftMotor") -- Handle of the left motor
    rightMotor = sim.getObjectHandle("bubbleRob_rightMotor") -- Handle of the right motor
    noseSensor = sim.getObjectHandle("bubbleRob_sensingNose") -- Handle of the proximity sensor
    frontRight = sim.getObjectHandle("bubbleRob_frontRightSensor")
    rearRight = sim.getObjectHandle("bubbleRob_rearRightSensor")
    frontLeft = sim.getObjectHandle("bubbleRob_frontLeftSensor")
    rearLeft = sim.getObjectHandle("bubbleRob_rearLeftSensor")
    backSensor = sim.getObjectHandle("bubbleRob_backSensor")

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
    desiredOrientation = 0
    isRotating = false
    doorsUnlocked = false
    hostageLost = false
    active = true

    xml =
        '<ui title="' ..
        sim.getObjectName(bubbleRobBase) ..
            ' parameters" closeable="false" resizeable="false" activate="false">' ..
        [[
            <label text="Robot speed: ]] .. robotSpeed .. [["/>
            <label text="Turn Speed: ]] .. turnSpeed .. [["/>
            <label text="Curve Speed: ]] .. curveSpeed .. [["/>
            <label text="Distance between lasers: ]] .. distanceBetweenLaserSensors .. [["/>
            <label text="Turning parameters: ]] .. wTurnL .. " " .. wTurnR .. " " .. minTurnTime .. "s" .. [["/>
            <label text="Curving parameters: ]] .. wCurveL .. " " .. wCurveR .. " " .. minCurveTime .. "s" .. [["/>
            <label text="" style="* {margin-left: 300px;}"/>
        </ui>
        ]]
        print(xml)
    ui = simUI.create(xml)
    simUI.setPosition(ui, 1500, 500)

end

function sysCall_actuation()

    local shouldIUnlcokDoors = sim.getStringSignal("unlockDoors")

    if(shouldIUnlcokDoors == "true" and not doorsUnlocked) then
        if(not isRotating) then
            turnAround()
        end
        rotate()
        if(doorsUnlocked) then
            sim.setStringSignal("doorsUnlocked","true")
        end
    else 
        if (doorsUnlocked and hostageLost) then 
            sim.setJointTargetVelocity(leftMotor, 0)
            sim.setJointTargetVelocity(rightMotor, 0)
        else
            local leftMotorSpeed, rightMotorSpeed
            -- print("State in actuation", state)
            if (robotDrivingState == 1) then
                -- print("Following wall")
                leftMotorSpeed, rightMotorSpeed = followWall()
            elseif (robotDrivingState == 2) then
                -- print("Turning...")
                leftMotorSpeed = wTurnL
                rightMotorSpeed = wTurnR
            elseif (robotDrivingState == 3) then
                -- print("Curving...")
                leftMotorSpeed = wCurveL
                rightMotorSpeed = wCurveR
            else
                leftMotorSpeed = 0
                rightMotorSpeed = 0
            end
            sim.setJointTargetVelocity(leftMotor, leftMotorSpeed)
            sim.setJointTargetVelocity(rightMotor, rightMotorSpeed)
        end
    end
end

function sysCall_sensing()
    local wallFront, wallSide, isWallInFront, isWallInRear

    hostageLost = sim.readProximitySensor(backSensor) == 0

    if (doorsUnlocked and hostageLost) then 
        print("LETS WAIT FOR HIM")
    else
    
        wallFront = sim.readProximitySensor(noseSensor) > 0
        if (direction == "right") then
            -- print ("distanceInFront", getDistance(frontRight, 1.21))
            -- print ("distance in rear", getDistance(rearRight, 1.21))
            isWallInFront = wallDetected(getDistance(frontRight, 1.21), 0.25, 0.25)
            isWallInRear = wallDetected(getDistance(rearRight, 1.21), 0.25, 0.25)
        else
            isWallInFront = wallDetected(getDistance(frontLeft, 1.21), 0.25, 0.25)
            isWallInRear = wallDetected(getDistance(rearLeft, 1.21), 0.25, 0.25)
        end
        wallSide = isWallInFront and isWallInRear
        -- print("Wall is front", wallFront)
        -- print("Wall is on side", wallSide)
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
            -- print((sim.getSimulationTime() - lastTime))
            -- print(minTurnTime)
            if (timeElapsed) then
                print("Is turning done?", timeElapsed)
            end
            if (wallSide and timeElapsed) then
                robotDrivingState = 1
            end
        elseif (robotDrivingState == 3) then
            local timeElapsed = ((sim.getSimulationTime() - lastTime) > minCurveTime)
            -- print((sim.getSimulationTime() - lastTime))
            -- print(minCurveTime)
            if (timeElapsed) then
                print("Is curving done?", timeElapsed)
            end
            if (wallFront) then
                robotDrivingState = 1
            end
            -- print("Is there a wall beside?", wallSide)
            if (wallSide and timeElapsed) then
                robotDrivingState = 1
            end
        end
    end
    -- print(state, lastTime)
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

function turnAround()
    local sign = sim.getObjectOrientation(bubbleRobBase, -1)[3] / math.abs(sim.getObjectOrientation(bubbleRobBase, -1)[3])
    desiredOrientation = offsetZero(roundToClosestQuadrant(-1 * sign * math.pi + sim.getObjectOrientation(bubbleRobBase, -1)[3]))
end

function rotate()
    isRotating = true
    local rotSpeed = 2
    local sign = (desiredOrientation / math.abs(desiredOrientation)) * -1
    sim.setJointTargetVelocity(leftMotor, rotSpeed * sign)
    sim.setJointTargetVelocity(rightMotor, -rotSpeed * sign)
    local currentAngle = sim.getObjectOrientation(bubbleRobBase, -1)[3]
    if (math.abs(desiredOrientation - currentAngle) < math.pi / 90) then
        print("Ending orientation", sim.getObjectOrientation(bubbleRobBase, -1)[3] * 57.2957795)
        desiredOrientation = 0
        isRotating = false
        doorsUnlocked = true
    end
end

function roundToClosestQuadrant(num)
    if (num % (math.pi / 2) >= math.pi / 4) then
        return num - num % (math.pi / 2) + (math.pi / 2)
    else
        return num - num % (math.pi / 2)
    end
end

function offsetZero(num)
    if (num == 0) then
        return 0.0001
    else
        return num
    end
end

function sysCall_cleanup()
    simUI.destroy(ui)
end
