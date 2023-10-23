dofile_once("mods/noita-journey/files/scripts/lib/utilities.lua")

local json = dofile_once("mods/noita-journey/files/scripts/lib/jsonlua/json.lua")
local GLOBALS = dofile_once("mods/noita-journey/files/scripts/global_name_enums.lua")

function item_pickup(entity_item, entity_who_picked, name)
  local plyaer_entity_id = entity_who_picked
  if not IsPlayer(plyaer_entity_id) then
    return
  end

  local wallet_comp_id = EntityGetFirstComponentIncludingDisabled(plyaer_entity_id, 'WalletComponent')
  if wallet_comp_id == nil then
    return
  end

  local wallet = ComponentGetValue2(wallet_comp_id, 'money')
  local x, y = EntityGetTransform(entity_item)

  local item_cost_component = EntityGetFirstComponentIncludingDisabled(entity_item, 'ItemCostComponent')

  local bought_item = {
    game_id = GlobalsGetValue(GLOBALS.GAME_ID),
    bought_by = GlobalsGetValue(GLOBALS.USER_ID),
    name = GetInternalVariableValue(entity_item, 'name', 'value_string'),
    item_type = GetInternalVariableValue(entity_item, 'item_type', 'value_string'),
    location = {
      x = x,
      y = y,
      biome = GetInternalVariableValue(entity_item, 'biome', 'value_string'),
    },
    price = ComponentGetValue2(item_cost_component, 'cost'),
    store_type = GetInternalVariableValue(entity_item, 'biome', 'value_string'),
    held_wallet = wallet,
    datetime = GameGetISO8601DateUTC(),
  }

  GlobalsSetValue(GLOBALS.BOUGHT_SHOP_ITEM, json.encode(bought_item))
end
