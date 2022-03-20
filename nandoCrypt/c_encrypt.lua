local thisRes = getThisResource()
local thisResName = getResourceName(thisRes)

local SW, SH = guiGetScreenSize()
local window, window2

local savedFileName, secretKey

function openMenu(version)
	closeMenu()

	guiSetInputMode("no_binds_when_editing")
	showCursor(true)

	if savedFileName == nil then
		local data = getElementData(localPlayer, thisResName..":savedFileName")
		if data then
			savedFileName = data
			outputChatBox("Loaded last used file name from localPlayer element data", 180,180,180)
		else
			savedFileName = "files/"
		end
	end
	if secretKey == nil then
		local data = getElementData(localPlayer, thisResName..":lastUsedSecretKey")
		if data then
			secretKey = data
			outputChatBox("Loaded last used secret key from localPlayer element data", 180,180,180)
		end
	end

	local WW, WH = 500, 205
	window = guiCreateWindow(SW/2 - WW/2, SH/2 - WH/2, WW, WH, "NandoCrypt ("..version..")", false)

	local close = guiCreateButton(10, WH-40, WW-20, 30, "Close", false, window)

	local setkey = guiCreateButton(10, WH-75, WW-20, 30, "", false, window)
	if (secretKey ~= nil) then
		guiSetText(setkey, "Change Secret Key")
		guiSetProperty(setkey, "NormalTextColour", "FFFFFF00")
	else
		guiSetText(setkey, "Set Secret Key")
		guiSetProperty(setkey, "NormalTextColour", "FF00FF00")
	end

	local decrypt = guiCreateButton(10, WH-110, WW-20, 30, "Decrypt File (Test)", false, window)
	if (secretKey ~= nil) then
		guiSetProperty(decrypt, "NormalTextColour", "ff6373ff")
	else
		guiSetEnabled(decrypt, false)
		guiSetProperty(decrypt, "NormalTextColour", "FFFF0000")
	end

	local encrypt = guiCreateButton(10, WH-145, WW-20, 30, "Encrypt File", false, window)
	if (secretKey ~= nil) then
		guiSetProperty(encrypt, "NormalTextColour", "FFFFFFFF")
	else
		guiSetEnabled(encrypt, false)
		guiSetProperty(encrypt, "NormalTextColour", "FFFF0000")
	end

	local file_edit = guiCreateEdit(10, WH-180, WW-20, 30, savedFileName, false, window)
	if (secretKey ~= nil) then
		addEventHandler( "onClientGUIChanged", file_edit, 
		function (theElement)
			savedFileName = guiGetText(source)
			setElementData(localPlayer, thisResName..":savedFileName", savedFileName, false)
		end, false)
	else
		guiSetText(file_edit, "A secret key & decrypter file needs to be generated 1st")
		guiSetEnabled(file_edit, false)
	end

	addEventHandler( "onClientGUIClick", window, 
	function (button, state, absoluteX, absoluteY)
		if button ~= "left" then return end

		if source == close then
			closeMenu()
		
		elseif source == setkey then
			openChangeKeyMenu()
		
		elseif source == encrypt or source == decrypt then
			local filePath = guiGetText(file_edit)
			if filePath == "" then
				return outputChatBox("You need to enter a valid serverside file path.", 255,25,25)
			end
			closeMenu()

			if source == encrypt then
				triggerServerEvent(thisResName..":requestEncryptFile", resourceRoot, filePath, secretKey, getElementData(localPlayer, thisResName..":lastUsedSecretKey") or nil)
				setElementData(localPlayer, thisResName..":lastUsedSecretKey", secretKey, false)
			elseif source == decrypt then
				triggerServerEvent(thisResName..":requestDecryptFile", resourceRoot, filePath)
			end
		end
	end)
end
addEvent(thisResName..":openMenu", true)
addEventHandler(thisResName..":openMenu", resourceRoot, openMenu)

function closeMenu()
	if isElement(window) then destroyElement(window) end
	if isElement(window2) then destroyElement(window2) end
	window = nil
	window2 = nil
	showCursor(false)
	guiSetInputMode("allow_binds")
end

function openChangeKeyMenu()
	if isElement(window) then
		guiSetVisible(window, false)
	end
	if isElement(window2) then destroyElement(window2) end

	local title = "Set Secret Key"
	if (secretKey ~= nil) then
		title = "Change Secret Key"
	end

	local WW, WH = 400, 135
	window2 = guiCreateWindow(SW/2 - WW/2, SH/2 - WH/2, WW, WH, title, false)

	local close = guiCreateButton(10, WH-40, WW-20, 30, "Cancel", false, window2)

	local setkey = guiCreateButton(10, WH-75, WW-20, 30, "Update", false, window2)
	guiSetProperty(setkey, "NormalTextColour", "FF00FF00")

	local key_edit = guiCreateEdit(10, WH-110, WW-20 - 50, 30, secretKey or "", false, window2)

	local random = guiCreateButton(WW-50, WH-110, 50, 30, "R", false, window2)
	guiSetProperty(random, "NormalTextColour", "ffdc7aff")


	addEventHandler( "onClientGUIClick", window2, 
	function (button, state, absoluteX, absoluteY)
		if button ~= "left" then return end

		if source == close then
			closeChangeKeyMenu()

		elseif source == random then
			guiSetText(key_edit, genRandomString(math.random(32, 64)))
		
		elseif source == setkey then
			local key = guiGetText(key_edit)
			if key == "" then
				return outputChatBox("You need to enter a valid secret key (min 32 characters) or click randomize.", 255,25,25)
			end
			if string.len(key) < 32 then
				return outputChatBox("Key must be at least 32 characters long. Click randomize to generate one automatically.", 255,25,25)
			end
			secretKey = key
			setClipboard(secretKey)
			outputChatBox(secretKey, 0,255,255)
			outputChatBox("Save the new secret key somewhere private! #ffffff(copied to clipboard)", 255,126,0, true)
			outputChatBox("It will be used for encrypting files in the server. Leaking this key may compromise the encrypted files.", 255,194,14)
			closeMenu()
		end
	end)
end

function closeChangeKeyMenu()
	if isElement(window2) then destroyElement(window2) end
	window2 = nil

	if isElement(window) then
		guiSetVisible(window, true)
	end
end

function genRandomString(length)
	local rstring = ""
	local chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
	for i = 1, length do
		local rand = math.random(#chars)
		rstring = rstring .. chars:sub(rand, rand)
	end
	return rstring
end