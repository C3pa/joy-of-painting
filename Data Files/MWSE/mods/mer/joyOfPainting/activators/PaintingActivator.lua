local common = require("mer.joyOfPainting.common")
local config = require("mer.joyOfPainting.config")
local logger = common.createLogger("PaintingActivator")
local Painting = require("mer.joyOfPainting.items.Painting")
---@param e equipEventData
local function onEquip(e)

end
event.register(tes3.event.equip, onEquip)


local PaintingActivator = {
    name = "PaintingActivator",
}

---@param e equipEventData|activateEventData
function PaintingActivator.activate(e)
    local painting = Painting:new{
        reference = e.target,
        item = e.item, ---@type any
        itemData = e.itemData,
    }
    tes3ui.showMessageMenu{
        message = painting.item.name,
        buttons = {
            {
                text = "View",
                callback = function()
                    painting:paintingMenu()
                end,
            },
            {
                text = "Pick Up",
                callback = function()
                    common.pickUp(painting.reference)
                end,
                showRequirements = function()
                    if painting.reference then
                        return true
                    end
                    return false
                end
            },
            {
                text = "Discard",
                callback = function()
                    tes3ui.showMessageMenu{
                        message = string.format("Are you sure you want to discard %s?", painting.item.name),
                        buttons = {
                            {
                                text = "Yes",
                                callback = function()
                                    if painting.reference then
                                        painting.reference:delete()
                                    else
                                        tes3.removeItem{
                                            reference = tes3.player,
                                            item = painting.item,
                                            itemData = painting.dataHolder,
                                            playSound = false,
                                        }
                                    end
                                    tes3.messageBox("You discard %s", painting.item.name)
                                    tes3.playSound{ sound = "scroll"}
                                end,
                            },
                        },
                        cancels = true
                    }
                end,
                showRequirements = function()
                    local canvasConfig = painting:getCanvasConfig()
                    if canvasConfig and not canvasConfig.requiresEasel then
                        return true
                    end
                    return false
                end
            },
        },
        cancels = true
    }
end

return PaintingActivator