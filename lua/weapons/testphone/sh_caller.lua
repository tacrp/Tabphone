if SERVER then
	util.AddNetworkString("Tabphone_Call_Receiving")
	util.AddNetworkString("Tabphone_Call_Send")
	util.AddNetworkString("Tabphone_Call_SendConfirmation")
	util.AddNetworkString("Tabphone_Call_Decline")
	util.AddNetworkString("Tabphone_Call_Accept")
	util.AddNetworkString("Tabphone_Call_DontAccept")
	util.AddNetworkString("Tabphone_Call_Ring")
	util.AddNetworkString("Tabphone_Call_YouDidntAnswer")
	util.AddNetworkString("Tabphone_Call_HangUp")
	util.AddNetworkString("Tabphone_Call_HangUp_Recipient")

	util.AddNetworkString("Tabphone_Message")
	util.AddNetworkString("Tabphone_NPCMessage")
end

TP_CALLDECLINE_BUSY = 0
TP_CALLDECLINE_ENDED = 1
TP_CALLCONFIRM_GO = 0
TP_CALLCONFIRM_ALREADY = 1
TP_CALLCONFIRM_DENIED = 2
TP_CALLCONFIRM_NONEXISTANT = 3
TP_CALLCONFIRM_SMARTASS = 4
TP_CALLCONFIRM_ANSWERED = 5

if CLIENT then
	function TabPhone.SIL(text, maxw, font)
		local content = {}
		local tline = ""
		local x = 0
		surface.SetFont(font)
	
		local ts = surface.GetTextSize(" ")
	
		local newlined = string.Explode("\n", text)
	
		for _newlines, line in ipairs(newlined) do
			local words = string.Explode("%s", line, true)
	
			for _words, word in ipairs(words) do
				local tx = surface.GetTextSize(word)

				local looped = false
				if x + tx > maxw then
					local dashi = string.find(word, "-")
					if dashi and surface.GetTextSize(utf8.sub(word, 0, dashi)) <= maxw - x then
						-- cut the word at the dash sign if possible
						table.insert(content, tline .. utf8.sub(word, 0, dashi))
						tline = ""
						x = 0
						word = utf8.sub(word, dashi + 1)
						tx = surface.GetTextSize(word)
						looped = true
					else
						-- move whole word to new line
						if _words == 1 then
							--print( "Line 1 wrapped")
						else
							--print( "didn't line 1 wrap")
							table.insert(content, tline)
							tline = ""
							x = 0
							looped = true
						end
					end
				end
	
				tline = tline .. word
				if looped then
					content[#content] = content[#content]:Left(-2)
				end
				if _words != #words then
					tline = tline .. " "
				end
	
				x = x + tx + ts
			end
	
			table.insert(content, tline)
			tline = ""
			x = 0
		end

		for i, v in ipairs(content) do
			--content[i] = v:Trim()
		end
	
		return content
	end

	net.Receive("TabPhone_Message", function(len, ply)
		local sender = net.ReadEntity()
		local message = net.ReadString()

		if !IsValid(sender) then return end

		local id = "SteamID:" .. sender:SteamID64()

		TabMemory.MessageHistory[id] = TabMemory.MessageHistory[id] or {}

		table.insert(TabMemory.MessageHistory[id], {
			yours = false,
			msg = message,
		})

		if !GetConVar("tabphone_dnd"):GetBool() then
			TabPhone.PlayNotiftone()
		end

		TabMemory.UnreadMessages[id] = true
		TabMemory.Has_Unread = true
	end)

	net.Receive("TabPhone_NPCMessage", function(len, ply)
		local sender = net.ReadString()
		local message = net.ReadString()

		local id = sender

		TabMemory.MessageHistory[id] = TabMemory.MessageHistory[id] or {}

		table.insert(TabMemory.MessageHistory[id], {
			yours = false,
			msg = message,
		})

		if !GetConVar("tabphone_dnd"):GetBool() then
			TabPhone.PlayNotiftone()
		end

		TabMemory.UnreadMessages[id] = true
		TabMemory.Has_Unread = true
	end)

	function TabPhone.SendMessage(ply, message)
		message = message:gsub("%s+", " ")
		message = message:Trim()
		if message == "" then return end
		if TabPhone_MessageDebounceTime > CurTime() then return end

		local id
		local is_to_npc = false

		if isstring(ply) then
			id = ply
			is_to_npc = true
		else
			id = "SteamID:" .. ply:SteamID64()
		end

		TabMemory.MessageHistory[id] = TabMemory.MessageHistory[id] or {}

		table.insert( TabMemory.MessageHistory[id], {
			yours = true,
			msg = message,
		} )

		if !is_to_npc then
			net.Start("TabPhone_Message")
			net.WriteEntity(ply)
			net.WriteString(message)
			net.SendToServer()
		end

		TabPhone_MessageDebounceTime = CurTime() + 0.5
	end

	net.Receive("Tabphone_Call_Ring", function(len, ply)
		TabPhone.StartRingtone()
		local p = LocalPlayer()
		local w = p:GetWeapon("testphone")

		if w:IsValid() then
			--input.SelectWeapon(w)

			if not GetConVar("tabphone_dnd"):GetBool() then
				TabPhone.EnterApp("call")
				TabMemory.CallStatus = "ringing"
				local sender = net.ReadPlayer()
				TabMemory.CallingPlayer = sender
				chat.AddText("You have a call")
			end
		end
	end)

	net.Receive("Tabphone_Call_YouDidntAnswer", function(len, ply)
		local p = LocalPlayer()
		local w = p:GetWeapon("testphone")

		if w:IsValid() then
			if TabMemory.ActiveApp == "call" then
				local sound = TabPhone.RingtonePath .. TabPhone.Ringtones[GetConVar("tabphone_ringtone"):GetInt()]
				LocalPlayer():StopSound(sound)
				TabPhone.EnterApp("mainmenu")
				local nick = "[IDK]"
				local sender = net.ReadPlayer()

				if sender:IsValid() then
					nick = sender:Nick()
				end

				chat.AddText("You missed a call from " .. nick .. ".")
				TabMemory.CallStatus = false
			end
		end
	end)

	net.Receive("Tabphone_Call_Decline", function(len, ply)
		local Reason = net.ReadUInt(4)

		if Reason == TP_CALLDECLINE_BUSY then
			chat.AddText("Busy")
			TabMemory.CallStatus = "busy"
			TabMemory.CallEndTime = UnPredictedCurTime()
			LocalPlayer():EmitSound("fesiug/tabphone/delete.ogg", 100, 100, TabPhone.GetVolume(), CHAN_STATIC)
		elseif Reason == TP_CALLDECLINE_ENDED then
			chat.AddText("Call ended")
			TabMemory.CallStatus = "callended"
			TabMemory.CallEndTime = UnPredictedCurTime()
			LocalPlayer():EmitSound("fesiug/tabphone/delete.ogg", 100, 100, TabPhone.GetVolume(), CHAN_STATIC)
		end
	end)

	net.Receive("Tabphone_Call_SendConfirmation", function(len, ply)
		local Reason = net.ReadUInt(4)

		--TabMemory.CallingPlayer = nil
		if Reason == TP_CALLCONFIRM_GO then
			chat.AddText("Call started")
			TabMemory.CallStatus = "calling"
			TabMemory.CallingPlayer = net.ReadPlayer()
		elseif Reason == TP_CALLCONFIRM_ALREADY then
			chat.AddText("You're already on a call.")
			TabMemory.CallStatus = false
		elseif Reason == TP_CALLCONFIRM_NONEXISTANT then
			chat.AddText("That recipient doesn't exist.")
			TabMemory.CallStatus = false
		elseif Reason == TP_CALLCONFIRM_SMARTASS then
			chat.AddText("Smartass")
			TabMemory.CallStatus = false
		elseif Reason == TP_CALLCONFIRM_ANSWERED then
			chat.AddText("Call answered, listen in")
			TabMemory.CallStatus = "incall"
			TabMemory.CallStartTime = UnPredictedCurTime()
		elseif Reason == TP_CALLCONFIRM_DENIED then
			--TabMemory.CallingPlayer = net.ReadPlayer()
			chat.AddText("You're not allowed to make calls.")
			TabMemory.CallStatus = false
		else
			chat.AddText("Unknown reason " .. Reason .. ".")
		end
	end)

	net.Receive("Tabphone_Call_HangUp_Recipient", function(len, ply) end)
end

Cache_S64ToPly = {}

function S64ToPly(s64)
	if Cache_S64ToPly[s64] and Cache_S64ToPly[s64]:IsValid() then
		return Cache_S64ToPly[s64]
	else
		local res = player.GetBySteamID64(s64)

		if res and res:IsValid() then
			Cache_S64ToPly[s64] = res

			return res
		end
	end

	return false
end

if SERVER then
	TABPHONE_LINES = TABPHONE_LINES or {}
	TABPHONE_LINKER = TABPHONE_LINKER or {}

	local function GetEveryPersonOnThisLine(calldata)
		local okay = {}

		for ply, thecall in pairs(TABPHONE_LINKER) do
			if calldata == thecall then
				table.insert(okay, ply)
			end
		end
		--PrintTable( okay )

		return okay
	end

	net.Receive("TabPhone_Message", function(len, ply)
		local recipient = net.ReadEntity()
		local message = net.ReadString()

		message = message:gsub("%s+", " ")
		message = message:Trim()
		message = string.sub(message, 1, 140)

		if message == "" then return end

		if !IsValid(recipient) then return end
		if !recipient:IsPlayer() then return end
		if (ply.TabPhoneMessageDebounceTime or 0) > CurTime() then return end

		ply.TabPhoneMessageDebounceTime = CurTime() + 0.5

		net.Start("TabPhone_Message")
		net.WriteEntity(ply)
		net.WriteString(message)
		net.Send(recipient)
	end)

	net.Receive("Tabphone_Call_HangUp", function(len, ply)
		local HangUpLine = TABPHONE_LINKER[ply]
		if not HangUpLine then return end
		net.Start("Tabphone_Call_YouDidntAnswer")
		net.WritePlayer(HangUpLine.Sender)
		net.Send(HangUpLine.Recipient)

		for _, line in pairs(TABPHONE_LINES) do
			if HangUpLine == line then
				TABPHONE_LINES[_] = nil
			end
		end

		for i, recip in ipairs(GetEveryPersonOnThisLine(HangUpLine)) do
			net.Start("Tabphone_Call_Decline")
			net.WriteUInt(TP_CALLDECLINE_ENDED, 4)
			net.Send(recip)
			TABPHONE_LINKER[recip] = nil
		end
	end)

	net.Receive("Tabphone_Call_DontAccept", function(len, ply)
		local p = ply
		local w = p:GetWeapon("testphone")
		if w:IsValid() then end
	end)

	net.Receive("Tabphone_Call_Accept", function(len, ply)
		-- Recipient accepts
		for line, calldata in pairs(TABPHONE_LINKER) do
			if calldata.Recipient == ply then
				TABPHONE_LINKER[ply] = calldata
				calldata.CallAccepted = true
				print("Call was accepted")
				net.Start("Tabphone_Call_SendConfirmation")
				net.WriteUInt(TP_CALLCONFIRM_ANSWERED, 4)

				net.Send({calldata.Sender, calldata.Recipient})

				break
			end
		end
	end)

	net.Receive("Tabphone_Call_Send", function(len, ply)
		local Calling = net.ReadString()
		local Reason
		local CallingEnt = S64ToPly(Calling)

		if TABPHONE_LINES[ply] then
			Reason = TP_CALLCONFIRM_ALREADY
		elseif false then
			Reason = TP_CALLCONFIRM_DENIED
		elseif not CallingEnt or not CallingEnt:IsValid() then
			Reason = TP_CALLCONFIRM_NONEXISTANT
		elseif CallingEnt == ply then
			Reason = TP_CALLCONFIRM_SMARTASS
		else
			local wow = {
				StartTime = CurTime(),
				Sender = ply,
				Recipient = CallingEnt,
				CallAccepted = false,
				Ringed = false
			}

			TABPHONE_LINKER[ply] = wow
			table.insert(TABPHONE_LINES, wow)
			Reason = TP_CALLCONFIRM_GO
		end

		net.Start("Tabphone_Call_SendConfirmation")
		net.WriteUInt(Reason, 4)

		if Reason == TP_CALLCONFIRM_GO then
			net.WritePlayer(CallingEnt)
		end

		net.Send(ply)
	end)

	hook.Add("Think", "Tabphone_Think", function()
		for line, calldata in pairs(TABPHONE_LINES) do
			if (calldata.StartTime + 5 <= CurTime()) and not calldata.CallAccepted then
				net.Start("Tabphone_Call_YouDidntAnswer")
				net.WritePlayer(calldata.Sender)
				net.Send(calldata.Recipient)

				for i, recip in ipairs(GetEveryPersonOnThisLine(calldata)) do
					net.Start("Tabphone_Call_Decline")
					net.WriteUInt(TP_CALLDECLINE_BUSY, 4)
					net.Send(recip)
					TABPHONE_LINKER[recip] = nil
				end

				TABPHONE_LINES[line] = nil
				--TABPHONE_LINES[ply] = nil
				continue
			elseif (calldata.StartTime + 0.5 <= CurTime()) and not calldata.CallAccepted and not calldata.Ringed then
				net.Start("Tabphone_Call_Ring")
				net.WritePlayer(calldata.Sender)
				net.Send(calldata.Recipient)
				calldata.Ringed = true
				continue
			end
		end
	end)

	hook.Add("PlayerCanHearPlayersVoice", "Tabphone_Call_PlayerCanHearPlayersVoice", function(listener, talker)
		local ll, lt = TABPHONE_LINKER[talker], TABPHONE_LINKER[listener]
		if ll and lt and (ll == lt) then return true, false end
	end)

	function TabPhone.SendNPCMessage(ply, from, message)
		net.Start("TabPhone_NPCMessage")
		net.WriteString(from)
		net.WriteString(message)
		net.Send(ply)
	end
end