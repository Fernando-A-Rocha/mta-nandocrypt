local thisRes = getThisResource()
local thisResName = getResourceName(thisRes)
local scriptVersion

local ENCRYPTED_EXT = ".nandocrypt"

-- Extra security to hide the secret key from people who can access server files
local COMPILE_DERCRYPTER = true

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

function clearDecrypterKeys(thePlayer, cmd)
	local kfn = "nando_decrypter_keys"
	if fileExists(kfn) then
		fileDelete(kfn)
		outputChatBox(kfn.." deleted.", thePlayer, 0,255,0)
	else
		outputChatBox(kfn.." already deleted.", thePlayer, 255,194,14)
	end
end
addCommandHandler("nclearkeys", clearDecrypterKeys, false, false)

function createDecrypter(secretKey, iv, encodedContent, player)
	local ivList = {}
	local kfn = "nando_decrypter_keys"
	local kf
	local opened = false
	if fileExists(kfn) then
		opened = true
		kf = fileOpen(kfn)
		if not kf then
			return outputChatBox("Failed to open: "..kfn, player, 255,25,25)
		end
	end
	if opened then
		local kfJson = fileRead(kf, fileGetSize(kf))
		if not kfJson then
			fileClose(kf)
			return outputChatBox("Failed to read: "..kfn, player, 255,25,25)
		end
		if kfJson ~= "" then
			ivList = fromJSON(kfJson)
		end
		fileClose(kf)
		
		if not ivList then
			iprint(kfJson)
			return outputChatBox("Failed to read IV keys from: "..kfn, player, 255,25,25)
		end
		fileDelete(kfn)
	end

	local kf = fileCreate(kfn)
	if not kf then
		return outputChatBox("Failed to create: "..kfn, player, 255,25,25)
	end

	local iv64 = base64Encode(iv)
	local encodedContentHash = md5(encodedContent)
	ivList[encodedContentHash] = iv64

	iprint("ivList", ivList)

	fileWrite(kf, toJSON(ivList))
	fileClose(kf)

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
-- which is stored in this cached & Luac protected file.
function ncDecrypt(file, callbackFunc)
if type(file) ~= "string" then return false, "File path not string" end
if type(callbackFunc) ~= "function" then return false, "Callback function invalid" end
if not fileExists(file) then return false, "File doesn't exist" end
local f = fileOpen(file)
if not f then return false, "Failed to open file" end
local fsize = fileGetSize(f)
if not fsize then
fileClose(f)
return false, "Failed to get file size"
end
local content = fileRead(f, fsize)
fileClose(f)
if (not content) or (content == "") then return false, "Failed to read file content or empty" end
local ivList = fromJSON('%s')
local contentHash = md5(content)
local theIV = ivList[contentHash]
if not theIV then
print(contentHash)
iprint(ivList)
return false, "Missing IV key for file content base64"
end
return decodeString("aes128", content, { key = base64Decode('%s'), iv = base64Decode(theIV) }, callbackFunc)
end
]], toJSON(ivList), base64Encode(secretKey))

	fileWrite(f, content)
	fileClose(f)

	-- Skip compilation:
	if (not COMPILE_DERCRYPTER) then
		outputChatBox("Created '"..fn.."'", player, 25,255,25)
		outputChatBox("Restarting "..thisResName.." resource..", player, 187,187,187)
		restartResource(thisRes)

	else
		outputChatBox("Created '"..fn.."', compiling..", player, 25,255,25)
		fetchRemote("https://luac.mtasa.com/?compile=1&debug=0&obfuscate=3", compileCallback, content, true, fn, player)
	end
end

function encryptFile(fpath, secretKey, player)

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
	local encoded, iv = encodeString("aes128", fileContent, { key = secretKey })
	-- iv depends on data encrypted
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

	createDecrypter(secretKey, iv, encoded, player)
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
	local worked, reason = ncDecrypt(filePath,
		function(data)
			outputChatBox("Decryption of '"..filePath.."' worked", thePlayer, 225,255,0)
		end
	)
	if not worked then
		return outputChatBox("Decrypt function failed: "..tostring(reason), thePlayer, 255,0,0)
	end
end
addEvent(thisResName..":requestDecryptFile", true)
addEventHandler(thisResName..":requestDecryptFile", resourceRoot, requestDecryptFile)

function requestEncryptFile(filePath, secretKey)
	encryptFile(filePath, secretKey, client)
end
addEvent(thisResName..":requestEncryptFile", true)
addEventHandler(thisResName..":requestEncryptFile", resourceRoot, requestEncryptFile)


addEventHandler( "onResourceStart", resourceRoot, 
function (startedResource)
	math.randomseed(os.time())

	local ver = getResourceInfo(startedResource, "version")
	scriptVersion = ((ver and "v"..ver) or "Unknown Version")
end)