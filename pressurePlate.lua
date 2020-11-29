function sysCall_init()
    pressureSensor = sim.getObjectHandle("proximitySensor")
    door = sim.getObjectHandle("DisappearingWall")
    initialDoorPosition = sim.getObjectPosition(door, -1)
    isDoorUp = false
end

function sysCall_actuation()
    -- put your actuation code here
end

function sysCall_sensing()
    if (not isDoorUp) then
        result = sim.readProximitySensor(pressureSensor)
        if (result > 0) then
            print("Killed the door")
            isDoorUp = true
            sim.setObjectPosition(door, -1, {sim.getObjectPosition(door, -1)[1], sim.getObjectPosition(door, -1)[2], sim.getObjectPosition(door, -1)[3] + 0.4})
        end
    end
end

function sysCall_cleanup()
    sim.setObjectPosition(door, -1, initialDoorPosition)
end

-- See the user manual or the available code snippets for additional callback functions and details
