
if SERVER then
	util.AddNetworkString("Tabphone_Call_Receiving")
	util.AddNetworkString("Tabphone_Call_Send")
	util.AddNetworkString("Tabphone_Call_SendConfirmation")
	util.AddNetworkString("Tabphone_Call_Decline")
	util.AddNetworkString("Tabphone_Call_Accept")
end

TP_CALLDECLINE_BUSY = 0
TP_CALLDECLINE_ENDED = 1

TP_CALLCONFIRM_GO = 0
TP_CALLCONFIRM_ALREADY = 1
TP_CALLCONFIRM_DENIED = 2
TP_CALLCONFIRM_NONEXISTANT = 3

if CLIENT then

	net.Receive("Tabphone_Call_Decline", function(len, ply)
		local Reason = net.ReadUInt(4)

		if Reason == TP_CALLDECLINE_BUSY then
			chat.AddText("Busy")
			TabMemory.CallStatus = "busy"
			TabMemory.CallEndTime = UnPredictedCurTime()
			LocalPlayer():EmitSound("fesiug/tabphone/delete.ogg", 100, 100, 1, CHAN_STATIC)
		elseif Reason == TP_CALLDECLINE_ENDED then
			chat.AddText("Call ended")
			TabMemory.CallStatus = "callended"
			TabMemory.CallEndTime = UnPredictedCurTime()
			LocalPlayer():EmitSound("fesiug/tabphone/delete.ogg", 100, 100, 1, CHAN_STATIC)
		end
	end)

	net.Receive("Tabphone_Call_SendConfirmation", function(len, ply)
		local Reason = net.ReadUInt(4)

		if Reason == TP_CALLCONFIRM_GO then
			chat.AddText("Call started")
			TabMemory.CallStatus = "calling"
		elseif Reason == TP_CALLCONFIRM_ALREADY then
			chat.AddText("You're already on a call.")
			TabMemory.CallStatus = false
		elseif Reason == TP_CALLCONFIRM_NONEXISTANT then
			chat.AddText("That recipient doesn't exist.")
			TabMemory.CallStatus = false
		elseif Reason == TP_CALLCONFIRM_DENIED then
			chat.AddText("You're not allowed to make calls.")
			TabMemory.CallStatus = false
		end
	end)

end

if SERVER then

	TABPHONE_LINES = TABPHONE_LINES or {}

	net.Receive("Tabphone_Call_Send", function(len, ply)
		local Calling = net.ReadUInt(8)
		local Reason

		if TABPHONE_LINES[ply] then
			Reason = TP_CALLCONFIRM_ALREADY
		elseif false then
			Reason = TP_CALLCONFIRM_DENIED
		elseif !Player(Calling):IsValid() then
			Reason = TP_CALLCONFIRM_NONEXISTANT
		else
			TABPHONE_LINES[ply] = { StartTime = CurTime(), Recipient = Player(Calling), CallAccepted = false }
			Reason = TP_CALLCONFIRM_GO
		end

		net.Start("Tabphone_Call_SendConfirmation")
			net.WriteUInt(Reason, 4)
		net.Send(ply)
	end)

	hook.Add("Think", "Tabphone_Think", function()

		for ply, calldata in pairs(TABPHONE_LINES) do
			if (calldata.StartTime+1 <= CurTime()) and !calldata.CallAccepted then
				net.Start("Tabphone_Call_Decline")
					net.WriteUInt(0, 4)
				net.Send(ply)
				TABPHONE_LINES[ply] = nil
				continue
			end
		end

	end)

end