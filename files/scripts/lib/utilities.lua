function Split(str, sep)
  if sep == nil then
    return {}
  end

  local t = {}

  local i = 1
  for s in string.gmatch(str, "([^" .. sep .. "]+)") do
    t[i] = s
    i = i + 1
  end

  return t
end

function DebugPrint(text)
  print(tostring(text))
end

function GameGetISO8601DateUTC()
  local year, month, day, hour, minute, second = GameGetDateAndTimeUTC()
  local function zeroPadding(text)
    local text = tostring(text)
    if #text == 1 then
      return '0' .. text
    end
    return text
  end

  local datetime_iso8601 = year .. '-' .. zeroPadding(month) .. '-' .. zeroPadding(day) .. 'T' .. zeroPadding(hour) .. ':' .. zeroPadding(minute) .. ':' .. zeroPadding(second) .. 'Z'
  return datetime_iso8601
end

dofile_once("mods/noita-journey/files/scripts/lib/utils/variable_storage.lua")
dofile_once("mods/noita-journey/files/scripts/lib/utils/player.lua")
dofile_once("mods/noita-journey/files/scripts/lib/utils/calculate.lua")
dofile_once("mods/noita-journey/files/scripts/lib/utils/extend_xml.lua")

-- has dependent
dofile_once("mods/noita-journey/files/scripts/lib/utils/wait_frame.lua")
dofile_once("mods/noita-journey/files/scripts/lib/utils/sound_player.lua")
