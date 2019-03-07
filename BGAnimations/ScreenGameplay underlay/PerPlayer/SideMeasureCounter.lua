-- don't allow SideMeasureCounter to appear in Casual gamemode via profile settings
if SL.Global.GameMode == "Casual" then return end

local player = ...
local pn = ToEnumShortString(player)
local mods = SL[pn].ActiveModifiers
local currentStreamNumber = 1
local PlayerState = GAMESTATE:GetPlayerState(player)
local streams, current_measure, previous_measure, SideCounter, song_dir, steps, steps_type, difficulty, seperateStreams, nps, song, peakNps, testmsr, sideMeasures
local text1, text2, text3, text4, text5
local current_count, stream_index, current_stream_length, next_stream_length

-- We'll want to reset each of these values for each new song in the case of CourseMode
local function InitializeMeasureCounter()
	song = GAMESTATE:GetCurrentSong()
	song_dir = GAMESTATE:GetCurrentSong():GetSongDir()
    steps = GAMESTATE:GetCurrentSteps(player)
    steps_type = ToEnumShortString( steps:GetStepsType() ):gsub("_", "-"):lower()
    difficulty = ToEnumShortString( steps:GetDifficulty() )
	streams = SL[pn].Streams
	bdown = GetStreamBreakdown(song_dir, steps_type, difficulty)
	current_count = 0
	stream_index = 1
	current_stream_length = 0
	previous_measure = nil
	
	-- We need to split up the breakdown into individual streams
	seperateStreams = mysplit(bdown, sep)
	local sepstring = tostring(seperateStreams)
	SCREENMAN:SystemMessage(sepstring)
	
	local iter = ''
	for i,v in ipairs(seperateStreams) do
		iter = iter..i..': '..tostring(v)..'\n'
	end
	SCREENMAN:SystemMessage(seperateStreams[2])
	if seperateStreams[currentStreamNumber]
	text1 = seperateStreams[currentStreamNumber]
	text2 = seperateStreams[currentStreamNumber+1]
	text3 = seperateStreams[currentStreamNumber+2]
	text4 = seperateStreams[currentStreamNumber+3]
	text5 = seperateStreams[currentStreamNumber+4]
end

function mysplit(inputstr, sep)
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

			local defaultMText
			local subtractMText
			current_stream_length = streams.Measures[stream_index].streamEnd - streams.Measures[stream_index].streamStart
			current_count = math.floor(current_measure - streams.Measures[stream_index].streamStart) + 1

			-- checks MeasureCounterStyle and set next measuretext
			if mods.MeasureCounterStyle == "Default" then
				stream_left = tostring(current_count .. "/" .. current_stream_length)
			elseif mods.MeasureCounterStyle == "Subtraction" then
				stream_left = current_stream_length - current_count + 1
			elseif mods.MeasureCounterStyle == "Both" then
				defaultMText = tostring("  (" .. current_count .. "/" .. current_stream_length .. ")")
				subtractMText = tostring(current_stream_length - current_count + 1)
				stream_left = subtractMText .. defaultMText
			end

			sideMeasures = tostring(current_count.."/"..text1.. '\n' ..text2.. '\n'..text3.. '\n'..text4.. '\n'..text5)
			text = tostring(testmsr)
			SideCounter:settext(sideMeasures)

			if current_count > current_stream_length then
				stream_index = stream_index + 1
				currentStreamNumber = currentStreamNumber + 1
				text1 = seperateStreams[currentStreamNumber]
				text2 = seperateStreams[currentStreamNumber+1]
				text3 = seperateStreams[currentStreamNumber+2]
				text4 = seperateStreams[currentStreamNumber+3]
				text5 = seperateStreams[currentStreamNumber+4]
			end
		else
			sideMeasures = tostring(text1.. '\n' ..text2.. '\n'..text3.. '\n'..text4.. '\n'..text5)
			SideCounter:settext(sideMeasures)
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
			SideCounter = self
			local width = GAMESTATE:GetCurrentStyle(player):GetWidth(player)
			local NumColumns = GAMESTATE:GetCurrentStyle():ColumnsPerPlayer()
			self:zoom(0.35):shadowlength(1):horizalign(center)
			self:xy( GetNotefieldX(player) - (width/NumColumns), _screen.cy - _screen.cy/4 )
		end
	}

	return af

else
	return Def.Actor{}
end
