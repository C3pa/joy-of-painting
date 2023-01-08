local common = require("mer.joyOfPainting.common")
local config = require("mer.joyOfPainting.config")
local logger = common.createLogger("FieldEaselActivator")
local Easel = require("mer.joyOfPainting.items.Easel")
local Activator = require("mer.joyOfPainting.services.Activator")


local function activateEasel(e)
    logger:debug("Activating Easel")
    local easel = Easel:new(e.target)
    if not easel then
        logger:error("Failed to create Easel")
        return
    end
    local buttons = Easel.getActivationButtons()
    logger:debug("Showing message menu")
    tes3ui.showMessageMenu{
        message = e.target.object.name,
        buttons = buttons,
        cancels = true,
        callbackParams = { reference = e.target}
    }
end

Activator.registerActivator{
    onActivate = activateEasel,
    isActivatorItem = function(e)
        if not e.target then
            return false
        end
        if not config.easels[e.object.id:lower()] then
            logger:error("Not an easel")
            return false
        end
        logger:debug("Is an easel")
        return true
    end,
    blockStackActivate = true
}

---@param e activateEventData
local function activateMiscEasel(e)
    tes3ui.showMessageMenu{
        message = e.target.object.name,
        buttons = {
            {
                text = "Unpack",
                callback = function()
                    local id = e.target.object.id:lower()
                    local miscEaselConfig = config.miscEasels[id]
                    if miscEaselConfig then
                        logger:debug("replacing with activator")
                        local activatorEasel = tes3.createReference{
                            object = miscEaselConfig.id,
                            position = e.target.position,
                            orientation = e.target.orientation,
                            cell = e.target.cell
                        }
                        logger:debug("Unpacking easel")
                        common.playActivatorAnimation{
                            reference = activatorEasel,
                            group = Easel.animationGroups.unpacking,
                            sound = "Wooden Door Open 1",
                            duration = 1.4
                        }
                        logger:debug("Deleting misc easel")
                        e.target:delete()
                    end
                end
            },
            {
                text = "Pick Up",
                callback = function()
                    logger:debug("Picking up misc easel")
                    common.pickUp(e.target)
                end
            }
        },
        cancels = true,
        callbackParams = { reference = e.target}
    }
end

Activator.registerActivator{
    onActivate = activateMiscEasel,
    isActivatorItem = function(e)
        if tes3ui.menuMode() then
            logger:debug("Menu mode, skip")
            return false
        end
        if not e.target then
            return false
        end
        if not config.miscEasels[e.object.id:lower()] then
            logger:error("Not an easel")
            return false
        end
        logger:debug("Is a misc easel")
        return true
    end,
    blockStackActivate = true
}

-- event.register("itemDropped", function(e)
--     if config.miscEasels[e.reference.object.id:lower()] then
--         logger:debug("Dropped misc easel, setting animation to packed")
--         tes3.playAnimation{
--             reference = e.reference,
--             group = Easel.animationGroups.packed,
--             startFlag = tes3.animationStartFlag.immediate,
--             loopCount = 0
--         }
--     end
-- end)