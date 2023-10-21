dofile_once("mods/noita-journey/files/scripts/lib/utilities.lua")
local uuid = dofile_once("mods/noita-journey/files/scripts/lib/uuid/uuid4.lua")
local json = dofile_once("mods/noita-journey/files/scripts/lib/jsonlua/json.lua")
local GLOBALS = dofile_once("mods/noita-journey/files/scripts/global_name_enums.lua")
local LOG_FOLDER_PATHS = dofile_once("mods/noita-journey/files/scripts/log_folder_path_enums.lua")

print("noita-journey load")

local FILE_NAMES = {
  USER = 'user.json',
  BOUGHT_ITEMS = 'bought-items.json',
  got_perks = 'got-perks.json',
}

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
---If you already saved, this function will merge exist json data
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

local function save_shop_item(shop_item_json)
  local bought_shop_item = json.decode(shop_item_json)
  local bought_item_file_path = LOG_FOLDER_PATHS.BOUGHT_ITEMS .. FILE_NAMES.BOUGHT_ITEMS

  local exists_shop_item = load_journey(bought_item_file_path)
  if exists_shop_item then
    table.insert(exists_shop_item, bought_shop_item)
    save_journey(exists_shop_item, bought_item_file_path)
  else
    save_journey({bought_shop_item}, bought_item_file_path)
  end
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

  local user_id = uuid.getUUID()
  local game_id = uuid.getUUID()

  GlobalsSetValue(GLOBALS.USER_ID, user_id)
  GlobalsSetValue(GLOBALS.GAME_ID, game_id)

  local user_file_path = LOG_FOLDER_PATHS.USER .. FILE_NAMES.USER
  local user_name = 'Den'
  local save_data = load_journey(user_file_path)
  if save_data then
    DebugPrint('updateData')
    table.insert(save_data.played_game_ids, {
      id = game_id,
      seed = StatsGetValue("world_seed"),
      datetime = GameGetISO8601DateUTC(),
    })
    save_journey(save_data, user_file_path)
  else
    DebugPrint('addData')
    save_journey({
      id = user_id,
      name = user_name,
      played_game_ids = {{
        id = game_id,
        seed = StatsGetValue("world_seed"),
        datetime = GameGetISO8601DateUTC(),
      }},
    }, user_file_path)
  end
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
end

function OnMagicNumbersAndWorldSeedInitialized() -- this is the last point where the Mod* API is available. after this materials.xml will be loaded.
  print("===================================== random " .. tostring(x))
end

print("noita-journey loaded")
