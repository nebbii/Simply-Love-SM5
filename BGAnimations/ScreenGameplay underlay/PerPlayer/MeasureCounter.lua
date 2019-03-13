-- don't allow MeasureCounter to appear in Casual gamemode via profile settings
if SL.Global.GameMode == "Casual" then return end

local player = ...
local pn = ToEnumShortString(player)
local mods = SL[pn].ActiveModifiers
local song = GAMESTATE:GetCurrentSong()
local song_dir = GAMESTATE:GetCurrentSong():GetSongDir()
local steps = GAMESTATE:GetCurrentSteps(player)
local steps_type = ToEnumShortString( steps:GetStepsType() ):gsub("_", "-"):lower()
local difficulty = ToEnumShortString( steps:GetDifficulty() )
local bdown = GetStreamBreakdown(song_dir, steps_type, difficulty)
local currentStreamNumber = 1
local PlayerState = GAMESTATE:GetPlayerState(player)
local streams, current_measure, previous_measure, MeasureCounterBMT, sideBdown, sideBdownBMT, mTextArray
local current_count, stream_index, current_stream_length, defaultMText, subtractMText, sideText, text
local text1, text2, text3, text4, text5

-- We'll want to reset each of these values for each new song in the case of CourseMode
local function InitializeMeasureCounter()
	streams = SL[pn].Streams
	current_count = 0
	stream_index = 1
	current_stream_length = 0
	previous_measure = nil
	mTextArray = {}

	-- We need to split up the breakdown into individual streams
	seperateStreams = Splitter(bdown, sep)
	local sepstring = tostring(seperateStreams)
	SCREENMAN:SystemMessage(sepstring)

	-- TO-DO needs to be rewritten in a more robust/elegant way
		for i=0,5 do	
			if (seperateStreams[currentStreamNumber+i]) ~= nil then
				mTextArray[currentStreamNumber+i] = seperateStreams[currentStreamNumber+i]
			else
				mTextArray[currentStreamNumber+i] = " "
			end
		end
end

function Splitter(inputstr, sep)
	if sep == nil then
			sep = "/"
	end
	local t={}
	for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
			table.insert(t, str)
	end
	return t
end

local function Update(self, delta)

	if not streams.Measures then return end

	current_measure = (math.floor(PlayerState:GetSongPosition():GetSongBeatVisible()))/4

	-- previous_measure will initially be nil; set it to be the same as current_measure
	if not previous_measure then previous_measure = current_measure end

	local new_measure_has_occurred = current_measure > previous_measure

	if new_measure_has_occurred then

		previous_measure = current_measure

		-- if the current measure is within the scope of the current stream
		if streams.Measures[stream_index]
		and current_measure >= streams.Measures[stream_index].streamStart
		and current_measure <= streams.Measures[stream_index].streamEnd then
			current_stream_length = streams.Measures[stream_index].streamEnd - streams.Measures[stream_index].streamStart
			current_count = math.floor(current_measure - streams.Measures[stream_index].streamStart) + 1

			-- checks MeasureCounterStyle and set next measuretext
			if mods.MeasureCounterStyle == "Traditional" then
				stream_left = tostring(current_count .. "/" .. current_stream_length)
			elseif mods.MeasureCounterStyle == "Subtraction" then
				stream_left = current_stream_length - current_count + 1
			elseif mods.MeasureCounterStyle == "Both" then
				subtractMText = tostring(current_stream_length - current_count + 1)
				defaultMText = tostring("/" .. current_stream_length)
				stream_left = subtractMText .. defaultMText
			end

				for i=0,5 do	
					if (seperateStreams[currentStreamNumber+i]) ~= nil then
						mTextArray[currentStreamNumber+i] = seperateStreams[currentStreamNumber+i]
					else
						mTextArray[currentStreamNumber+i] = " "
					end
				end
			sideBdown = tostring(current_count.."/"..mTextArray[currentStreamNumber].. '\n' ..mTextArray[currentStreamNumber+1]..'\n'..mTextArray[currentStreamNumber+2].. '\n'..mTextArray[currentStreamNumber+3].. '\n'..mTextArray[currentStreamNumber+4])
			text = tostring(stream_left)
			MeasureCounterBMT:settext( text )
			sideBdownBMT:settext(sideBdown)

			if current_count > current_stream_length then
				stream_index = stream_index + 1
				sideBdownBMT:settext(mTextArray[currentStreamNumber+1].. '\n' ..mTextArray[currentStreamNumber+2]..'\n'..mTextArray[currentStreamNumber+3].. '\n'..mTextArray[currentStreamNumber+4].. '\n'..mTextArray[currentStreamNumber+5])
				currentStreamNumber = currentStreamNumber + 1
				MeasureCounterBMT:settext( "" )
			end

		else
			sideBdownBMT:settext(mTextArray[currentStreamNumber].. '\n' ..mTextArray[currentStreamNumber+1]..'\n'..mTextArray[currentStreamNumber+2].. '\n'..mTextArray[currentStreamNumber+3].. '\n'..mTextArray[currentStreamNumber+4])
			MeasureCounterBMT:settext( "" )
		end
	end

	return
end

if mods.MeasureCounter and mods.MeasureCounter ~= "None" then

	local af = Def.ActorFrame{
		InitCommand=function(self)
			self:queuecommand("SetUpdate")
		end,
		CurrentSongChangedMessageCommand=function(self)
			InitializeMeasureCounter()
		end,
		SetUpdateCommand=function(self)
			self:SetUpdateFunction( Update )
		end
	}

	af[#af+1] = Def.BitmapText{
		Font="_wendy small",
		InitCommand=function(self)
			MeasureCounterBMT = self
			local width = GAMESTATE:GetCurrentStyle(player):GetWidth(player)
			local NumColumns = GAMESTATE:GetCurrentStyle():ColumnsPerPlayer()
			
			-- Set the size of the measure counter according to the size mod
			if mods.MeasureCounterSize == "Big" then
				self:zoom(0.5):shadowlength(1):horizalign(center)
			elseif mods.MeasureCounterSize == "Humongous" then
				self:zoom(0.75):shadowlength(1):horizalign(center)
			else
				self:zoom(0.35):shadowlength(1):horizalign(center)
			end

			-- Set the position for the measurecounter according to the selected X and Y axis mods
			if mods.MeasureCounterPositionX == "Center" and mods.MeasureCounterPositionY == "Below" then
				self:xy( GetNotefieldX(player), _screen.cy )
			elseif mods.MeasureCounterPositionX == "Center" and mods.MeasureCounterPositionY == "Above" then
				self:xy( GetNotefieldX(player), _screen.cy - _screen.cy/4 )
			elseif mods.MeasureCounterPositionX == "Left" and mods.MeasureCounterPositionY == "Below" then
				self:xy( GetNotefieldX(player) - (width/NumColumns), _screen.cy)
			else
				self:xy( GetNotefieldX(player) - (width/NumColumns), _screen.cy - _screen.cy/4 )
			end
		end
	}

	af[#af+2] = Def.BitmapText{
		Font="_wendy small",
		InitCommand=function(self)
			sideBdownBMT = self
			local width = GAMESTATE:GetCurrentStyle(player):GetWidth(player)
			local NumColumns = GAMESTATE:GetCurrentStyle():ColumnsPerPlayer()
			
			-- Set the size of the measure counter according to the size mod
			if mods.MeasureCounterSize == "Big" then
				self:zoom(0.5):shadowlength(1):horizalign(center)
			elseif mods.MeasureCounterSize == "Humongous" then
				self:zoom(0.75):shadowlength(1):horizalign(center)
			else
				self:zoom(0.35):shadowlength(1):horizalign(center)
			end

			-- Set the position for the measurecounter according to the selected X and Y axis mods
				self:xy( GetNotefieldX(player) - (width/1.5), _screen.cy + _screen.cy/4)

		end
	}
	return af

else
	return Def.Actor{}
end
