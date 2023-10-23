dofile_once("mods/noita-journey/files/scripts/lib/utilities.lua")
local uuid = dofile_once("mods/noita-journey/files/scripts/lib/uuid/uuid4.lua")
local json = dofile_once("mods/noita-journey/files/scripts/lib/jsonlua/json.lua")
local GLOBALS = dofile_once("mods/noita-journey/files/scripts/global_name_enums.lua")
local LOG_FOLDER_PATHS = dofile_once("mods/noita-journey/files/scripts/log_folder_path_enums.lua")

print("noita-journey load")

---Returns saved data as table
---If you didn't save yet, this function will return nil
---@param target_file_path string
---@return table | nil
local function load_journey(target_file_path)
  local file = io.open(target_file_path, "r")
  if not file then
    return nil
  end

  local encoded_by_json = file:read('*a')
  file:close()

  local successed, data = pcall(json.decode, encoded_by_json)
  if not successed then
    print('file was broken so can not read')
    return nil
  end

  return data
end

---This function will save as json
---@param save_object table
---@param target_file_path string
local function save_journey(save_object, target_file_path)
  local encoded = json.encode(save_object)
  local file = io.open(target_file_path, "w")

  if not file then
    DebugPrint('warning: file can not load')
    DebugPrint('warning: this file will be overrdden')
    return
  end

  file:write(encoded)
  file:close()
end

---This function will save as json
---@param save_object table
---@param target_file_path string
local function append_journey(save_object, target_file_path)
  local encoded = json.encode(save_object)
  local file = io.open(target_file_path, "a")

  if not file then
    DebugPrint('warning: file can not load')
    DebugPrint('warning: this file will be overrdden')
    return
  end

  file:write(encoded .. '\n')
  file:close()
end

local function save_played_game(user_id, game_id)
  local played_games_file_path = LOG_FOLDER_PATHS.USER .. 'played-games.jsonl'
  DebugPrint('addData')
  append_journey({
    user_id = user_id,
    game_id = game_id,
    seed = StatsGetValue("world_seed"),
    datetime = GameGetISO8601DateUTC(),
  }, played_games_file_path)
end

local function save_user(user_id, game_id, user_name)
  local user_file_path = LOG_FOLDER_PATHS.USER .. 'user.json'
  local save_data = load_journey(user_file_path)
  if save_data then
    DebugPrint('updateData')
    save_data.user_name = user_name
    save_data.current_game_id = game_id
    save_data.datetime = GameGetISO8601DateUTC()
    save_journey(save_data, user_file_path)
  else
    DebugPrint('addData')
    save_journey({
      id = user_id,
      name = user_name,
      current_game_id = game_id,
      datetime = GameGetISO8601DateUTC(),
    }, user_file_path)
  end
end

local function save_shop_item(shop_item_json)
  local bought_shop_item = json.decode(shop_item_json)
  local bought_item_file_path = LOG_FOLDER_PATHS.BOUGHT_ITEMS .. GlobalsGetValue(GLOBALS.GAME_ID) .. '.jsonl'
  append_journey(bought_shop_item, bought_item_file_path)
end

local function save_player_location()
  local player_entity_id = GetPlayerEntity()
  if not player_entity_id then
    return
  end
  local x, y = EntityGetTransform(player_entity_id)
  local location = {
    game_id = GlobalsGetValue(GLOBALS.GAME_ID),
    x = x,
    y = y,
    datetime = GameGetISO8601DateUTC(),
  }

  local location_histories_file_path = LOG_FOLDER_PATHS.LOCATION_HISTORIES .. GlobalsGetValue(GLOBALS.GAME_ID) .. '.jsonl'
  append_journey(location, location_histories_file_path)
end

--
-- Loader
--

ModLuaFileAppend("data/scripts/items/generate_shop_item.lua", "mods/noita-journey/files/scripts/append/items/generate_shop_item.lua")

--
-- Event Functions
--

function OnModPreInit()
  print("Mod - OnModPreInit()") -- First this is called for all mods
end

function OnModInit()
  print("Mod - OnModInit()") -- After that this is called for all mods
  local user_name = ModSettingGet('NOITA_JOURNEY.USER_NAME')
  local user_id = ModSettingGet('NOITA_JOURNEY.USER_ID')

  if not user_name then
    ModSettingSet('NOITA_JOURNEY.USER_NAME', 'Den')
  end

  if not user_id then
    ModSettingSet('NOITA_JOURNEY.USER_ID', uuid.getUUID())
  end
end

function OnModPostInit()
  print("Mod - OnModPostInit()") -- Then this is called for all mods
end

function OnPlayerSpawned(player_entity) -- This runs when player entity has been created
  print("Mod - OnPlayerSpawned")
end

function OnWorldInitialized() -- This is called once the game world is initialized. Doesn't ensure any world chunks actually exist. Use OnPlayerSpawned to ensure the chunks around player have been loaded or created.
  print("Mod - OnWorldInitialized")

  if not GameHasFlagRun(GLOBALS.IS_CONTINUE_GAME) then
    OnInitializedFirst()
    GameAddFlagRun(GLOBALS.IS_CONTINUE_GAME)
  else
    OnInitializedContinue()
  end
end

function OnInitializedFirst()
  DebugPrint('OnInitializedFirst()')
  local game_id = uuid.getUUID()
  local user_id = tostring(ModSettingGet('NOITA_JOURNEY.USER_ID'))
  local user_name = ModSettingGet('NOITA_JOURNEY.USER_NAME')

  GlobalsSetValue(GLOBALS.USER_ID, user_id)
  GlobalsSetValue(GLOBALS.GAME_ID, game_id)
  save_played_game(user_id, game_id)
  save_user(user_id, game_id, user_name)
end

function OnInitializedContinue()
  DebugPrint('OnInitializedContinue()')
end

function OnWorldPreUpdate() -- This is called every time the game is about to start updating the world
end

function OnWorldPostUpdate() -- This is called every time the game has finished updating the world
  local bought_shop_item_json = GlobalsGetValue(GLOBALS.BOUGHT_SHOP_ITEM, '')
  if bought_shop_item_json ~= '' then
    save_shop_item(bought_shop_item_json)
    GlobalsSetValue(GLOBALS.BOUGHT_SHOP_ITEM, '')
  end

  if GameGetFrameNum() % 120 == 0 then
    save_player_location()
  end
end

function OnMagicNumbersAndWorldSeedInitialized() -- this is the last point where the Mod* API is available. after this materials.xml will be loaded.
  print("===================================== random " .. tostring(x))
end

print("noita-journey loaded")
