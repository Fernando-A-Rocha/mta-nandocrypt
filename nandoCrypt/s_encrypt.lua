local thisRes = getThisResource()
local thisResName = getResourceName(thisRes)
local scriptVersion

local ENCRYPTED_EXT = ".nandocrypt"

function compileCallback(responseData, responseError, fn, player)

	local errorCodes = {
		["ERROR Nothing to do - Please select compile and/or obfuscate"] = true,
		["ERROR Could not compile file"] = true,
		["ERROR Could not read file"] = true,
		["ERROR Already compiled"] = true,
		["ERROR Already encrypted"] = true,
	}

	if responseError == 0 then

		if errorCodes[responseData] == true then
			return outputChatBox("#ffffffLuac: #ff0000'"..fn.."' failed to compile: "..responseData, player, 255,255,255, true)
		end

		if fileExists(fn) then
			fileDelete(fn)
		end
		local f = fileCreate(fn)
		if not f then
			return outputChatBox("Failed to create (upon Luac): "..fn, player, 255,255,255, true)
		end

		fileWrite(f, responseData)
		fileClose(f)

		outputChatBox("#ffffffLuac: #00ff00'"..fn.."' compiled successfully", player, 255,255,255, true)

		outputChatBox("Copy this file to your resource and include it in meta.xml with type='client' and cache='false'", player, 255,194,14)

		outputChatBox("Restarting "..thisResName.." resource..", player, 187,187,187)
		restartResource(thisRes)
	else
		outputChatBox("#ffffffLuac: #ff0000'"..fn.."' failed to compile", player, 255,255,255, true)
	end
end

function createDecrypter(secretKey, player)
	local fn = "nando_decrypter"
	local f
	if fileExists(fn) then
		fileDelete(fn)
	end
	f = fileCreate(fn)
	if not f then
		return outputChatBox("Failed to open: "..fn, player, 255,25,25)
	end

	local content = string.format(
[[-- Created by Nando
-- This decrypts a file (given path) using a secret key
-- which is stored in this Luac protected file.
function ncDecrypt(file, callbackFunc)
	if type(file) ~= "string" then return false end
	if type(callbackFunc) ~= "function" then return false end
	if not fileExists(file) then return false end
	local f = fileOpen(file)
	if not f then return false end
	local content = fileRead(f, fileGetSize(f))
	fileClose(f)
	if (not content) or (content == "") then return false end
	return decodeString("tea", content, { key = '%s' }, callbackFunc)
end
]], secretKey)

	fileWrite(f, content)
	fileClose(f)

	outputChatBox("Created '"..fn.."', compiling..", player, 25,255,25)

	fetchRemote("https://luac.mtasa.com/?compile=1&debug=0&obfuscate=3", compileCallback, content, true, fn, player)
end

function encryptFile(fpath, secretKey, lastUsedSecretKey, player)

	if not fileExists(fpath) then
		return outputChatBox("File doesn't exist: "..fpath, player, 255,25,25)
	end
	local ef = fileOpen(fpath)
	if not ef then
		return outputChatBox("Failed to open: "..fpath, player, 255,25,25)
	end
	local fileContent = fileRead(ef, fileGetSize(ef))
	fileClose(ef)
	if (not fileContent) or (fileContent == "") then
		return outputChatBox("Failed to read or file is empty: "..fpath, player, 255,25,25)
	end
	local encoded = encodeString("tea", fileContent, { key = secretKey })
	if not encoded then
		return outputChatBox("Encoding algorithm failed", player, 255,25,25)
	end
	local efnn = fpath..ENCRYPTED_EXT
	if fileExists(efnn) then fileDelete(efnn) end
	local efn = fileCreate(efnn)
	if not efn then
		return outputChatBox("Failed to open: "..efnn, player, 255,25,25)
	end
	fileWrite(efn, encoded)
	fileClose(efn)

	outputChatBox("Encrypted '"..fpath.."' into '"..efnn.."'", player, 25,255,25)

	if (lastUsedSecretKey == nil) or (lastUsedSecretKey ~= secretKey) then
		createDecrypter(secretKey, player)
	end
end


function requestMenu(thePlayer, cmd)
	-- permission checks here

	triggerClientEvent(thePlayer, thisResName..":openMenu", resourceRoot, scriptVersion)
end
addCommandHandler("NandoCrypt", requestMenu, false, false)

function requestDecryptFile(filePath)
	if type(ncDecrypt) ~= "function" then
		return outputChatBox("Decrypt function not loaded", thePlayer, 255,0,0)
	end
	local result = ncDecrypt(filePath,
		function(data)
			outputChatBox("Decryption of '"..filePath.."' worked", thePlayer, 225,255,0)
		end
	)
	if not result then
		return outputChatBox("Decrypt function returned: "..tostring(result), thePlayer, 255,0,0)
	end
end
addEvent(thisResName..":requestDecryptFile", true)
addEventHandler(thisResName..":requestDecryptFile", resourceRoot, requestDecryptFile)

function requestEncryptFile(filePath, secretKey, lastUsedSecretKey)
	encryptFile(filePath, secretKey, lastUsedSecretKey, client)
end
addEvent(thisResName..":requestEncryptFile", true)
addEventHandler(thisResName..":requestEncryptFile", resourceRoot, requestEncryptFile)


addEventHandler( "onResourceStart", resourceRoot, 
function (startedResource)
	math.randomseed(os.time())

	local ver = getResourceInfo(startedResource, "version")
	scriptVersion = ((ver and "v"..ver) or "Unknown Version")
end)