local thisRes = getThisResource()
local thisResName = getResourceName(thisRes)
local ver = getResourceInfo(thisRes, "version")
local scriptVersion = ((ver and "v"..ver) or "Unknown Version")

local FN_DECRYPTER_SCRIPT = "nando_decrypter"
local FN_DECRYPTER_KEYS = "nando_decrypter_keys.json"
local FN_ENCRYPT_LOGS = "nando_encrypt.log"

local ENCRYPTED_EXT = ".nandocrypt"

-- Extra security to hide the secret key from people who can access server files
local COMPILE_DERCRYPTER = true
local COMPILE_URL = "https://luac.mtasa.com/?compile=1&debug=0&obfuscate=3"

addEvent(thisResName..":requestDecryptFile", true)
addEvent(thisResName..":requestEncryptFile", true)

function compileCallback(responseData, responseInfo, fn, player)

	local errorCodes = {
		["ERROR Nothing to do - Please select compile and/or obfuscate"] = true,
		["ERROR Could not compile file"] = true,
		["ERROR Could not read file"] = true,
		["ERROR Already compiled"] = true,
		["ERROR Already encrypted"] = true,
	}

	if responseInfo.success then

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

function encryptFile(fpath, secretKey, player)

	if not fileExists(fpath) then
		outputChatBox("File doesn't exist: "..fpath, player, 255,25,25)
		return false
	end
	local ef = fileOpen(fpath)
	if not ef then
		outputChatBox("Failed to open: "..fpath, player, 255,25,25)
		return false
	end
	local fileContent = fileRead(ef, fileGetSize(ef))
	fileClose(ef)
	if (not fileContent) or (fileContent == "") then
		outputChatBox("Failed to read or file is empty: "..fpath, player, 255,25,25)
		return false
	end

	local encoded, iv = encodeString("aes128", fileContent, { key = secretKey })
	-- iv depends on data encrypted
	if not encoded then
		outputChatBox("Encoding algorithm failed", player, 255,25,25)
		return false
	end
	local encodedContentHash = md5(encoded)

	local ivList = {}
	local kfn = FN_DECRYPTER_KEYS
	local kf
	local opened = false
	if fileExists(kfn) then
		opened = true
		kf = fileOpen(kfn)
		if not kf then
			outputChatBox("Failed to open: "..kfn, player, 255,25,25)
			return false
		end
	end
	if opened then
		local kfJson = fileRead(kf, fileGetSize(kf))
		fileClose(kf)
		if not kfJson then
			outputChatBox("Failed to read: "..kfn, player, 255,25,25)
			return false
		end
		if kfJson ~= "" then
			ivList = fromJSON(kfJson)
			if not ivList then
				outputChatBox("Failed to read IV keys from: "..kfn, player, 255,25,25)
				return false
			end
		end
		fileDelete(kfn)
	end
	kf = fileCreate(kfn)
	if not kf then
		outputChatBox("Failed to create: "..kfn, player, 255,25,25)
		return false
	end

	local efnn = fpath..ENCRYPTED_EXT
	if fileExists(efnn) then
		local efn = fileOpen(efnn)
		if not efn then
			outputChatBox("Failed to open: "..efnn, player, 255,25,25)
			return false
		end
		-- delete old useless hash
		local efnContent = fileRead(efn, fileGetSize(efn))
		fileClose(efn)
		if not efnContent then
			outputChatBox("Failed to read: "..efnn, player, 255,25,25)
			return false
		end
		local encodedContentHash_old = md5(efnContent)
		if ivList[encodedContentHash_old] then
			ivList[encodedContentHash_old] = nil
			outputChatBox("Deleting old hash '"..encodedContentHash_old.."' from stored keys", player, 255,126,0)
		end
		fileDelete(efnn)
	end
	local efn = fileCreate(efnn)
	if not efn then
		outputChatBox("Failed to open: "..efnn, player, 255,25,25)
		return false
	end
	fileWrite(efn, encoded)
	fileClose(efn)

	outputChatBox("Encrypted '"..fpath.."' into '"..efnn.."'", player, 25,255,25)


	local iv64 = encodeString("base64", iv)
	ivList[encodedContentHash] = iv64

	fileWrite(kf, toJSON(ivList))
	fileClose(kf)

	local fn = FN_DECRYPTER_SCRIPT
	local f
	if fileExists(fn) then
		fileDelete(fn)
	end
	f = fileCreate(fn)
	if not f then
		outputChatBox("Failed to open: "..fn, player, 255,25,25)
		return false
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
		return false, "Missing IV key for file content base64"
	end
	return decodeString("aes128", content, { key = decodeString("base64", '%s'), iv = decodeString("base64", theIV) }, callbackFunc)
end
]], toJSON(ivList), encodeString("base64", secretKey))

	fileWrite(f, content)
	fileClose(f)

	addEncryptLog(
		"Encrypted file '"..fpath.."' and obtained hash '"..encodedContentHash.."'. Corresponding IV stored in '"..kfn.."'."
	)

	outputChatBox("Created '"..fn.."'", player, 25,255,25)
	return true
end

function addEncryptLog(msg)
	local lfn = FN_ENCRYPT_LOGS
	local lf
	if fileExists(lfn) then
		lf = fileOpen(lfn)
	else
		lf = fileCreate(lfn)
	end
	if not lf then
		outputDebugString("Failed to create/open file: "..lfn, 0, 255,25,25)
		return false
	end
	local lfc = fileRead(lf, fileGetSize(lf))
	if not lfc then
		outputDebugString("Failed to read file: "..lfn, 0, 255,25,25)
		return false
	end

	local time = getRealTime()
	local stamp = "[" ..string.format("%02d:%02d:%02d", time.hour, time.minute, time.second).." "..string.format("%04d-%02d-%02d", time.year+1900, time.month+1, time.monthday).."] "

	fileWrite(lf, stamp .. msg.. "\n")
	fileClose(lf)
	return true
end

local function getFilesInFolderRecursively(parentPath, folderName)
	local files = {}
	local parentFolder
	if parentPath then
		parentFolder = parentPath .. "/" .. folderName
	else
		parentFolder = folderName
	end
	for _, fileOrFolder in pairs(pathListDir(parentFolder) or {}) do
		local thisPath = parentFolder.."/"..fileOrFolder
		if pathIsFile(thisPath) then
			if fileOrFolder ~= '.keep' then
				files[#files+1] = thisPath
			end
		elseif pathIsDirectory(thisPath) then
			local subFiles = getFilesInFolderRecursively(parentFolder, fileOrFolder)
			for _, subFile in pairs(subFiles) do
				files[#files+1] = subFile
			end
		end
	end
	return files
end

local function requestMenu(thePlayer, cmd, option)
	if not (option == "menu" or option == "loadfiles") then
		return outputChatBox("SYNTAX: /"..cmd.." menu|loadfiles", thePlayer, 255,255,0)
	end
	if option == 'menu' then
		triggerClientEvent(thePlayer, thisResName..":openMenu", thePlayer, scriptVersion)
	elseif option == 'loadfiles' then
		local files = getFilesInFolderRecursively(nil, "files")
		local files2 = {}
		for _, file in pairs(files) do
			files2[file] = true
			outputChatBox(" - ".. file, thePlayer, 187,187,187)
		end
		outputChatBox("Found "..#files.." files inside the files folder", thePlayer, 25,255,25)
		triggerClientEvent(thePlayer, thisResName..":loadFileListFromServer", thePlayer, files2)
	end
end
addCommandHandler("nandocrypt", requestMenu, false, false)

function requestDecryptFile(filePaths)
	if not client then return end
	if type(ncDecrypt) ~= "function" then
		return outputChatBox("Decryption function not loaded (check if "..FN_DECRYPTER_SCRIPT.." is valid)", client, 255,0,0)
	end
	for filePath,_ in pairs(filePaths) do
		filePath = filePath..ENCRYPTED_EXT
		local worked, reason = ncDecrypt(filePath,
			function(data)
				outputChatBox("Decryption of '"..filePath.."' worked", client, 225,255,0)
			end
		)
		if not worked then
			return outputChatBox("Aborting, decryption of '"..filePath.."' failed: "..tostring(reason), client, 255,0,0)
		end
	end
end
addEventHandler(thisResName..":requestDecryptFile", resourceRoot, requestDecryptFile, false)

function requestEncryptFile(filePaths, secretKey)
	for filePath,_ in pairs(filePaths) do
		if not encryptFile(filePath, secretKey, client) then
			outputChatBox("Aborted encryptions.", client, 255,255,0)
			break
		end
	end

	if not COMPILE_DERCRYPTER then
		outputChatBox("Restarting "..thisResName.." resource..", client, 187,187,187)
		restartResource(thisRes)
	else
		local fn = FN_DECRYPTER_SCRIPT
		local f = fileOpen(fn)
		if not f then
			return outputChatBox("Failed to open: "..fn, client, 255,25,25)
		end
		local content = fileRead(f, fileGetSize(f))
		fileClose(f)
		if not content or content == "" then
			return outputChatBox("File is empty: "..fn, client, 255,25,25)
		end
		outputChatBox("Compiling '"..fn.."'..", client, 75,255,75)
		fetchRemote(COMPILE_URL, {
			queueName='nandocrypt_comp',
			method="POST",
			postData=content,
		}, compileCallback, {fn, client})
	end
end
addEventHandler(thisResName..":requestEncryptFile", resourceRoot, requestEncryptFile, false)
