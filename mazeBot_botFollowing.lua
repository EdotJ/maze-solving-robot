function sysCall_init()
    noseSensor = sim.getObjectHandle("bubbleRob_sensingNose#0")
    robotDrivingState = 0
   -- This is executed exactly once, the first time this script is executed
    active = false;
end

function sysCall_actuation()
    active = sim.getStringSignal("wakeUp")

    if (active) then
        -- local leftMotorSpeed, rightMotorSpeed

        -- if (robotDrivingState == 1) then
        --     print("Following rescueBot")
        --     leftMotorSpeed, rightMotorSpeed = followWall()
        -- elseif (robotDrivingState == 2) then
        --     print("Turning...")
        --     leftMotorSpeed = wTurnL
        --     rightMotorSpeed = wTurnR
        -- elseif (robotDrivingState == 3) then
        --     print("Curving...")
        --     leftMotorSpeed = wCurveL
        --     rightMotorSpeed = wCurveR
        -- else
        --     leftMotorSpeed = 0
        --     rightMotorSpeed = 0
        -- end
        -- sim.setJointTargetVelocity(leftMotor, leftMotorSpeed)
        -- sim.setJointTargetVelocity(rightMotor, rightMotorSpeed)
    end



    -- result=sim.readProximitySensor(noseSensor)
    -- if (result>0) then backUntilTime=sim.getSimulationTime()+4 end

    -- -- read the line detection sensors:
    -- sensorReading={false,false,false}
    -- for i=1,3,1 do
    --     result,data=sim.readVisionSensor(floorSensorHandles[i])
    --     if (result>=0) then
    --         sensorReading[i]=(data[11]<0.3) -- data[11] is the average of intensity of the image
    --     end
    --     print(sensorReading[i])
    -- end

    -- -- compute left and right velocities to follow the detected line:
    -- rightV=speed
    -- leftV=speed
    -- if sensorReading[1] then
    --     leftV=0.03*speed
    -- end
    -- if sensorReading[3] then
    --     rightV=0.03*speed
    -- end
    -- if sensorReading[1] and sensorReading[3] then
    --     backUntilTime=sim.getSimulationTime()+2
    -- end

    -- if (backUntilTime<sim.getSimulationTime()) then
    --     -- When in forward mode, we simply move forward at the desired speed
    --     sim.setJointTargetVelocity(leftMotor,leftV)
    --     sim.setJointTargetVelocity(rightMotor,rightV)
    -- else
    --     -- When in backward mode, we simply backup in a curve at reduced speed
    --     sim.setJointTargetVelocity(leftMotor,-speed/2)
    --     sim.setJointTargetVelocity(rightMotor,-speed/8)
    -- end
end

function sysCall_sensing()
    local wallFront, wallSide, isWallInFront, isWallInRear
    wallFront = sim.readProximitySensor(noseSensor) > 0
    robotDrivingState = 1
end