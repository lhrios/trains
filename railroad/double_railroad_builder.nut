/*
 * trAIns - An AI for OpenTTD
 * Copyright (C) 2009  Luis Henrique O. Rios
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.

 * You should have received a copy of the GNU General Public License along
 * with this program; if not, write to the Free Software Foundation, Inc.,
 * 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
*/


class BridgeInformation {
	start_tile = null;
	exit_tile = null;
	part_index = null;
	primary_bridges = null;
	secondary_bridges = null;
	secondary_rail_offset = null;

	constructor(){
		primary_bridges = array(0);
		secondary_bridges = array(0);
	}

	function _tostring(){
		return "BridgeInformation: start_tile: " + Tile.ToString(start_tile) +
			" exit_tile: " + Tile.ToString(exit_tile) +
			" part_index: " + ::ai_instance.dtp.ToString(part_index);
	}

	function CanBeCoalesced(bridge_information) {
		if ((Tile.DistanceX(exit_tile, bridge_information.start_tile) <= DoubleRailroadBuilder.MAX_DISTANCE_TO_TRIE_COALESCENCE
				&& Tile.DistanceY(exit_tile, bridge_information.start_tile) == 0)
				|| (Tile.DistanceY(exit_tile, bridge_information.start_tile) <= DoubleRailroadBuilder.MAX_DISTANCE_TO_TRIE_COALESCENCE
				&& Tile.DistanceX(exit_tile, bridge_information.start_tile) == 0)) {

			assert (part_index == bridge_information.part_index);
			assert (secondary_rail_offset == bridge_information.secondary_rail_offset);
			return true;
		}
		return false;
	}

	function Coalesce(bridge_information) {
		exit_tile = bridge_information.exit_tile;
		Array.appendArray(primary_bridges, bridge_information.primary_bridges);
		Array.appendArray(secondary_bridges, bridge_information.secondary_bridges);
	}
}

class DoubleRailroad {
	path = null;
	depots_tiles_near_start = null;
	depots_tiles_near_end = null;
}

class DoubleRailroadBuilder {
	/* Public: */
	constructor(tile_from , tile_to , part_from , part_to){

		this.tile_from = tile_from;
		this.tile_to = tile_to;
		this.part_from = part_from;
		this.part_to = part_to;

		this.dtp = ::ai_instance.dtp;

		initialize_a_star = true;
		a_star = AStar(DoubleRailroadBuilder.G , DoubleRailroadBuilder.H ,
			DoubleRailroadBuilder.GetNeighbours , DoubleRailroadBuilder.EndNode ,
			this , this , this , this);
		ignored_nodes = array(0);
	}

	function BuildTrack();
	function GetTrackCost();
	static function DemolishDoubleRailroad(path);
	static function EstimateCostToConvertTrack(path , rail_type);
	static function ConvertTrack(path , rail_type);

	function _tostring(){
		return "From: " + Tile.ToString(tile_from) + "(" + dtp.ToString(part_from) + ") " +
			"To: " + Tile.ToString(tile_to) + "(" + dtp.ToString(part_to) + ").";
	}

	/* Private: */
	/* Constants: */
	static PART_COST = 1;
	static BRIDGE_MAX_LENGTH = 30;
	static MAX_DISTANCE_TO_TRIE_COALESCENCE = 3;

	static PATHFINDING_TIME_OUT = (365 * 2.5).tointeger();/* days. */
	static PATHFINDING_INTERVAL = 30;

	tile_from = null;
	tile_to = null;
	part_from = null;
	part_to = null;
	max_iterations = null;
	user_data = null;
	final_path = null;
	first_path = null;
	start_date = null;
	start_tick = null;
	initialize_a_star = null;
	ignored_nodes = null;

	a_star = null;
	dtp = null;

	static function DemolishBridge(bridge_information);
	static function BuildBridge(bridge_information);
	static function ConvertBridge(bridge_information , rail_type);
	function G(parent_node , tile , part_index , user_data , self);
	function H(parent_node , tile , part_index , user_data , self);
	function GetNeighbours(node , self);
	function EndNode(node , self);
	function LandToBuildBridgeOver(tile);
	function PostProcessing(path);
	function IntraPartBridgeCoalescence(path);
}

class BridgeValuator {
	largest_price = null;
	largest_max_speed = null;
	length = null;

	constructor(length){
		local bridges = AIBridgeList_Length(length);
		bridges.Valuate(AIBridge.GetPrice , length);
		bridges.Sort(AIAbstractList.SORT_BY_VALUE , false);
		largest_price = bridges.GetValue(bridges.Begin());

		bridges.Valuate(AIBridge.GetMaxSpeed);
		bridges.Sort(AIAbstractList.SORT_BY_VALUE , false);
		largest_max_speed = bridges.GetValue(bridges.Begin());

		this.length = length;
	}

	static function ValuateBridgeType(id , bv){
		local v = 1.0;
		v *= AIBridge.GetMaxSpeed(id).tofloat() / bv.largest_max_speed.tofloat();
		v /= AIBridge.GetPrice(id , bv.length).tofloat() / bv.largest_price.tofloat();
		v *= 1000;
		return v.tointeger();
	}
}

function DoubleRailroadBuilder::EstimateCostToConvertTrack(path , rail_type){
	local ai_test_mode = AITestMode();
	local cost =  AIAccounting();

	DoubleRailroadBuilder.ConvertTrack(path , rail_type);
	return cost.GetCosts();
}

function DoubleRailroadBuilder::DemolishBridge(bridge_information){
	local dtp = ::ai_instance.dtp;
	local primary_tile = bridge_information.start_tile;
	local secondary_tile = primary_tile + bridge_information.secondary_rail_offset;
	local next_tile = dtp.parts[bridge_information.part_index].next_tile;
	local rail_track = dtp.parts[bridge_information.part_index].sections[0].track;
	local i = 0;

	while(primary_tile != bridge_information.exit_tile + next_tile){
		if(i < bridge_information.primary_bridges.len() &&
			primary_tile == bridge_information.primary_bridges[i].first){
			local pair = bridge_information.primary_bridges[i];
			AITile.DemolishTile(primary_tile);
			primary_tile = pair.second + next_tile;
			i++;
		}else{
			AIRail.RemoveRailTrack(primary_tile , rail_track);
			primary_tile += next_tile;
		}
	}

	i = 0;
	while(secondary_tile != bridge_information.exit_tile + next_tile +
		bridge_information.secondary_rail_offset){

		if(i < bridge_information.secondary_bridges.len() &&
			secondary_tile == bridge_information.secondary_bridges[i].first){
			local pair = bridge_information.secondary_bridges[i];
			AITile.DemolishTile(secondary_tile);
			secondary_tile = pair.second + next_tile;
			i++;
		}else{
			AIRail.RemoveRailTrack(secondary_tile , rail_track);
			secondary_tile += next_tile;
		}
	}
}

function DoubleRailroadBuilder::BuildBridge(bridge_information){
	local dtp = ::ai_instance.dtp;
	local primary_tile = bridge_information.start_tile;
	local secondary_tile = primary_tile + bridge_information.secondary_rail_offset;
	local next_tile = dtp.parts[bridge_information.part_index].next_tile;
	local rail_track = dtp.parts[bridge_information.part_index].sections[0].track;
	local i = 0;

	while(primary_tile != bridge_information.exit_tile + next_tile){
		if(i < bridge_information.primary_bridges.len() &&
			primary_tile == bridge_information.primary_bridges[i].first){
			local pair = bridge_information.primary_bridges[i];
			local length = AITile.GetDistanceManhattanToTile(pair.first , pair.second) + 1;
			local bv = BridgeValuator(length);
			local bridges = AIBridgeList_Length(length)

			bridges.Valuate(bv.ValuateBridgeType , bv);
			bridges.Sort(AIAbstractList.SORT_BY_VALUE , false);

			if(!AIBridge.BuildBridge(AIVehicle.VT_RAIL , bridges.Begin() , pair.first , pair.second))
				return false;
			primary_tile = pair.second + next_tile;
			i++;
		}else{
			if(!AIRail.BuildRailTrack(primary_tile , rail_track)) return false;
			primary_tile += next_tile;
		}
	}

	i = 0;
	while(secondary_tile != bridge_information.exit_tile + next_tile +
		bridge_information.secondary_rail_offset){
		if(i < bridge_information.secondary_bridges.len() &&
			secondary_tile == bridge_information.secondary_bridges[i].first){
			local pair = bridge_information.secondary_bridges[i];
			local length = AITile.GetDistanceManhattanToTile(pair.first , pair.second) + 1;
			local bv = BridgeValuator(length);
			local bridges = AIBridgeList_Length(length)

			bridges.Valuate(bv.ValuateBridgeType , bv);
			bridges.Sort(AIAbstractList.SORT_BY_VALUE , false);
			if(!AIBridge.BuildBridge(AIVehicle.VT_RAIL , bridges.Begin() , pair.first , pair.second))
				return false;
			secondary_tile = pair.second + next_tile;
			i++;
		}else{
			if(!AIRail.BuildRailTrack(secondary_tile , rail_track)) return false;
			secondary_tile += next_tile;
		}
	}
	return true;
}

function DoubleRailroadBuilder::BuildBridgeSignals(bridge_information, interval, last_signal){
	local dtp = ::ai_instance.dtp;
	local primary_tile = bridge_information.start_tile;
	local secondary_tile = primary_tile + bridge_information.secondary_rail_offset;
	local next_tile = dtp.parts[bridge_information.part_index].next_tile;
	local rail_track = dtp.parts[bridge_information.part_index].sections[0].track;
	local signal_senses = dtp.parts[bridge_information.part_index].signal_senses;
	local i = 0;
	local j = last_signal;

	do {
		local must_build_signal = !AIBridge.IsBridgeTile(primary_tile) && (j % interval == 0
			/* Next is a bridge start. */
			|| (i < bridge_information.primary_bridges.len() && primary_tile + next_tile == bridge_information.primary_bridges[i].first));

		if (must_build_signal) {
			if(!RailroadCommon.BuildSignal(primary_tile, rail_track, signal_senses[0], AIRail.SIGNALTYPE_NORMAL)) {
				return false;
			}
		}

		if(i < bridge_information.primary_bridges.len() &&
			primary_tile == bridge_information.primary_bridges[i].first){
			local pair = bridge_information.primary_bridges[i];
			primary_tile = pair.second + next_tile;
			i++;
			j = 0;
		}else{
			primary_tile += next_tile;
			j++;
		}

	} while(primary_tile != bridge_information.exit_tile + next_tile);

	i = 0;
	j = last_signal;
	do {
		local must_build_signal = !AIBridge.IsBridgeTile(secondary_tile) && (j % interval == 0
			/* Next is a bridge start. */
			|| (i < bridge_information.secondary_bridges.len() && secondary_tile + next_tile == bridge_information.secondary_bridges[i].first));

		if (must_build_signal) {
			if(!RailroadCommon.BuildSignal(secondary_tile, rail_track, signal_senses[1], AIRail.SIGNALTYPE_NORMAL)) {
			 	return false;
			}
		}

		if(i < bridge_information.secondary_bridges.len() &&
			secondary_tile == bridge_information.secondary_bridges[i].first){
			local pair = bridge_information.secondary_bridges[i];
			secondary_tile = pair.second + next_tile;
			i++;
			j = 0;
		}else{
			secondary_tile += next_tile;
			j++;
		}

	} while(secondary_tile != bridge_information.exit_tile + next_tile + bridge_information.secondary_rail_offset);

	return true;
}


function DoubleRailroadBuilder::ConvertBridge(bridge_information , rail_type){
	local dtp = ::ai_instance.dtp;
	local primary_tile = bridge_information.start_tile;
	local secondary_tile = primary_tile + bridge_information.secondary_rail_offset;
	local next_tile = dtp.parts[bridge_information.part_index].next_tile;
	local rail_track = dtp.parts[bridge_information.part_index].sections[0].track;
	local i = 0;

	while(primary_tile != bridge_information.exit_tile + next_tile){
		if(i < bridge_information.primary_bridges.len() &&
			primary_tile == bridge_information.primary_bridges[i].first){
			local pair = bridge_information.primary_bridges[i];
			AIRail.ConvertRailType(pair.first , pair.first , rail_type);
			primary_tile = pair.second + next_tile;
			i++;
		}else{
			AIRail.ConvertRailType(primary_tile , primary_tile , rail_type);
			primary_tile += next_tile;
		}
	}

	i = 0;
	while(secondary_tile != bridge_information.exit_tile + next_tile +
		bridge_information.secondary_rail_offset){
		if(i < bridge_information.secondary_bridges.len() &&
			secondary_tile == bridge_information.secondary_bridges[i].first){
			local pair = bridge_information.secondary_bridges[i];
			AIRail.ConvertRailType(pair.first , pair.first , rail_type);
			secondary_tile = pair.second;
			i++;
		}else{
			AIRail.ConvertRailType(secondary_tile , secondary_tile , rail_type);
			secondary_tile += next_tile;
		}
	}
}

function DoubleRailroadBuilder::ConvertTrack(path , rail_type){
	local dtp = ::ai_instance.dtp;

	while(path != null){
		local tile , part_index;
		tile = path.tile;
		part_index = path.part_index;
		switch(part_index){
			case dtp.BRIDGE:
				DoubleRailroadBuilder.ConvertBridge(path.user_data , rail_type);
			break;
			case dtp.TUNNEL:
			break;
			default:
				dtp.ConvertDoublePart(tile , part_index , rail_type);
			break;
		}
		DoubleDepotBuilder.ConvertDepotPart(path , rail_type);
		DoubleJunctionBuilder.ConvertJunction(path , rail_type);
		path = path.child_path;
	}
}

/* TODO: */
function DoubleRailroadBuilder::GetTrackCost(){
}

function DoubleRailroadBuilder::DemolishDoubleRailroad(path){
	local dtp = ::ai_instance.dtp;

	while(path != null){
		if(dtp.IsLineBendOrDiagonal(path.part_index)){
			dtp.DemolishDoublePart(path.tile , path.part_index);
			if(path.depot_information != null){
				DoubleDepotBuilder.DemolishDepotPart(path , true);
				DoubleDepotBuilder.DemolishDepotPart(path , false);
			}
			if(path.junction_information != null){
				DoubleJunctionBuilder.DemolishJunction(path.junction_information);
			}
		}else if(path.part_index == dtp.TUNNEL){
			;
		}else if(path.part_index == dtp.BRIDGE){
			DoubleRailroadBuilder.DemolishBridge(path.user_data);
		}

		path = path.child_path;
	}
}

function DoubleRailroadBuilder::G(parent_node , tile , part_index , user_data , self){
	this = self;
	local c;

	/* The special cases. */
	switch(part_index){
		case dtp.BRIDGE:
			c = (AIMap.DistanceManhattan(user_data.start_tile , user_data.exit_tile) + 1) *
				PART_COST;
		break;
		case dtp.TUNNEL:
		break;
		default:
			c = PART_COST;
		break;
	}

	/* Debug: */
 	//AITile.DemolishTile(tile);

	if(parent_node == null) return c;
	else return parent_node.g + c;
}

function DoubleRailroadBuilder::H(parent_node , tile , part_index , user_data , self){
	this = self;

	switch(part_index){
		case DoubleTrackParts.BRIDGE:
			part_index = user_data.part_index;
 			if(part_index == DoubleTrackParts.NS_LINE || part_index == DoubleTrackParts.EW_LINE)
				tile = user_data.exit_tile +
					dtp.parts[dtp.GetOppositePart(part_index)].next_tile;
 			else tile = user_data.exit_tile;
		break;
	}

	local t_x , t_y , g_x , g_y;
	t_x = AIMap.GetTileX(tile);
	t_y = AIMap.GetTileY(tile);
	g_x = AIMap.GetTileX(tile_to);
	g_y = AIMap.GetTileY(tile_to);
	return max(abs(t_x - g_x) , abs(t_y - g_y)) * PART_COST;
}

function DoubleRailroadBuilder::GetNeighbours(node , self){
	this = self;
	local neighbours = [];
	local part_index = node.part_index;
	local new_tile;

	switch(part_index){
		case DoubleTrackParts.BRIDGE:{
			local user_data = node.user_data;
			part_index = user_data.part_index;
			if(part_index == DoubleTrackParts.NS_LINE || part_index == DoubleTrackParts.EW_LINE)
				new_tile = user_data.exit_tile;
			else new_tile = user_data.exit_tile + dtp.parts[part_index].next_tile;
		}break;

		default:
			new_tile = node.tile + dtp.parts[part_index].next_tile;
		break;
	}

	if(!AIMap.IsValidTile(new_tile)) return [];

	foreach(child_part_index in dtp.parts[part_index].continuation_parts){
		/* Check if it was already generated. */
		if(a_star.IsInClosedList(new_tile , child_part_index , null)) continue;

		if(dtp.LandToBuildDoublePart(new_tile , child_part_index) &&
			dtp.SlopesToBuildDoublePart(new_tile , child_part_index)){
			neighbours.append(a_star.CreateNode(new_tile , child_part_index , null , node));
		}
	}

	/* Try to build a brigde. */
	foreach(reference_part_index in dtp.parts[part_index].continuation_parts){

		if(dtp.IsLine(reference_part_index)){
			local next_tile , secondary_rail_offset , rail_track , is_primary_rail_blocked ,
				is_secondary_rail_blocked, length , exit , primary_tile , secondary_tile , primary_length ,
				secondary_length , problem , bridge_information = BridgeInformation();

			next_tile = dtp.parts[reference_part_index].next_tile;
			switch(reference_part_index){
				case DoubleTrackParts.EW_LINE:
					new_tile += AIMap.GetTileIndex(-1 , 0);
					secondary_rail_offset = AIMap.GetTileIndex(0 , -1);
				break;
				case DoubleTrackParts.WE_LINE:
					secondary_rail_offset = AIMap.GetTileIndex(0 , -1);
				break;
				case DoubleTrackParts.NS_LINE:
					new_tile += AIMap.GetTileIndex(0 , -1);
					secondary_rail_offset = AIMap.GetTileIndex(-1 , 0);
				break;
				case DoubleTrackParts.SN_LINE:
					secondary_rail_offset = AIMap.GetTileIndex(-1 , 0);
				break;
				default:
					assert(false);
				break;
			}
			if(a_star.IsInClosedList(new_tile , DoubleTrackParts.BRIDGE , reference_part_index)) continue;
			rail_track = dtp.parts[reference_part_index].sections[0].track;

			problem = false;
			primary_tile = secondary_tile = new_tile;
			secondary_tile += secondary_rail_offset;
			primary_length = secondary_length = 0;

			is_primary_rail_blocked = RailroadCommon.IsRailBlocked(primary_tile , next_tile , rail_track) &&
				RailroadCommon.CanBuildRailOnLand(primary_tile);
			is_secondary_rail_blocked = RailroadCommon.IsRailBlocked(secondary_tile , next_tile , rail_track) &&
				RailroadCommon.CanBuildRailOnLand(primary_tile);

			bridge_information.start_tile = primary_tile;
			bridge_information.part_index = reference_part_index;

			while(!problem && (is_primary_rail_blocked || is_secondary_rail_blocked ||
				primary_length != secondary_length)){

				if(is_primary_rail_blocked){
					length = 2;
					exit = primary_tile + next_tile;
					while(true){
						if(!(AIMap.IsValidTile(exit) && AIMap.IsValidTile(exit + next_tile) &&
							length < BRIDGE_MAX_LENGTH)){
							problem = true;
							break;
						}
						if(RailroadCommon.CanBuildRailOnLand(exit) &&
							RailroadCommon.CanBuildRailOnLand(exit + next_tile) ){
							local ai_test_mode = AITestMode();
							if(AIBridge.BuildBridge(AIVehicle.VT_RAIL , 0 , primary_tile , exit) ){
								bridge_information.primary_bridges.push(Pair(primary_tile , exit));
								primary_tile = exit + next_tile;
								primary_length += length;
								break;
							}
						}
						length++;
						exit += next_tile;
					}
				}

				if(is_secondary_rail_blocked){
					length = 2;
					exit = secondary_tile + next_tile;
					while(true){
						if(!(AIMap.IsValidTile(exit) && AIMap.IsValidTile(exit + next_tile) &&
							length < BRIDGE_MAX_LENGTH)){
							problem = true;
							break;
						}
						if(RailroadCommon.CanBuildRailOnLand(exit) &&
							RailroadCommon.CanBuildRailOnLand(exit + next_tile) ){
							local ai_test_mode = AITestMode();
							if(AIBridge.BuildBridge(AIVehicle.VT_RAIL , 0 , secondary_tile , exit) ){
								bridge_information.secondary_bridges.push(Pair(secondary_tile , exit));
								secondary_tile = exit + next_tile;
								secondary_length += length;
								break;
							}
						}
						length++;
						exit += next_tile;
					}
				}

				local next_exit;
				if(secondary_length < primary_length){
					for(length = secondary_length , exit = secondary_tile ;
						length < primary_length ; length++ , exit += next_tile){
						next_exit = exit + next_tile;

						if(!(RailroadCommon.CanBuildRailOnLand(exit))){
							problem = true;
							break;
						}else if(!RailroadCommon.CanBuildTrackOnSlope(exit , rail_track) ||
							RailroadCommon.IsRailBlocked(exit , next_tile , rail_track)) break;
					}
					secondary_tile = exit;
					secondary_length = length;
				}else if(secondary_length > primary_length){
					for(length = primary_length , exit = primary_tile ;
						length < secondary_length ; length++ , exit += next_tile){
						next_exit = exit + next_tile;

						if(!(RailroadCommon.CanBuildRailOnLand(exit))){
							problem = true;
							break;
						}else if(!RailroadCommon.CanBuildTrackOnSlope(exit , rail_track) ||
							RailroadCommon.IsRailBlocked(exit , next_tile , rail_track)) break;
					}
					primary_tile = exit;
					primary_length = length;
				}

				is_primary_rail_blocked = RailroadCommon.IsRailBlocked(primary_tile , next_tile , rail_track) ||
					secondary_length > primary_length;
				is_secondary_rail_blocked =  RailroadCommon.IsRailBlocked(secondary_tile , next_tile , rail_track) ||
					primary_length > secondary_length;
			}

			if(!problem && primary_length != 0){
				local tile , part_index;

				part_index = dtp.GetOppositePart(reference_part_index);
				bridge_information.exit_tile = primary_tile + dtp.parts[part_index].next_tile;
				bridge_information.secondary_rail_offset = secondary_rail_offset;
				tile = bridge_information.exit_tile;
				switch(reference_part_index){
					case DoubleTrackParts.EW_LINE:
						tile += AIMap.GetTileIndex(1 , 0);
					break;
					case DoubleTrackParts.NS_LINE:
						tile += AIMap.GetTileIndex(0 , 1);
					break;
				}

				neighbours.append(a_star.CreateNode(tile , DoubleTrackParts.BRIDGE , bridge_information ,
					node));
			}
			break;
		}
	}
	return neighbours;
}

function DoubleRailroadBuilder::EndNode(node , self){
	this = self;
	local part_index = node.part_index;
	local tile = node.tile;

	/* FIXME: Bridges can never end on destination tile. */
	switch(part_index){
		case DoubleTrackParts.BRIDGE:{
			local user_data = node.user_data;

			part_index = user_data.part_index;
			tile = user_data.exit_tile;
		}break;
		default:
			 tile += dtp.parts[part_index].next_tile;
		break;
	}

	if(tile == tile_to){
		foreach(part in dtp.parts[part_index].continuation_parts){
			if(part == part_to) return true;
		}
	}

	return false;
}

function DoubleRailroadBuilder::BuildSignals(path , interval){
	local i = 0;
	local dtp = ::ai_instance.dtp;
	local must_build_signal = false;

	while(path != null){
		local can_build_signal;
		local tile = path.tile;
		local next_path = path.child_path;
		local part_index = path.part_index;

		if(i % interval == 0 ||
			(next_path != null &&
			(next_path.depot_information != null || dtp.IsBridgeOrTunnel(next_path.part_index))) ||
			path.depot_information != null || dtp.IsBridgeOrTunnel(path.part_index))
			must_build_signal = true;

		if(must_build_signal && dtp.IsLineBendOrDiagonal(part_index) && path.depot_information == null){
			{
				local ai_test_mode = AITestMode();
				can_build_signal = dtp.BuildDoublePartSignals(tile , part_index , AIRail.SIGNALTYPE_NORMAL);
			}
			if(can_build_signal){
				dtp.BuildDoublePartSignals(tile , part_index , AIRail.SIGNALTYPE_NORMAL);
				must_build_signal = false;
				i = 0;
			}
		} else if (part_index == DoubleTrackParts.BRIDGE) {
			BuildBridgeSignals(path.user_data, interval, i);
		}

		path = next_path;
		i++;
	}
}

function DoubleRailroadBuilder::BuildTrack() {
	local enough_cash = true;

	while(enough_cash){
		if(initialize_a_star){
			start_date = AIDate.GetCurrentDate();
			start_tick = ::ai_instance.GetTick();
			a_star.InitializePath([[tile_from , part_from , user_data]] , ignored_nodes);
			initialize_a_star = false;
		}
		local path = a_star.FindPath(PATHFINDING_INTERVAL);

		if(AIDate.GetCurrentDate() > start_date + PATHFINDING_TIME_OUT){
			LogMessagesManager.PrintLogMessage("DoubleRailroadBuilder::BuildTrack: Time out.");
			if(final_path != null) DemolishDoubleRailroad(final_path);
			if(first_path != null) DemolishDoubleRailroad(first_path);
			return null;
		}else if(path == false){
			return false;
		}else if(path != null){
			local problem = false;
			LogMessagesManager.PrintLogMessage("DoubleRailroadBuilder::BuildTrack: Found a path (" +
				(AIDate.GetCurrentDate() - start_date) + " days) (" +
				(::ai_instance.GetTick() - start_tick) + " ticks).");

			PostProcessing(path);

			first_path = path;
			while(path != null && !problem){

				/* Bridge. */
				if(path.part_index == DoubleTrackParts.BRIDGE){
					if(!DoubleRailroadBuilder.BuildBridge(path.user_data)){
						if(AIError.GetLastError() == AIError.ERR_NOT_ENOUGH_CASH)
							enough_cash = false;
						problem = true;
					}

				/* Lines, Bends and Diagonals. */
				}else{
					if(!dtp.LandToBuildDoublePart(path.tile , path.part_index) ||
						!dtp.BuildDoublePart(path.tile , path.part_index)){
						if(AIError.GetLastError() == AIError.ERR_NOT_ENOUGH_CASH)
							enough_cash = false;
						problem = true;
					}
				}

				if(problem && enough_cash){
					ignored_nodes.push([path.tile , path.part_index , path]);

					for(local i = 0 ; path != null && i < 5 ; i++){
						switch(path.part_index){
							case DoubleTrackParts.BRIDGE:
								DemolishBridge(path.user_data);
							break;
							default:
								dtp.DemolishDoublePart(path.tile , path.part_index);
						}
						path = path.parent_path;
					}
					if(path != null){
						tile_from = path.tile;
						part_from = path.part_index;
						user_data = path.user_data;

						path.child_path = null;

						if(final_path == null) final_path = first_path;
						else
							final_path.Append(first_path);
					}
					initialize_a_star = true;
					continue;
				}

				if(path.child_path == null){
					if(final_path == null) final_path = first_path;
					else
						final_path.Append(first_path);
					break;
				}else	path = path.child_path;
			}
			/* We just finished the construction. */
			if(!problem) break;
		}else{
			LogMessagesManager.PrintLogMessage("DoubleRailroadBuilder::BuildTrack: Did not find a path.");
			if(final_path != null) DemolishDoubleRailroad(final_path);
			if(first_path != null) DemolishDoubleRailroad(first_path);
			return null;
		}
	}

	if(!enough_cash){
		LogMessagesManager.PrintLogMessage("DoubleRailroadBuilder::BuildTrack: I do not have enough money.");
		if(final_path != null) DemolishDoubleRailroad(final_path);
		if(first_path != null) DemolishDoubleRailroad(first_path);
		return null;
	}

	local double_railroad = DoubleRailroad();
	double_railroad.path = final_path;

	/* Build the depots. */
	{
		local depots_tiles_at_track_with_part_direction = DoubleDepotBuilder.BuildDepots(final_path , 90 , true);
		local depots_tiles_at_track_with_opposite_part_direction =
			DoubleDepotBuilder.BuildDepots(final_path , 90 , false);

		if(depots_tiles_at_track_with_part_direction.first == null ||
			depots_tiles_at_track_with_opposite_part_direction.first == null){

			LogMessagesManager.PrintLogMessage("DoubleRailroadBuilder::BuildTrack: Could not build the depots.");
			DemolishDoubleRailroad(final_path);
			return null;
		}

		double_railroad.depots_tiles_near_start = [depots_tiles_at_track_with_part_direction.first ,
			depots_tiles_at_track_with_opposite_part_direction.first];
		double_railroad.depots_tiles_near_end = [depots_tiles_at_track_with_part_direction.second ,
			depots_tiles_at_track_with_opposite_part_direction.second];
	}

	/* Build the signals. */
	BuildSignals(final_path , 6);

	return double_railroad;
}

function DoubleRailroadBuilder::PostProcessing(path) {
	/* Tries to find consecutive bridges and collapse them into a single one. */
	while (path != null) {
		/* Is it a bridge? */
		if(path.part_index == DoubleTrackParts.BRIDGE){
			/* TODO: We can make this generic. */
			if (path.child_path != null && path.child_path.part_index == DoubleTrackParts.BRIDGE
					&& path.user_data.CanBeCoalesced(path.child_path.user_data)) {

				path.user_data.Coalesce(path.child_path.user_data);

				path.child_path.Remove();

			} else if (path.child_path != null && path.child_path.child_path != null
					&& path.child_path.child_path.part_index == DoubleTrackParts.BRIDGE
					&& path.user_data.CanBeCoalesced(path.child_path.child_path.user_data)) {

				path.user_data.Coalesce(path.child_path.child_path.user_data);

				path.child_path.Remove();
				path.child_path.Remove();

			} else if (path.child_path != null && path.child_path.child_path != null && path.child_path.child_path.child_path != null
					&& path.child_path.child_path.child_path.part_index == DoubleTrackParts.BRIDGE
					&& path.user_data.CanBeCoalesced(path.child_path.child_path.child_path.user_data)) {

				path.user_data.Coalesce(path.child_path.child_path.child_path.user_data);

				path.child_path.Remove();
				path.child_path.Remove();
				path.child_path.Remove();
			}

			IntraPartBridgeCoalescence(path);
		}
		path = path.child_path;
	}
}

function DoubleRailroadBuilder::IntraPartBridgeCoalescence(path) {
	assert (path.part_index == DoubleTrackParts.BRIDGE);

	local ai_test_mode = AITestMode();
	local bridge_information = path.user_data;
	local primary_bridges = bridge_information.primary_bridges;
	local secondary_bridges = bridge_information.secondary_bridges;

	local collapseOneSide = function(bridges) {
		local i = 0;
		local j = 1;
		while (j < bridges.len()) {
			local start_i = bridges[i].first;
			local end_i = bridges[i].second;
			local start_j = bridges[j].first;
			local end_j = bridges[j].second;

			if (AIMap.DistanceManhattan(end_i, start_j) <= MAX_DISTANCE_TO_TRIE_COALESCENCE && AIMap.DistanceManhattan(start_i, end_j) <= BRIDGE_MAX_LENGTH
					&& AIBridge.BuildBridge(AIVehicle.VT_RAIL , 0 , start_i , end_j)) {
				bridges[i].second = bridges[j].second;
				bridges[j] = null;
				j++;
			} else {
				i = j;
				j++;
			}
		}
		Array.removeNull(bridges);
	};

	collapseOneSide(primary_bridges);
	collapseOneSide(secondary_bridges);
}
