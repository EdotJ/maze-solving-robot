function sysCall_init()
    pressureSensor = sim.getObjectHandle("proximitySensor")
    
    door = sim.getObjectHandle("Door")
    initialDoorPosition = sim.getObjectPosition(door, -1)

    cageDoor = sim.getObjectHandle("CageDoor")
    initialCageDoorPosition = sim.getObjectPosition(door, -1)

    areDoorsOpen = false
end

function sysCall_actuation()
    -- put your actuation code here
end

function sysCall_sensing()
    if (not areDoorsOpen) then
        result = sim.readProximitySensor(pressureSensor)
        if (result > 0) then

            sim.setStringSignal("unlockDoors", "true")

            local unlockedDoors = sim.getStringSignal("doorsUnlocked")

            if(unlockedDoors) then
                areDoorsOpen = true
                openDoor(door)
                openDoor(cageDoor)
                print("Opened doors")
                sim.setStringSignal("wakeUp", "true")
            end
        end
    end
end

function openDoor(doorToOpen)
    sim.setObjectPosition(doorToOpen, -1, {sim.getObjectPosition(doorToOpen, -1)[1], sim.getObjectPosition(doorToOpen, -1)[2], sim.getObjectPosition(doorToOpen, -1)[3] + 0.4})
end

function sysCall_cleanup()
    sim.setObjectPosition(door, -1, initialDoorPosition)
    sim.setObjectPosition(cageDoor, -1, initialCageDoorPosition)
end

-- See the user manual or the available code snippets for additional callback functions and details
