--[[
Example resource that uses NandoCrypt to decrypt models and replace them.
]]

local replaceList = {
    {507, "mods/elegant.txd.nandocrypt", "mods/elegant.dff.nandocrypt"},
}

addEventHandler("onClientResourceStart", resourceRoot,
function()
    if type(ncDecrypt) ~= "function" then
        return outputDebugString("Decrypt function not loaded", 0, 255,0,0)
    end
    for k,v in pairs(replaceList) do
        local model = v[1]
        for i,w in pairs({
            {path=v[2], type="txd"},
            {path=v[3], type="dff"},
            {path=v[4], type="col"},
        }) do
            if w.path ~= nil then
                local worked = ncDecrypt(w.path,
                    function(data)
                        if w.type == "txd" then
                            print(("Replacing %s (TXD) for model %d"):format(w.path, model))
                            engineImportTXD(engineLoadTXD(data), model)
                        elseif w.type == "dff" then
                            print(("Replacing %s (DFF) for model %d"):format(w.path, model))
                            engineReplaceModel(engineLoadDFF(data), model)
                        elseif w.type == "col" then
                            print(("Replacing %s (COL) for model %d"):format(w.path, model))
                            engineReplaceCOL(engineLoadCOL(data), model)
                        end
                    end
                )
                if not worked then
                    return outputDebugString("Decryption of '"..w.path.."' failed", 0, 255,0,0)
                end
            end
        end
    end
end)