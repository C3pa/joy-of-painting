local common = require("mer.joyOfPainting.common")
local config = require("mer.joyOfPainting.config")
local logger = common.createLogger("SkillService")

local SkillService = {}

SkillService.skills = {}


--Painting skill determines how "blobby" the paint effect is
function SkillService.getDetailLevel()
    local paintingSkill = SkillService.skills.painting.value
    local MAX_RADIUS = config.skillPaintEffect.MAX_RADIUS
    local MIN_RADIUS = config.skillPaintEffect.MIN_RADIUS
    local MIN_SKILL = config.skillPaintEffect.MIN_SKILL
    local MAX_SKILL = config.skillPaintEffect.MAX_SKILL
    local MAX_RANDOM = config.skillPaintEffect.MAX_RANDOM
    local paintRadius = math.remap(paintingSkill, MIN_SKILL, MAX_SKILL, MAX_RADIUS, MIN_RADIUS)
    paintRadius = paintRadius + math.random(0, MAX_RANDOM*100)/100
    paintRadius = math.max(paintRadius, 0)
    return paintRadius
end

function SkillService.getPaintingValue()
    local paintingSkill = SkillService.skills.painting.value
    local MAX_GOLD = config.skillGoldEffect.MAX_GOLD
    local MIN_GOLD = config.skillGoldEffect.MIN_GOLD
    local MIN_SKILL = config.skillGoldEffect.MIN_SKILL
    local MAX_SKILL = config.skillGoldEffect.MAX_SKILL
    local MAX_RANDOM = config.skillGoldEffect.MAX_RANDOM
    local goldValue = math.remap(paintingSkill, MIN_SKILL, MAX_SKILL, MIN_GOLD, MAX_GOLD)
    goldValue = goldValue + math.random(0, MAX_RANDOM)
    return goldValue
end

local function initRegionsTable()
    if tes3.player.data.joyOfPainting == nil then
        tes3.player.data.joyOfPainting = {}
    end
    if tes3.player.data.joyOfPainting.paintedRegions == nil then
        tes3.player.data.joyOfPainting.paintedRegions = {}
    end
end

local function isNewRegion(location)
    initRegionsTable()
    return tes3.player.data.joyOfPainting.paintedRegions[location] == nil
end

function SkillService.progressSkillFromPainting()
    local location = tes3.player.cell.displayName
    local paintingSkill = SkillService.skills.painting
    local BASE_PROGRESS = config.skillProgress.BASE_PROGRESS_PAINTING
    local NEW_REGION_MULTI = config.skillProgress.NEW_REGION_MULTI
    local progress = BASE_PROGRESS
    logger:debug("Base progress is %d", progress)
    if isNewRegion(location) then
        logger:debug("New region, multiplying progress by %d", NEW_REGION_MULTI)
        progress = progress * NEW_REGION_MULTI
        tes3.player.data.joyOfPainting.paintedRegions[location] = true
    end
    local rand = math.random(0, config.skillProgress.MAX_RANDOM)
    progress = progress + rand
    logger:debug("Progressing painting skill by %d", progress)
    paintingSkill:progressSkill(progress)
end

return SkillService