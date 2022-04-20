--[[
Example resource that uses NandoCrypt to decrypt models and replace them.
]]

local replaceList = { -- Possible keys: model, txd, dff, col, lodDistance
    {model=507, txd="mods/elegant.txd.nandocrypt", dff="mods/elegant.dff.nandocrypt"},
    {model=955, txd="mods/sprunk.txd.nandocrypt", dff="mods/sprunk.dff.nandocrypt"},
}

function checkReplaceCompleted(theType)
	local count = 0
	for k,v in pairs(replaceList) do
		if (not v[theType.."_loaded"]) then
			return false
		else
			count = count + 1
		end
	end
	print("Replaced a total of "..count.." "..string.upper(theType).." mod files")
	return true
end

function replaceMods(theType)

	for k,v in pairs(replaceList) do
        local model = v.model
        if type(model) ~= "number" then
        	outputDebugString("Missing model ID in replace list #"..k, 1)
        	return
        end

        local path = v[theType]
        if type(path)=="string" then
			if theType == "txd" then
                local worked = ncDecrypt(path,
                    function(data)
                        if engineImportTXD(engineLoadTXD(data), model) then
                        	print(("Replaced %s (%s) for model %d"):format(path, string.upper(theType), model))
                        end
                        replaceList[k][theType.."_loaded"] = true
                        if checkReplaceCompleted("txd") then replaceMods("dff") end
                    end
                )
                if not worked then
                	outputDebugString("ABORTING: Decryption of '"..path.."' failed", 1)
                    return
                end
			elseif theType == "dff" then
                local worked = ncDecrypt(path,
                    function(data)
                        if engineReplaceModel(engineLoadDFF(data), model) then
                        	print(("Replaced %s (%s) for model %d"):format(path, string.upper(theType), model))
                        end
                        replaceList[k][theType.."_loaded"] = true
                        if checkReplaceCompleted("dff") then replaceMods("col") end
                    end
                )
                if not worked then
                	outputDebugString("ABORTING: Decryption of '"..path.."' failed", 1)
                    return
                end
			elseif theType == "col" then
				local worked = ncDecrypt(path,
                    function(data)
                        if engineReplaceCOL(engineLoadCOL(data), model) then
                        	print(("Replaced %s (%s) for model %d"):format(path, string.upper(theType), model))
                        end
                        replaceList[k][theType.."_loaded"] = true
                        checkReplaceCompleted("col")
                    end
                )
                if not worked then
                	outputDebugString("ABORTING: Decryption of '"..path.."' failed", 1)
                    return
                end
			end
		end
	end
end

function applyLodDistances()

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
        return outputDebugString("Decrypt function not loaded", 0, 255,0,0)
    end

    if not applyLodDistances() then return end

    -- Correct load order: TXD -> DFF -> COL
    replaceMods("txd")
end)