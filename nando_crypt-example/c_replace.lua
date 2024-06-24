--[[
Example resource that uses NandoCrypt to decrypt models and replace them.
]]

local NANDOCRYPT_EXT = ".nandocrypt"

-- Possible keys: model, txd, dff, col, lodDistance
local replaceList = {
    {model=507, txd="mods/elegant.txd.nandocrypt", dff="mods/elegant.dff.nandocrypt"},
    {model=955, txd="mods/sprunk.txd.nandocrypt", dff="mods/sprunk.dff.nandocrypt"},
}

local function isEncrypted(filePath)
    return filePath:sub(-#NANDOCRYPT_EXT) == NANDOCRYPT_EXT
end

local function applyMod(data, theType, model)
    if theType == "txd" then
        return engineImportTXD(engineLoadTXD(data), model)
    elseif theType == "dff" then
        return engineReplaceModel(engineLoadDFF(data), model)
    elseif theType == "col" then
        return engineReplaceCOL(engineLoadCOL(data), model)
    end
end

local function loadOneMod(theType, path, model)
    if isEncrypted(path) then
        if not ncDecrypt(path,
            function(data)
                applyMod(data, theType, model)
            end
        ) then
            outputDebugString("Decryption of '"..path.."' failed", 1)
        end
    else
        applyMod(path, theType, model)
    end
end

local function replaceMods()

	for k,v in pairs(replaceList) do
        local model = v.model
        if type(model) ~= "number" then
        	outputDebugString("Missing model ID in replace list #"..k, 1)
        	return
        end

        local col = v.col
        if col then
            loadOneMod("col", col, model)
        end
        local txd = v.txd
        if txd then
            loadOneMod("txd", txd, model)
        end
        local dff = v.dff
        if dff then
            loadOneMod("dff", dff, model)
        end
	end
end

local function applyLodDistances()

    for k,v in pairs(replaceList) do
        local model = v.model
        if type(model) ~= "number" then
        	outputDebugString("Missing model ID in replace list #"..k, 1)
        	return false
        end

        local lodDistance = v.lodDistance
        if type(lodDistance) == "number" then
        	engineSetModelLODDistance(model, lodDistance)
        end
    end

    return true
end

addEventHandler("onClientResourceStart", resourceRoot,
function()
    if type(ncDecrypt) ~= "function" then
        return outputDebugString("Nando Decrypt clientside function not loaded", 0, 255,0,0)
    end

    if not applyLodDistances() then return end

    replaceMods()
end)
