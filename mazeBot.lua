function sysCall_init()
    -- This is executed exactly once, the first time this script is executed
    bubbleRobBase = sim.getObjectAssociatedWithScript(sim.handle_self) -- this is bubbleRob's handle
    leftMotor = sim.getObjectHandle("bubbleRob_leftMotor") -- Handle of the left motor
    rightMotor = sim.getObjectHandle("bubbleRob_rightMotor") -- Handle of the right motor
    noseSensor = sim.getObjectHandle("bubbleRob_sensingNose") -- Handle of the proximity sensor
    peripheralSensorLeft = sim.getObjectHandle("bubbleRob_peripheralVisionLeft")
    peripheralSensorRight = sim.getObjectHandle("bubbleRob_peripheralVisionRight")
    floorSensorHandles = {-1, -1, -1}
    floorSensorHandles[1] = sim.getObjectHandle("bubbleRob_leftSensor")
    floorSensorHandles[2] = sim.getObjectHandle("bubbleRob_middleSensor")
    floorSensorHandles[3] = sim.getObjectHandle("bubbleRob_rightSensor")

    minMaxSpeed = {50 * math.pi / 180, 300 * math.pi / 180} -- Min and max speeds for each motor
    stop = false -- should the robot stand still?
    desiredOrientation = 0

    path = sim.createPath(-1)

    -- LINE DRAWING
    previousPoint = nil
    lineSize = 40 -- in points
    maximumLines = 9999
    red = {1, 0, 0}
    drawingContainer = simAddDrawingObject(sim_drawing_lines, lineSize, 0, -1, maximumLines, red) -- adds a line

    xml =
        '<ui title="' ..
        sim.getObjectName(bubbleRobBase) ..
            ' speed" closeable="false" resizeable="false" activate="false">' ..
                [[
                <hslider minimum="0" maximum="100" on-change="speedChange_callback" id="1"/>
            <label text="" style="* {margin-left: 300px;}"/>
        </ui>
        ]]
    ui = simUI.create(xml)
    speed = (minMaxSpeed[1] + minMaxSpeed[2]) * 0.5
    simUI.setSliderValue(ui, 1, 100 * (speed - minMaxSpeed[1]) / (minMaxSpeed[2] - minMaxSpeed[1]))
end
function speedChange_callback(ui, id, newVal)
    speed = minMaxSpeed[1] + (minMaxSpeed[2] - minMaxSpeed[1]) * newVal / 100
end

function sysCall_actuation()
    sensorReading = {false, false, false}
    for i = 1, 3, 1 do
        result, data = sim.readVisionSensor(floorSensorHandles[i])
        if (result >= 0) then
            sensorReading[i] = (data[11] < 0.3) -- data[11] is the average of intensity of the image
        end
    end
    print("Sensors: ", sensorReading)
    if (desiredOrientation ~= 0) then
        rotate()
    else
        if (previousPoint == nil) then
            previousPoint = sim.getObjectPosition(bubbleRobBase, -1)
        else
            currentPoint = sim.getObjectPosition(bubbleRobBase, -1)
            sim.addDrawingObjectItem(
                drawingContainer,
                {previousPoint[1], previousPoint[2], 0.01, currentPoint[1], currentPoint[2], 0.01}
            )
            previousPoint = currentPoint
        end
        move()
    end
end

function rotate()
    local rotSpeed = 0.5
    local sign = (desiredOrientation / math.abs(desiredOrientation)) * -1
    simSetJointTargetVelocity(leftMotor, rotSpeed * sign)
    simSetJointTargetVelocity(rightMotor, -rotSpeed * sign)
    local currentAngle = sim.getObjectOrientation(bubbleRobBase, -1)[3]
    if (math.abs(desiredOrientation - currentAngle) < math.pi / 360) then
        print("Ending orientation", sim.getObjectOrientation(bubbleRobBase, -1)[3] * 57.2957795)
        desiredOrientation = 0
    end
end

function move()
    isObstacleFront = sim.readProximitySensor(noseSensor)
    isObstacleLeft = sim.readProximitySensor(peripheralSensorLeft)
    isObstacleRight = sim.readProximitySensor(peripheralSensorRight)
    if (isObstacleFront > 0) then -- check if obstacle in front
        if (isObstacleRight == 0) then -- favor going right if no obstacle on right
            goRight()
        elseif (isObstacleLeft == 0) then
            print("Obstacle left", isObstacleLeft)
            print("obstacle right", isObstacleRight)
            goLeft()
        else
            goBack()
        end
    else
        goForward()
    end
end

function goLeft()
    print("Rotating left")
    print("Current rotation", sim.getObjectOrientation(bubbleRobBase, -1)[3] * 57.2957795)
    local sign =
        sim.getObjectOrientation(bubbleRobBase, -1)[3] / math.abs(sim.getObjectOrientation(bubbleRobBase, -1)[3])
    print("Sign", sign)
    desiredOrientation =
        offsetZero(
        roundToClosestQuadrant(modByPiWithSignChange(math.pi / 2 + sim.getObjectOrientation(bubbleRobBase, -1)[3]))
    )
    print("desiredOrientation to left", desiredOrientation * 57.2957795)
end

function goRight()
    print("Rotating Right")
    print("Current rotation", sim.getObjectOrientation(bubbleRobBase, -1)[3] * 57.2957795)
    desiredOrientation =
        offsetZero(
        roundToClosestQuadrant(modByPiWithSignChange(-math.pi / 2 + sim.getObjectOrientation(bubbleRobBase, -1)[3]))
    )
    print("desiredOrientation to right", desiredOrientation * 57.2957795)
end

function goForward()
    sim.setJointTargetVelocity(leftMotor, speed)
    sim.setJointTargetVelocity(rightMotor, speed)
end

function goBack()
    print("Turning around")
    print("Current rotation", sim.getObjectOrientation(bubbleRobBase, -1)[3] * 57.2957795)
    local sign =
        sim.getObjectOrientation(bubbleRobBase, -1)[3] / math.abs(sim.getObjectOrientation(bubbleRobBase, -1)[3])
    print("Sign", sign)
    desiredOrientation =
        offsetZero(roundToClosestQuadrant(-1 * sign * math.pi + sim.getObjectOrientation(bubbleRobBase, -1)[3]))
    print("desiredOrientation to backward", desiredOrientation * 57.2957795)
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

function modByPiWithSignChange(num)
    -- check if the number is really over 180 or is it a small offset
    if (num > math.pi * 57.2957795 + 10) then
        if (math.mod(num, math.pi) == num) then
            return num
        else
            return math.mod(num, math.pi) * -1
        end
    else
        return num
    end
end

function sysCall_cleanup()
    simUI.destroy(ui)
    sim.removeDrawingObject(drawingContainer)
end
