--
-- Extra Gears for FS 22
--
-- BarryCarlyon
-- Version 1.0.0.1
--

ExtraGears = {}
ExtraGears.MOD_NAME = g_currentModName
-- lets do a config
ExtraGears.default = {}
ExtraGears.default.position = {}
ExtraGears.default.position.x = 0.96
ExtraGears.default.position.y = 0.01
ExtraGears.default.reset_on_direction_change = false
ExtraGears.default.reset_on_enter = false

local xmlFilePath = getUserProfileAppPath() .. "modSettings/extraGears.xml"

function ExtraGears.prerequisitesPresent(specializations)
    return true
end

function ExtraGears.registerEventListeners(vehicleType)
    print("ExtraGears -- registerEventListeners for ExtraGears" ..tostring(vehicleType));
    SpecializationUtil.registerEventListener(vehicleType, "onDraw", ExtraGears)
end

function ExtraGears:loadMap(name)
    print("ExtraGears -- loadMap for ExtraGears");
    
    -- Bind/append functions 
    FSCareerMissionInfo.saveToXMLFile = Utils.appendedFunction(FSCareerMissionInfo.saveToXMLFile, ExtraGears.saveToXMLFile)
    g_currentMission.onEnterVehicle = Utils.appendedFunction(g_currentMission.onEnterVehicle, ExtraGears.onEnterVehicle)
    
    Motorized.actionEventDirectionChange = Utils.appendedFunction(Motorized.actionEventDirectionChange, ExtraGears.actionEventDirectionChange)

    self.position = {}
    self.position.x = ExtraGears.default.position.x
    self.position.y = ExtraGears.default.position.y
    self.reset_on_direction_change = ExtraGears.default.reset_on_direction_change
    self.reset_on_enter = ExtraGears.default.reset_on_enter

    if g_dedicatedServerInfo == nil then
         if not fileExists(xmlFilePath) then
            if not fileExists(xmlFilePath) then
                self:defaultXML(xmlFilePath)
            end
            self:loadXML(xmlFilePath)
        else
            self:loadXML(xmlFilePath)
        end
    end
end

function ExtraGears:defaultXML(fileName)
    print("ExtraGears - Make Default Config File " ..tostring(fileName))
    local xml = createXMLFile("ExtraGears", fileName, "ExtraGears")
    setXMLFloat(xml, "ExtraGears.position#x", ExtraGears.default.position.x)
    setXMLFloat(xml, "ExtraGears.position#y", ExtraGears.default.position.y)
    setXMLBool(xml, "ExtraGears.reset_settings#reset_on_direction_change", ExtraGears.default.reset_on_direction_change)
    setXMLBool(xml, "ExtraGears.reset_settings#reset_on_enter", ExtraGears.default.reset_on_enter)
    saveXMLFile(xml)
    delete(xml)
end

function ExtraGears:saveToXMLFile(missionInfo)
    print("ExtraGears - saveToXMLFile ")
    local xml = createXMLFile("ExtraGears", xmlFilePath, "ExtraGears")
    setXMLFloat(xml, "ExtraGears.position#x", ExtraGears.position.x)
    setXMLFloat(xml, "ExtraGears.position#y", ExtraGears.position.y)
    setXMLBool(xml, "ExtraGears.reset_settings#reset_on_direction_change", ExtraGears.reset_on_direction_change)
    setXMLBool(xml, "ExtraGears.reset_settings#reset_on_enter", ExtraGears.reset_on_enter)
    saveXMLFile(xml)
    delete(xml)
end

function ExtraGears:loadXML(fileName)
    print("ExtraGears -- loading XML " ..tostring(fileName))
    local xml = loadXMLFile("ExtraGears", fileName)
    local x = Utils.getNoNil(getXMLFloat(xml, "ExtraGears.position#x"), ExtraGears.position.x)
    if (self:posOK(x)) then
        self.position.x = x
    else
        self.position.x = ExtraGears.default.position.x
    end
    local y = Utils.getNoNil(getXMLFloat(xml, "ExtraGears.position#y"), ExtraGears.position.y)
    if (self:posOK(y)) then
        self.position.y = y
    else
        self.position.y = ExtraGears.default.position.y
    end

    self.reset_on_direction_change = Utils.getNoNil(getXMLBool(xml, "ExtraGears.reset_settings#reset_on_direction_change"), ExtraGears.reset_on_direction_change)
    self.reset_on_enter = Utils.getNoNil(getXMLBool(xml, "ExtraGears.reset_settings#reset_on_enter"), ExtraGears.reset_on_enter)

    print("ExtraGears -- loaded " ..tostring(self.position.x) .." " ..tostring(self.position.x) .." " ..tostring(self.reset_on_direction_change) .. tostring(self.reset_on_enter))
end

function ExtraGears:posOK(val)
    local val = tonumber(float)
    if val ~= nil and val >= 0 and val <= 1 then
        return true
    else
        return false
    end
end

function ExtraGears:onDraw(dt)
    -- ExtraGears.shiftGearOverrideAmount
    -- print("ExtraGears - Draw");
    if self.isClient then
        -- print("ExtraGears - Is Client")
        local vehicle = g_currentMission.controlledVehicle
        if vehicle ~= nil and vehicle:getIsSynchronized() then
            if nil == ExtraGears.shiftGearOverrideAmount then
            ExtraGears.shiftGearOverrideAmount = 0
            end
            -- renderText(0.96, 0.01, 0.03, "+"..tostring(ExtraGears.shiftGearOverrideAmount))
            renderText(ExtraGears.position.x, ExtraGears.position.y, 0.03, "+"..tostring(ExtraGears.shiftGearOverrideAmount))
            setTextColor(1, 1, 1, 1)
            setTextAlignment(RenderText.ALIGN_RIGHT)
        end
    end
end

-- dataS/scripts/vehicles/specializations/Motorized.lua
-- inputBindings override Motorized
function Motorized:onRegisterActionEvents(isActiveForInput, isActiveForInputIgnoreSelection)
    if self.isClient then
        local spec = self.spec_motorized
        self:clearActionEventsTable(spec.actionEvents)

        if isActiveForInputIgnoreSelection then
            local _, actionEventId = self:addActionEvent(spec.actionEvents, InputAction.TOGGLE_MOTOR_STATE, self, Motorized.actionEventToggleMotorState, false, true, false, true, nil)
            g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_VERY_HIGH)
            g_inputBinding:setActionEventText(actionEventId, spec.turnOnText)

            if spec.motor.minForwardGearRatio == nil or spec.motor.minBackwardGearRatio == nil then
                if self:getGearShiftMode() ~= VehicleMotor.SHIFT_MODE_AUTOMATIC or not GS_IS_CONSOLE_VERSION then
                    if spec.motor.manualShiftGears then
                        _, actionEventId = self:addActionEvent(spec.actionEvents, InputAction.SHIFT_GEAR_UP, self, Motorized.actionEventShiftGear, false, true, false, true, nil)
                        g_inputBinding:setActionEventTextVisibility(actionEventId, false)
                        _, actionEventId = self:addActionEvent(spec.actionEvents, InputAction.SHIFT_GEAR_DOWN, self, Motorized.actionEventShiftGear, false, true, false, true, nil)
                        g_inputBinding:setActionEventTextVisibility(actionEventId, false)

                        _, actionEventId = self:addActionEvent(spec.actionEvents, InputAction.SHIFT_GEAR_SELECT_1, self, Motorized.actionEventSelectGear, true, true, true, true, 1)
                        g_inputBinding:setActionEventTextVisibility(actionEventId, false)
                        _, actionEventId = self:addActionEvent(spec.actionEvents, InputAction.SHIFT_GEAR_SELECT_2, self, Motorized.actionEventSelectGear, true, true, true, true, 2)
                        g_inputBinding:setActionEventTextVisibility(actionEventId, false)
                        _, actionEventId = self:addActionEvent(spec.actionEvents, InputAction.SHIFT_GEAR_SELECT_3, self, Motorized.actionEventSelectGear, true, true, true, true, 3)
                        g_inputBinding:setActionEventTextVisibility(actionEventId, false)
                        _, actionEventId = self:addActionEvent(spec.actionEvents, InputAction.SHIFT_GEAR_SELECT_4, self, Motorized.actionEventSelectGear, true, true, true, true, 4)
                        g_inputBinding:setActionEventTextVisibility(actionEventId, false)
                        _, actionEventId = self:addActionEvent(spec.actionEvents, InputAction.SHIFT_GEAR_SELECT_5, self, Motorized.actionEventSelectGear, true, true, true, true, 5)
                        g_inputBinding:setActionEventTextVisibility(actionEventId, false)
                        _, actionEventId = self:addActionEvent(spec.actionEvents, InputAction.SHIFT_GEAR_SELECT_6, self, Motorized.actionEventSelectGear, true, true, true, true, 6)
                        g_inputBinding:setActionEventTextVisibility(actionEventId, false)
                        _, actionEventId = self:addActionEvent(spec.actionEvents, InputAction.SHIFT_GEAR_SELECT_7, self, Motorized.actionEventSelectGear, true, true, true, true, 7)
                        g_inputBinding:setActionEventTextVisibility(actionEventId, false)
                        _, actionEventId = self:addActionEvent(spec.actionEvents, InputAction.SHIFT_GEAR_SELECT_8, self, Motorized.actionEventSelectGear, true, true, true, true, 8)
                        g_inputBinding:setActionEventTextVisibility(actionEventId, false)

                        print("ExtraGears -- Override Motorized:onRegisterActionEvents for vehicle motor registration 1->18")
                        _, actionEventId = self:addActionEvent(spec.actionEvents, InputAction.EXG_GEAR_1, self, Motorized.actionEventSelectGear, true, true, true, true, 1)
                        g_inputBinding:setActionEventTextVisibility(actionEventId, false)
                        _, actionEventId = self:addActionEvent(spec.actionEvents, InputAction.EXG_GEAR_2, self, Motorized.actionEventSelectGear, true, true, true, true, 2)
                        g_inputBinding:setActionEventTextVisibility(actionEventId, false)
                        _, actionEventId = self:addActionEvent(spec.actionEvents, InputAction.EXG_GEAR_3, self, Motorized.actionEventSelectGear, true, true, true, true, 3)
                        g_inputBinding:setActionEventTextVisibility(actionEventId, false)
                        _, actionEventId = self:addActionEvent(spec.actionEvents, InputAction.EXG_GEAR_4, self, Motorized.actionEventSelectGear, true, true, true, true, 4)
                        g_inputBinding:setActionEventTextVisibility(actionEventId, false)
                        _, actionEventId = self:addActionEvent(spec.actionEvents, InputAction.EXG_GEAR_5, self, Motorized.actionEventSelectGear, true, true, true, true, 5)
                        g_inputBinding:setActionEventTextVisibility(actionEventId, false)
                        _, actionEventId = self:addActionEvent(spec.actionEvents, InputAction.EXG_GEAR_6, self, Motorized.actionEventSelectGear, true, true, true, true, 6)
                        g_inputBinding:setActionEventTextVisibility(actionEventId, false)
                        _, actionEventId = self:addActionEvent(spec.actionEvents, InputAction.EXG_GEAR_7, self, Motorized.actionEventSelectGear, true, true, true, true, 7)
                        g_inputBinding:setActionEventTextVisibility(actionEventId, false)
                        _, actionEventId = self:addActionEvent(spec.actionEvents, InputAction.EXG_GEAR_8, self, Motorized.actionEventSelectGear, true, true, true, true, 8)
                        g_inputBinding:setActionEventTextVisibility(actionEventId, false)

                        -- add 9 -> 18
                        _, actionEventId = self:addActionEvent(spec.actionEvents, InputAction.EXG_GEAR_9, self, Motorized.actionEventSelectGear, true, true, true, true, 9)
                        g_inputBinding:setActionEventTextVisibility(actionEventId, false)
                        _, actionEventId = self:addActionEvent(spec.actionEvents, InputAction.EXG_GEAR_10, self, Motorized.actionEventSelectGear, true, true, true, true, 10)
                        g_inputBinding:setActionEventTextVisibility(actionEventId, false)
                        _, actionEventId = self:addActionEvent(spec.actionEvents, InputAction.EXG_GEAR_11, self, Motorized.actionEventSelectGear, true, true, true, true, 11)
                        g_inputBinding:setActionEventTextVisibility(actionEventId, false)
                        _, actionEventId = self:addActionEvent(spec.actionEvents, InputAction.EXG_GEAR_11, self, Motorized.actionEventSelectGear, true, true, true, true, 11)
                        g_inputBinding:setActionEventTextVisibility(actionEventId, false)
                        _, actionEventId = self:addActionEvent(spec.actionEvents, InputAction.EXG_GEAR_12, self, Motorized.actionEventSelectGear, true, true, true, true, 12)
                        g_inputBinding:setActionEventTextVisibility(actionEventId, false)
                        _, actionEventId = self:addActionEvent(spec.actionEvents, InputAction.EXG_GEAR_13, self, Motorized.actionEventSelectGear, true, true, true, true, 13)
                        g_inputBinding:setActionEventTextVisibility(actionEventId, false)
                        _, actionEventId = self:addActionEvent(spec.actionEvents, InputAction.EXG_GEAR_14, self, Motorized.actionEventSelectGear, true, true, true, true, 14)
                        g_inputBinding:setActionEventTextVisibility(actionEventId, false)
                        _, actionEventId = self:addActionEvent(spec.actionEvents, InputAction.EXG_GEAR_15, self, Motorized.actionEventSelectGear, true, true, true, true, 15)
                        g_inputBinding:setActionEventTextVisibility(actionEventId, false)
                        _, actionEventId = self:addActionEvent(spec.actionEvents, InputAction.EXG_GEAR_16, self, Motorized.actionEventSelectGear, true, true, true, true, 16)
                        g_inputBinding:setActionEventTextVisibility(actionEventId, false)
                        _, actionEventId = self:addActionEvent(spec.actionEvents, InputAction.EXG_GEAR_17, self, Motorized.actionEventSelectGear, true, true, true, true, 17)
                        g_inputBinding:setActionEventTextVisibility(actionEventId, false)
                        _, actionEventId = self:addActionEvent(spec.actionEvents, InputAction.EXG_GEAR_18, self, Motorized.actionEventSelectGear, true, true, true, true, 18)
                        g_inputBinding:setActionEventTextVisibility(actionEventId, false)
                    end

                    if spec.motor.manualShiftGroups then
                        if spec.motor.gearGroups ~= nil then
                            _, actionEventId = self:addActionEvent(spec.actionEvents, InputAction.SHIFT_GROUP_UP, self, Motorized.actionEventShiftGroup, false, true, false, true, nil)
                            g_inputBinding:setActionEventTextVisibility(actionEventId, false)
                            _, actionEventId = self:addActionEvent(spec.actionEvents, InputAction.SHIFT_GROUP_DOWN, self, Motorized.actionEventShiftGroup, false, true, false, true, nil)
                            g_inputBinding:setActionEventTextVisibility(actionEventId, false)

                            _, actionEventId = self:addActionEvent(spec.actionEvents, InputAction.SHIFT_GROUP_SELECT_1, self, Motorized.actionEventSelectGroup, true, true, true, true, 1)
                            g_inputBinding:setActionEventTextVisibility(actionEventId, false)
                            _, actionEventId = self:addActionEvent(spec.actionEvents, InputAction.SHIFT_GROUP_SELECT_2, self, Motorized.actionEventSelectGroup, true, true, true, true, 2)
                            g_inputBinding:setActionEventTextVisibility(actionEventId, false)
                            _, actionEventId = self:addActionEvent(spec.actionEvents, InputAction.SHIFT_GROUP_SELECT_3, self, Motorized.actionEventSelectGroup, true, true, true, true, 3)
                            g_inputBinding:setActionEventTextVisibility(actionEventId, false)
                            _, actionEventId = self:addActionEvent(spec.actionEvents, InputAction.SHIFT_GROUP_SELECT_4, self, Motorized.actionEventSelectGroup, true, true, true, true, 4)
                            g_inputBinding:setActionEventTextVisibility(actionEventId, false)

                            -- add gear group 5/6 c/o SentinelMantik
                            print("ExtraGears -- Override Motorized:onRegisterActionEvents for vehicle motor registration geargroup")
                            _, actionEventId = self:addActionEvent(spec.actionEvents, InputAction.EXG_GRP_5, self, Motorized.actionEventSelectGroup, true, true, true, true, 5)
                            g_inputBinding:setActionEventTextVisibility(actionEventId, false)
                            _, actionEventId = self:addActionEvent(spec.actionEvents, InputAction.EXG_GRP_6, self, Motorized.actionEventSelectGroup, true, true, true, true, 6)
                            g_inputBinding:setActionEventTextVisibility(actionEventId, false)
                        end
                    end

                    _, actionEventId = self:addActionEvent(spec.actionEvents, InputAction.AXIS_CLUTCH_VEHICLE, self, Motorized.actionEventClutch, false, false, true, true, nil)
                    g_inputBinding:setActionEventTextVisibility(actionEventId, false)

                    print("ExtraGears -- Override Motorized:onRegisterActionEvents for vehicle motor registration -> shift groups")
                    -- add the shifter groups
                    _, actionEventId = self:addActionEvent(spec.actionEvents, InputAction.EXG_GEAR_SHIFT_6_UP, self, MotorGearShiftEvent.shiftGearOverrideStep, false, true, false, true, 6)
                    g_inputBinding:setActionEventTextVisibility(actionEventId, false)
                    _, actionEventId = self:addActionEvent(spec.actionEvents, InputAction.EXG_GEAR_SHIFT_6_DOWN, self, MotorGearShiftEvent.shiftGearOverrideStep, false, true, false, true, -6)
                    g_inputBinding:setActionEventTextVisibility(actionEventId, false)

                    _, actionEventId = self:addActionEvent(spec.actionEvents, InputAction.EXG_GEAR_SHIFT_8_UP, self, MotorGearShiftEvent.shiftGearOverrideStep, false, true, false, true, 8)
                    g_inputBinding:setActionEventTextVisibility(actionEventId, false)
                    _, actionEventId = self:addActionEvent(spec.actionEvents, InputAction.EXG_GEAR_SHIFT_8_DOWN, self, MotorGearShiftEvent.shiftGearOverrideStep, false, true, false, true, -8)
                    g_inputBinding:setActionEventTextVisibility(actionEventId, false)


                    _, actionEventId = self:addActionEvent(spec.actionEvents, InputAction.EXG_GEAR_SHIFT_A8, self, MotorGearShiftEvent.shiftGearOverride, false, true, false, true, 8)
                    g_inputBinding:setActionEventTextVisibility(actionEventId, false)
                    _, actionEventId = self:addActionEvent(spec.actionEvents, InputAction.EXG_GEAR_SHIFT_B8, self, MotorGearShiftEvent.shiftGearOverride, false, true, false, true, 16)
                    g_inputBinding:setActionEventTextVisibility(actionEventId, false)
                    _, actionEventId = self:addActionEvent(spec.actionEvents, InputAction.EXG_GEAR_SHIFT_A6, self, MotorGearShiftEvent.shiftGearOverride, false, true, false, true, 6)
                    g_inputBinding:setActionEventTextVisibility(actionEventId, false)
                    _, actionEventId = self:addActionEvent(spec.actionEvents, InputAction.EXG_GEAR_SHIFT_B6, self, MotorGearShiftEvent.shiftGearOverride, false, true, false, true, 12)
                    g_inputBinding:setActionEventTextVisibility(actionEventId, false)
                    _, actionEventId = self:addActionEvent(spec.actionEvents, InputAction.EXG_GEAR_SHIFT_C6, self, MotorGearShiftEvent.shiftGearOverride, false, true, false, true, 18)
                    g_inputBinding:setActionEventTextVisibility(actionEventId, false)
                end
            end

            if self:getDirectionChangeMode() == VehicleMotor.DIRECTION_CHANGE_MODE_MANUAL or self:getGearShiftMode() ~= VehicleMotor.SHIFT_MODE_AUTOMATIC then
                _, actionEventId = self:addActionEvent(spec.actionEvents, InputAction.DIRECTION_CHANGE, self, Motorized.actionEventDirectionChange, false, true, false, true, nil, nil, true)
                g_inputBinding:setActionEventTextVisibility(actionEventId, false)
                _, actionEventId = self:addActionEvent(spec.actionEvents, InputAction.DIRECTION_CHANGE_POS, self, Motorized.actionEventDirectionChange, false, true, false, true, nil, nil, true)
                g_inputBinding:setActionEventTextVisibility(actionEventId, false)
                _, actionEventId = self:addActionEvent(spec.actionEvents, InputAction.DIRECTION_CHANGE_NEG, self, Motorized.actionEventDirectionChange, false, true, false, true, nil, nil, true)
                g_inputBinding:setActionEventTextVisibility(actionEventId, false)
            end

            Motorized.updateActionEvents(self)
        end
    end
end

function ExtraGears:onEnterVehicle()
    print("ExtraGears -- onEnter")
    if ExtraGears.reset_on_enter then
        print("ExtraGears -- onEnter -> reset to 0")
        ExtraGears.shiftGearOverrideAmount = 0
        ExtraGears.lastshiftGearOverrideAmount = 0
    end
end

--called after Motorized:actionEventDirectionChange (as appended function)
function ExtraGears:actionEventDirectionChange(self, actionName, inputValue, callbackState, isAnalog)
    print("ExtraGears -- actionEventDirectionChange")

    if ExtraGears.reset_on_direction_change then
        print("ExtraGears - direction change -> reset to 0")
        ExtraGears.shiftGearOverrideAmount = 0
        ExtraGears.lastshiftGearOverrideAmount = 0
    end
end

-- dataS\scripts\vehicles\specializations\events\MotorGearShiftEvent.lua
function MotorGearShiftEvent:shiftGearOverrideStep(actionName, keyStatus, shiftAmount, arg4, arg5, two)
    print("ExtraGears -- shift add/remove" ..tostring(shiftAmount));
    if nil == ExtraGears.lastshiftGearOverrideAmount then
        ExtraGears.lastshiftGearOverrideAmount = 0
    end
    if nil == ExtraGears.shiftGearOverrideAmount then
        ExtraGears.shiftGearOverrideAmount = 0
    end
    ExtraGears.shiftGearOverrideAmount = ExtraGears.shiftGearOverrideAmount + shiftAmount
    if ExtraGears.shiftGearOverrideAmount < 0 then
        ExtraGears.shiftGearOverrideAmount = 0
    end
    -- probably need to add a cap
    -- this needs more thought
    -- 21 is 3 x 8
    if ExtraGears.shiftGearOverrideAmount >= 24 then
        ExtraGears.shiftGearOverrideAmount = 0
    end
end

-- keyStatus 1 down
-- keyStatus 0 released
function MotorGearShiftEvent:shiftGearOverride(actionName, keyStatus, shiftAmount, arg4, arg5, two)
    print("ExtraGears -- shift amount " ..tostring(actionName) .." " ..tostring(keyStatus) .." " ..tostring(shiftAmount) .." " ..tostring(arg4) .." " ..tostring(arg5) .." " ..tostring(two))

    --local spec = self.spec_ExtraGears
    if nil == ExtraGears.lastshiftGearOverrideAmount then
        ExtraGears.shiftGearOverrideAmount = shiftAmount
    elseif ExtraGears.lastshiftGearOverrideAmount == shiftAmount then
        ExtraGears.shiftGearOverrideAmount = 0;
    else
        ExtraGears.shiftGearOverrideAmount = shiftAmount
    end
    print("ExtraGears -- shift amount now " ..tostring(ExtraGears.shiftGearOverrideAmount))
    ExtraGears.lastshiftGearOverrideAmount = ExtraGears.shiftGearOverrideAmount
end

---Broadcast event from server to all clients, if called on client call function on server and broadcast it to all clients
-- @param table vehicle vehicle
-- @param integer shiftType type of shifting event
-- @param integer shiftValue additional value for shifting event
function MotorGearShiftEvent.sendEvent(vehicle, shiftType, shiftValue)
    if g_client ~= nil then
        if shiftType == MotorGearShiftEvent.TYPE_SELECT_GEAR then
            --sanity check

            local inp = shiftValue;

            if nill == ExtraGears.shiftGearOverrideAmount then
                ExtraGears.shiftGearOverrideAmount = 0
            end
             print("ExtraGears - in shiftevent sendEvent - " ..tostring(shiftValue) .." | " ..tostring(ExtraGears.shiftGearOverrideAmount));
            -- is the stick in neutral?
            -- only bump if not in neutral

            -- 1.2 patch
            -- if shiftValue > 1 then
            --     shiftValue = shiftValue - (keybind - 1);
            -- end

            if shiftValue > 0 then
                shiftValue = shiftValue + ExtraGears.shiftGearOverrideAmount;
            end
            --print("ExtraGears - in shiftevent resolved " ..tostring(inp) ..tostring(' ') ..tostring(ExtraGears.shiftGearOverrideAmount) ..(' ') ..tostring(shiftValue));
            -- print("ExtraGears - in shiftevent resolved " ..tostring(shiftValue));
        end

        g_client:getServerConnection():sendEvent(MotorGearShiftEvent.new(vehicle, shiftType, shiftValue))
    end
end

---Called on client side on join
-- @param integer streamId streamId
-- @param integer connection connection
function MotorGearShiftEvent:readStream(streamId, connection)
    self.vehicle = NetworkUtil.readNodeObject(streamId)
    self.shiftType = streamReadUIntN(streamId, 4)

    if self.shiftType == MotorGearShiftEvent.TYPE_SELECT_GEAR or self.shiftType == MotorGearShiftEvent.TYPE_SELECT_GROUP then
        self.shiftValue = streamReadUIntN(streamId, 5)
    end

    self:run(connection)
end


---Called on server side on join
-- @param integer streamId streamId
-- @param integer connection connection
function MotorGearShiftEvent:writeStream(streamId, connection)
    NetworkUtil.writeNodeObject(streamId, self.vehicle)
    streamWriteUIntN(streamId, self.shiftType, 4)

    if self.shiftType == MotorGearShiftEvent.TYPE_SELECT_GEAR or self.shiftType == MotorGearShiftEvent.TYPE_SELECT_GROUP then
        streamWriteUIntN(streamId, self.shiftValue, 5)
    end
end


function MotorGearShiftEvent:run(connection)
    if self.vehicle ~= nil and self.vehicle:getIsSynchronized() then
        local spec = self.vehicle.spec_motorized
        if spec ~= nil and spec.isMotorStarted then
            if self.shiftType == MotorGearShiftEvent.TYPE_SHIFT_UP then
                spec.motor:shiftGear(true)
            elseif self.shiftType == MotorGearShiftEvent.TYPE_SHIFT_DOWN then
                spec.motor:shiftGear(false)
            elseif self.shiftType == MotorGearShiftEvent.TYPE_SELECT_GEAR then
                -- print("ExtraGears - setting " ..tostring(self.shiftValue))
                spec.motor:selectGear(self.shiftValue, self.shiftValue ~= 0)
            elseif self.shiftType == MotorGearShiftEvent.TYPE_SHIFT_GROUP_UP then
                spec.motor:shiftGroup(true)
            elseif self.shiftType == MotorGearShiftEvent.TYPE_SHIFT_GROUP_DOWN then
                spec.motor:shiftGroup(false)
            elseif self.shiftType == MotorGearShiftEvent.TYPE_SELECT_GROUP then
                spec.motor:selectGroup(self.shiftValue, self.shiftValue ~= 0)
            elseif self.shiftType == MotorGearShiftEvent.TYPE_DIRECTION_CHANGE then
                spec.motor:changeDirection()
            elseif self.shiftType == MotorGearShiftEvent.TYPE_DIRECTION_CHANGE_POS then
                spec.motor:changeDirection(1)
            elseif self.shiftType == MotorGearShiftEvent.TYPE_DIRECTION_CHANGE_NEG then
                spec.motor:changeDirection(-1)
            end
        end
    end
end



addModEventListener(ExtraGears);
