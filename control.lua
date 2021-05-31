-- TODO
-- * Trains stuff fails if
--    * Two people on same force (ok failure)


require "teamwork-utils"
require "lua-migrations"

INITIAL_DIVIDER_ALLOWED_ITEMS = {
	['transport-belt'] = true,
	['fast-transport-belt'] = true,
	['express-transport-belt'] = true,
	['pipe'] = true,
	['straight-rail'] = true,
	['curved-rail'] = true,
	['small-electric-pole'] = true,
	['medium-electric-pole'] = true,
	['big-electric-pole'] = true,
	['substation'] = true,
}
local function divider_allowed_items()
	-- initialize it the first time.
	if global.divider_allowed_items == nil then
		global.divider_allowed_items = INITIAL_DIVIDER_ALLOWED_ITEMS
	end
	return global.divider_allowed_items
end
local function add_divider_allowed_item(item)
	-- initialize it the first time.
	if global.divider_allowed_items == nil then
		global.divider_allowed_items = INITIAL_DIVIDER_ALLOWED_ITEMS
	end
	global.divider_allowed_items[item] = true
end

GLOBAL_ALLOWED_ITEMS = {
	['locomotive'] = true,
	['cargo-wagon'] = true,
	['fluid-wagon'] = true,
	['artillery-wagon'] = true,
	['tank'] = true,
	['car'] = true,
	['character'] = true,
}

GAME_FORCES_PLAYER_ITEMS = {
	['train-stop'] = true,
}

local function playerForces()
	local res = {}
	for _, name in pairs(global.player_forces) do
		res[name] = game.forces[name]
	end
	return res
end

local function isPlayerForce(force)
	return not (playerForces()[force.name] == nil)
end

local function PlayerForceNames()
	local res = {}
	for name, _ in pairs(playerForces()) do
		table.insert(res, name)
	end
	return res
end

--------------------------
-------    Tech    -------
--------------------------

local function disableAllBackfillTechs()
	for _, force in pairs(playerForces()) do
		for name, tech in pairs(force.technologies) do
			if isBackfillTech(name) then
				tech.enabled = false
			end
		end
	end
end

local function allyResearchedTech(tech_name)
	for name, force in pairs(playerForces()) do
		if not force.technologies[tech_name].researched then
			for _, player in pairs(force.players) do
				player.print("Ally researched tech " .. tech_name)
			end

			force.technologies[tech_name].researched = true
			for _, effect in pairs(force.technologies[tech_name].effects) do
				if effect.type == 'unlock-recipe' then
					local recipe_name = effect.recipe
					force.recipes[recipe_name].enabled = false
				end
			end
		end
	end
end

local function expensifyTech(tech_name)
	for name, force in pairs(playerForces()) do
		if not force.technologies[tech_name].researched then
			local progress = force.get_saved_technology_progress(tech_name) or 0
			local new_progress = progress / settings.startup["tech-cost-factor"].value

			force.technologies[backtechName(tech_name)].enabled = true
			force.set_saved_technology_progress(backtechName(tech_name), new_progress)
		end
	end
end

local function someoneHas(tech_name)
	for _, force in pairs(playerForces()) do
		if force.technologies[tech_name].researched then return true end
	end
	return false
end

DIVIDER_ITEMS_UNLOCKED = {
	['teamwork-divider-belts'] = {
		['underground-belt'] = true,
		['fast-underground-belt'] = true,
		['express-underground-belt'] = true,
		['splitter'] = true,
		['fast-splitter'] = true,
		['express-splitter'] = true,
	},
	['teamwork-divider-fluids'] = {
		['pipe-to-ground'] = true,
		['storage-tank'] = true,
	},
	['teamwork-divider-inserters'] = {
		['burner-inserter'] = true,
		['inserter'] = true,
		['long-handed-inserter'] = true,
		['fast-inserter'] = true,
		['filter-inserter'] = true,
		['stack-inserter'] = true,
		['stack-filter-inserter'] = true,
	},
	['teamwork-divider-rail-signals'] = {
		['rail-signal'] = true,
		['rail-chain-signal'] = true,
	},
	['teamwork-divider-chests'] = {
		['wooden-chest'] = true,
		['iron-chest'] = true,
		['steel-chest'] = true,
		['logistic-chest-active-provider'] = true,
		['logistic-chest-passive-provider'] = true,
		['logistic-chest-requester'] = true,
		['logistic-chest-buffer'] = true,
		['logistic-chest-storage'] = true,
	},
	['teamwork-divider-military'] = {
		['stone-wall'] = true,
		['gate'] = true,
		['land-mine'] = true,
		['gun-turret'] = true,
		['laser-turret'] = true,
		['flamethrower-turret'] = true,
		['artillery-turret'] = true,
	},
}
local function isDividerEnablingTech(tech)
	return starts_with(tech.name, 'teamwork-divider')
end
local function ResearchCompleted(event)
	if isDividerEnablingTech(event.research) then
		for item_name, _ in pairs(DIVIDER_ITEMS_UNLOCKED[event.research.name]) do
			add_divider_allowed_item(item_name)
		end
		allyResearchedTech(event.research.name)
		return
	end
	-- Don't disable upgrade-type techs.
	if isSharedTech(event.research) then
		expensifyTech(event.research.name)
		allyResearchedTech(event.research.name)
	end

end
script.on_event(defines.events.on_research_finished, ResearchCompleted)

--------------------------
------- Game Start -------
--------------------------

local function create_peaceful_force(name, starting_items_position)
	game.create_force(name)
	for _, other_name in pairs(global.player_forces) do
		game.forces[name].set_cease_fire(game.forces[other_name], true)
		game.forces[other_name].set_cease_fire(game.forces[name], true)
	end
	table.insert(global.player_forces, name)
	-- Set "Friend" with the deafult force, for compatibility with mods that give the default force stuff.
	game.forces[name].set_friend(game.forces.player, true)
	game.forces.player.set_friend(game.forces[name], true)

	if starting_items_position ~= nil then
		local chest = game.surfaces[1].create_entity({name="wooden-chest", position=starting_items_position, force=game.forces[name]})
		chest.insert{name="transport-belt", count = 50}
		chest.insert{name="iron-plate", count = 12 }
	end
end

local function Init()
	global.train_ui_lock = nil
	global.player_forces = {}
	global.divider_half_width = 6
	global.divider_generated_to = {
		min_x = 0,
		max_x = 0,
		min_y = 0,
		max_y = 0,
	}
	global.next_expand_tick = ExpandPeriod(0, settings)
	if settings.global["num-teams"].value == "two-player" then
		create_peaceful_force('left', {x=-20, y=-20})
		create_peaceful_force('right', {x=20, y=-20})
	end
	if settings.global["num-teams"].value == "four-player" then
		create_peaceful_force('top-left', {x=-20, y=-20})
		create_peaceful_force('top-right', {x=20, y=-20})
		create_peaceful_force('bottom-left', {x=-20, y=20})
		create_peaceful_force('bottom-right', {x=20, y=20})
	end
	disableAllBackfillTechs()
end
script.on_init(Init)

local function setPlayerTeam(player_index)
	local index = player_index % (#global.player_forces) + 1
	local team = global.player_forces[index]
	debugPrint("Setting player " .. player_index .. " (" .. game.players[player_index].name .. ") to team " .. team)

	game.players[player_index].force = game.forces[team]
end

local function PlayerCreated(event)
	setPlayerTeam(event.player_index)
	local player = game.players[event.player_index]
end
script.on_event(defines.events.on_player_created, PlayerCreated)

script.on_event(defines.events.on_player_changed_force, function(event)
	if game.players[event.player_index].force == game.forces.player then
		debugPrint("Error: player " .. event.player_index .. " changed teams from " .. event.force.name .. " to " .. game.players[event.player_index].force.name)
		debugPrint("I'm going to change them back.")
		setPlayerTeam(event.player_index)
	end
end)

--------------------------
-------   Divider  -------
--------------------------


local function FillAreaWithDivider(min_x, max_x, min_y, max_y)
	local surface = game.surfaces[1]
	local tiles = {}
	for i=min_x,max_x-1 do
		for j=min_y,max_y-1 do
			table.insert(tiles, {name='hazard-concrete-left', position={i,j}})
		end
	end
	surface.set_tiles(tiles)

	local player_entities = game.surfaces[1].find_entities_filtered{
		area={
			left_top={x=min_x, y=min_y},
			right_bottom={x=max_x, y=max_y},
		},
		force=PlayerForceNames(),
	}
	for _, entity in pairs(player_entities) do
		if not entity.valid then
			debugPrint("Entity was invalid.")
		else
			if (not GLOBAL_ALLOWED_ITEMS[entity.name]) then
				if divider_allowed_items()[entity.name] then
					entity.force = game.forces.player
				else
					local pos = entity.position
					entity.die()
					local ghosts = game.surfaces[1].find_entities_filtered{position=pos }
					for _, ghost in pairs(ghosts) do
						printForce(ghost.force, "Removing ghost of a " .. ghost.name)
						ghost.destroy()
					end
				end
			end
		end
	end
end
local function FillChunkWithDividerVertical(event)
	local bounding_box = event.area
	if bounding_box.left_top.x > global.divider_half_width then return end
	if bounding_box.right_bottom.x < -global.divider_half_width then return end
	local min_x = math.max(bounding_box.left_top.x, -global.divider_half_width)
	local max_x = math.min(bounding_box.right_bottom.x, global.divider_half_width)
	local min_y = bounding_box.left_top.y
	local max_y = bounding_box.right_bottom.y
	FillAreaWithDivider(min_x, max_x, min_y, max_y)
	global.divider_generated_to.min_y = math.min(bounding_box.left_top.y, global.divider_generated_to.min_y)
	global.divider_generated_to.max_y = math.max(bounding_box.right_bottom.y, global.divider_generated_to.max_y)

end
local function FillChunkWithDividerHorizontal(event)
	local bounding_box = event.area
	if bounding_box.left_top.y > global.divider_half_width then return end
	if bounding_box.right_bottom.y < -global.divider_half_width then return end
	local min_y = math.max(bounding_box.left_top.y, -global.divider_half_width)
	local max_y = math.min(bounding_box.right_bottom.y, global.divider_half_width)
	local min_x = bounding_box.left_top.x
	local max_x = bounding_box.right_bottom.x
	FillAreaWithDivider(min_x, max_x, min_y, max_y)
	global.divider_generated_to.min_x = math.min(bounding_box.left_top.x, global.divider_generated_to.min_x)
	global.divider_generated_to.max_x = math.max(bounding_box.right_bottom.x, global.divider_generated_to.max_x)
end
local function FillChunkWithDivider(event)
	if settings.global["num-teams"].value == "two-player" then
		FillChunkWithDividerVertical(event)
	end
	if settings.global["num-teams"].value == "four-player" then
		FillChunkWithDividerVertical(event)
		FillChunkWithDividerHorizontal(event)
	end
end
script.on_event(defines.events.on_chunk_generated, FillChunkWithDivider)


local function ExpandDivider(event)
	printAllPlayers("No Man's Land Expands!")
	global.divider_half_width = global.divider_half_width + 1
	local surface = game.surfaces[1]

	-- Vertical
	FillAreaWithDivider(
		-global.divider_half_width,
		-global.divider_half_width + 1,
		global.divider_generated_to.min_y,
		global.divider_generated_to.max_y
	)
	FillAreaWithDivider(
		global.divider_half_width - 1,
		global.divider_half_width,
		global.divider_generated_to.min_y,
		global.divider_generated_to.max_y
	)
	--Horizontal
	if settings.global["num-teams"].value == "four-player" then
		FillAreaWithDivider(
			global.divider_generated_to.min_x,
			global.divider_generated_to.max_x,
			-global.divider_half_width,
			-global.divider_half_width + 1
		)
		FillAreaWithDivider(
			global.divider_generated_to.min_x,
			global.divider_generated_to.max_x,
			global.divider_half_width - 1,
			global.divider_half_width
		)
	end
end

local function OnTick(event)
	if settings.global["expand"].value ~= "none" then
		if (event.tick >= global.next_expand_tick) then
			global.next_expand_tick = global.next_expand_tick + ExpandPeriod(event.tick, settings)
			ExpandDivider()
		end
	end
end
script.on_event(defines.events.on_tick, OnTick)


--------------------------
---- Placement Bounds ----
--------------------------

local function inDivider(bounding_box)
	-- Vertical segment
	if (bounding_box.left_top.x <= global.divider_half_width) and
	   (bounding_box.right_bottom.x >= -global.divider_half_width) then
		return true
	end
	-- Horizontal segment
	if settings.global["num-teams"].value == "four-player" then
		if (bounding_box.left_top.y <= global.divider_half_width) and
	   	(bounding_box.right_bottom.y >= -global.divider_half_width) then
			return true
		end
	end
	return false
end

local function onCorrectSide(team_name, bounding_box)
	if team_name == "left" then
		return bounding_box.right_bottom.x < -global.divider_half_width
	end
	if team_name == "right" then
		return bounding_box.left_top.x > global.divider_half_width
	end
	if team_name == "top-left" then
		return bounding_box.right_bottom.x < -global.divider_half_width and bounding_box.right_bottom.y < -global.divider_half_width
	end
	if team_name == "top-right" then
		return bounding_box.left_top.x > global.divider_half_width and bounding_box.right_bottom.y < -global.divider_half_width
	end
	if team_name == "bottom-left" then
		return bounding_box.right_bottom.x < -global.divider_half_width and bounding_box.left_top.y > global.divider_half_width
	end
	if team_name == "bottom-right" then
		return bounding_box.left_top.x > global.divider_half_width and bounding_box.left_top.y > global.divider_half_width
	end
end

local function DestroyInvalidEntities(event)
	local entity = event.created_entity
	local player
	if event.player_index then
		player = game.players[event.player_index]
	end
	local force_name = entity.force.name

	if GLOBAL_ALLOWED_ITEMS[entity.name] or GAME_FORCES_PLAYER_ITEMS[entity.name] then
		-- This item can be build anywhere and interacted by anyone.
		entity.force = game.forces.player
		return
	end
	if onCorrectSide(force_name, entity.bounding_box) then
		-- built on correct side.
		return
	end

	if inDivider(entity.bounding_box) then
		if divider_allowed_items()[entity.name] then
			entity.force = game.forces.player
			return
		end
		entity.destroy()
		if player then
			player.print("Only transport belts, pipes, power poles, rails, and vehicles can be built in no-man's land without further research.")
		else
			printForce(entity.force, "A robot has tried to build in no-man's land. You might want to stop it.")
		end
		return
	end

	if player then
		player.print("The " .. entity.name .. " that you build on the wrong side of the map quickly dissolves into dust.")
	else
		printForce(entity.force, "A robot has tried to build in another faction's land. You might want to stop it.")
	end
	entity.destroy()
end
script.on_event(defines.events.on_built_entity, DestroyInvalidEntities)
script.on_event(defines.events.on_robot_built_entity, DestroyInvalidEntities)

local function PlacedTile(event)
	local force
	if event.player_index then
		force = game.players[event.player_index].force
	end
	if event.robot then
		force = event.robot.force
	end

	local surface = game.surfaces[1]
	for _, tile in pairs(event.tiles) do
		if inDivider({left_top=tile.position, right_bottom=tile.position}) then
			surface.set_tiles({{name='hazard-concrete-left', position=tile.position}})
			if event.player_index then
				printForce(force, "The gods of Hazard Concrete confiscate all your hazard concrete!")
				game.players[event.player_index].remove_item{name='hazard-concrete', count=500 }
			end
		end
	end
end
script.on_event(defines.events.on_player_built_tile, PlacedTile)
script.on_event(defines.events.on_player_mined_tile, PlacedTile)

script.on_event(defines.events.on_robot_built_tile, PlacedTile)
script.on_event(defines.events.on_robot_mined_tile, PlacedTile)


local function DroppedItem(event)
	local player = game.players[event.player_index]
	local entity = event.entity
	if onCorrectSide(player.force.name, event.entity.bounding_box) then return end
	player.print("The " .. entity.stack.name .. " you dropped outside your land quickly fades into mist.")
	entity.destroy()

end
script.on_event(defines.events.on_player_dropped_item, DroppedItem)

local function PickedUpItem(event)
	local player = game.players[event.player_index]
	local item_stack = event.item_stack
	if onCorrectSide(player.force.name, {left_top=player.position, right_bottom=player.position}) then return end
	player.print("You picked up " .. item_stack.name .. " from outside your land. It melts and slips through your fingers, lost forever.")
	player.remove_item(item_stack)
end
script.on_event(defines.events.on_picked_up_item, PickedUpItem)

--------------------------
------    Rocket    ------
--------------------------

local function StopDividerExpansionForever(event)
	printAllPlayers("A Rocket has been launched!")
	local rocket_inventory = event.rocket.get_inventory(defines.inventory.rocket)
	if rocket_inventory == nil then
		printAllPlayers("The rocket had no contents.")
		return
	end
	local contents = rocket_inventory.get_contents()
	for name, amount in pairs(contents) do
		local item_proto = game.item_prototypes[name]
		local entity_proto = item_proto.place_result
		if entity_proto == nil then
			printAllPlayers("The rocket contained a " .. item_proto.name .. "; try launching something that can be built.")
		else
			local entity_name = entity_proto.name
			printAllPlayers("The rocket contained a " .. entity_name .. "; these can now be built in No Man's Land.")
			add_divider_allowed_item(entity_name)
		end
	end

end
script.on_event(defines.events.on_rocket_launched, StopDividerExpansionForever)