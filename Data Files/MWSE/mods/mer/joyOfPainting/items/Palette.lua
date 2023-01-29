---@class JOP.Palette.params
---@field reference tes3reference?
---@field item tes3item?
---@field itemData tes3itemData?
---@field paletteItem JOP.PaletteItem

---@class JOP.PaletteItem
---@field id string The id of the palette item. Must be a valid tes3item
---@field meshOverride string The mesh to use for this palette item
---@field breaks boolean Whether the palette breaks when uses run out
---@field fullByDefault boolean Whether the palette is full by default
---@field uses number The number of uses for the palette
---@field paintType string The paintType that this palette can be used with


---@class JOP.PaintType
---@field id string The id of the palette type
---@field name string The name of the palette type
---@field brushType string? The brush type to use for this palette. If not specified, this palette does not need a brush to use.
---@field refillMenu craftingFrameworkMenuActivator

local common = require("mer.joyOfPainting.common")
local config = require("mer.joyOfPainting.config")
local logger = common.createLogger("Palette")
local NodeManager = require("mer.joyOfPainting.services.NodeManager")
local CraftingFramework = require("CraftingFramework")
local meshService = require("mer.joyOfPainting.services.MeshService")
---@class JOP.Palette
local Palette = {
    classname = "Palette",
    ---@type JOP.PaletteItem
    paletteItem = nil,
    ---@type tes3reference
    reference = nil,
    item = nil,
    itemData = nil,
    dataHolder = nil,
    data = nil,
}
Palette.__index = Palette

--[[
    Register a palette item
]]
---@param e JOP.PaletteItem
function Palette.registerPaletteItem(e)
    logger:assert(type(e.id) == "string", "id must be a string")
    logger:assert(type(e.paintType) == "string", "paintTypes must be a table")
    logger:debug("Registering palette item %s", e.id)
    e.id = e.id:lower()
    config.paletteItems[e.id] = table.copy(e, {})
    if e.meshOverride then
        meshService.registerOverride(e.id, e.meshOverride)
    end
end

---@param e JOP.PaintType
function Palette.registerPaintType(e)
    logger:assert(type(e.id) == "string", "id must be a string")
    logger:assert(type(e.name) == "string", "name must be a string")
    logger:debug("Registering palette type %s", e.id)
    e.id = e.id:lower()
    config.paintTypes[e.id] = table.copy(e, {})
end

---@param e JOP.Palette.params
---@return JOP.Palette|nil
function Palette:new(e)
    logger:assert((e.reference or e.item) ~= nil, "Palette requires either a reference or an item")
    local palette = setmetatable({}, self)

    palette.reference = e.reference
    palette.item = e.item
    self.itemData = e.itemData
    if e.reference and not e.item then
        palette.item = e.reference.object --[[@as JOP.tes3itemChildren]]
    end

    palette.paletteItem = config.paletteItems[palette.item.id:lower()]
    if palette.paletteItem == nil then
        logger:debug("%s is not a palette", palette.item.id)
        return nil
    end
    palette.dataHolder = (e.itemData ~= nil) and e.itemData or e.reference
    palette.data = setmetatable({}, {
        __index = function(_, k)
            if not (
                palette.dataHolder
                and palette.dataHolder.data
                and palette.dataHolder.data.joyOfPainting
            ) then
                return nil
            end
            return palette.dataHolder.data.joyOfPainting[k]
        end,
        __newindex = function(_, k, v)
            if palette.dataHolder == nil then
                logger:debug("Setting value %s and dataHolder doesn't exist yet", k)
                if not palette.reference then
                    logger:debug("palette.item: %s", palette.item)
                    --create itemData
                    palette.dataHolder = tes3.addItemData{
                        to = tes3.player,
                        item = palette.item.id,
                    }
                    if palette.dataHolder == nil then
                        logger:error("Failed to create itemData for palette")
                        return
                    end
                end
            end
            if not ( palette.dataHolder.data and palette.dataHolder.data.joyOfPainting) then
                palette.dataHolder.data.joyOfPainting = {}
            end
            palette.dataHolder.data.joyOfPainting[k] = v
        end
    })
    return palette
end

function Palette:use()
    if self:getRemainingUses() > 0 then
        logger:debug("Using up paint for %s", self.item.id)
        if not self.data.uses then
            self.data.uses = self.paletteItem.uses
        end
        self.data.uses = self.data.uses - 1
        NodeManager.updateSwitch("paint_palette")
        if self.paletteItem.breaks and self.data.uses == 0 then
            logger:debug("Palette has no more uses, removing")
            if self.reference then
                self.reference:delete()
            else
                tes3.removeItem{
                    reference = tes3.player,
                    item = self.item,
                    itemData = self.itemData,
                    playSound = false,
                }
            end
        end
        return true
    end
    logger:debug("Palette has no more uses")
    return false
end


---@return JOP.PaintType
function Palette:getPaintType()
    return config.paintTypes[self.paletteItem.paintType]
end

function Palette:initRefillMenuActivator()
    local paintType = self:getPaintType()

    config.paintTypes[paintType.id].refillMenu = CraftingFramework.MenuActivator:new{
        id = "JOP_RefillPaint_" .. paintType.id,
        name = string.format("Refill %s", paintType.name),
        type = "event",
        defaultFilter = "all",
        defaultShowCategories = false,
        closeCallback = function() end,
        craftButtonText = "Refill",
        showCollapseCategoriesButton = false,
        showCategoriesButton = false,
        showFilterButton = false,
        showSortButton = false,
    }
end

function Palette:updateRecipes()
    local paintType = self:getPaintType()
    if not paintType.refillMenu then
        self:initRefillMenuActivator()
    end

    ---@type craftingFrameworkRecipeData[]
    local recipes = {}
    for _, refill in pairs(config.refills[paintType.id]) do
        logger:debug("Adding %s to refill recipes", refill.recipe.id)
        table.insert(recipes, refill.recipe)
    end
    paintType.refillMenu:registerRecipes(recipes)
end

function Palette.getPaletteToRefill()
    return tes3.player.tempData.jop_paletteToRefill
end

function Palette:setPaletteToRefill()
    tes3.player.tempData.jop_paletteToRefill = self
end

function Palette:openRefillMenu()
    local paintType = self:getPaintType()
    self:updateRecipes()
    self:setPaletteToRefill()
    paintType.refillMenu:openMenu()
end

function Palette:doRefill()
    self.data.uses = self.paletteItem.uses
    NodeManager.updateSwitch("paint_palette")
end

function Palette:getRefills()
    local paintType = self:getPaintType()
    return config.refills[paintType.id]
end

function Palette:hasRefillRecipes()
    local refills = self:getRefills()
    return refills ~= nil and #refills > 0
end

---@return number
function Palette:getRemainingUses()
    if not self.data.uses then
        if self.paletteItem.fullByDefault then
            return self.paletteItem.uses
        else
            return 0
        end
    end
    return self.data.uses
end

---@return number
function Palette:getMaxUses()
    return self.paletteItem.uses
end

function Palette.isPalette(id)
    return config.paletteItems[id:lower()] ~= nil
end

return Palette