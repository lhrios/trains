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


class DoubleDepotBuilder {
	/* Public: */
	static function BuildDepots(path , interval , at_track_with_part_direction);
	static function ConvertDepotPart(path , rail_type);
	static function DemolishDepotPart(path , at_track_with_part_direction);

	/* Private: */
	static function CanBuildDepot(path , at_track_with_part_direction);
	static function BuildDepotPart(path , at_track_with_part_direction);
}

class DepotInformation {
	path = null;
	depot_position_index = null;

	constructor(path , depot_position_index){
		this.path = path;
		this.depot_position_index = depot_position_index;
	}

	function _typeof(){
		return "DepotInformation";
	}
}

function DoubleDepotBuilder::BuildDepots(path , interval , at_track_with_part_direction){
	local c = 0;
	local must_build_depot = false;
	local first_depot_tile = null , last_depot_tile = null;
	local last_depot = 0;
	local dtp = ::ai_instance.dtp;

	while(true){
		local tile = path.tile;
		local part_index = path.part_index;

		if(c % interval == 0) must_build_depot = true;

		if(must_build_depot){
			if(dtp.IsLineBendOrDiagonal(part_index) &&
				DoubleDepotBuilder.CanBuildDepot(path , at_track_with_part_direction)){
				local aux;

				aux = DoubleDepotBuilder.BuildDepotPart(path , at_track_with_part_direction);
				if(aux != null){
					if(first_depot_tile == null) first_depot_tile = aux;
					last_depot_tile = aux;
					must_build_depot = false;
					last_depot = c;
				}
			}
		}
		if(path.child_path == null) break;
		path = path.child_path;
		c++;
	}

	if(c - last_depot > interval/2.0){
		last_depot += interval/4;
		while(c > last_depot && path != null){
			local tile = path.tile;
			local part_index = path.part_index;

			if(dtp.IsLineBendOrDiagonal(part_index) &&
				DoubleDepotBuilder.CanBuildDepot(path , at_track_with_part_direction)){
				local aux = DoubleDepotBuilder.BuildDepotPart(path , at_track_with_part_direction);
				if(aux != null){
					last_depot_tile = aux;
					break;
				}
			}
			c--;
			path = path.parent_path;
		}
	}

	return Pair(first_depot_tile , last_depot_tile);
}

/* TODO: Consider the use of terraforming. */
function DoubleDepotBuilder::CanBuildDepot(path , at_track_with_part_direction){
	local dtp = ::ai_instance.dtp;
	local tile = path.tile;
	local part_index = path.part_index;
	local depot = null;
	local depot_part_index;
	local can_build_depot = false;
	local depot_index;

	if(at_track_with_part_direction) depot_index = 0;
	else depot_index = 1;

	/* Bends. */
	if(dtp.IsBend(part_index)){
		if(dtp.parts[part_index].depots[depot_index] == null) return false;
		depot = dtp.parts[part_index].depots[depot_index];
		depot_part_index = depot.part_index;
	/* Diagonals.*/
	}else if(dtp.IsDiagonal(part_index)){
		if(path.parent_path == null || !dtp.IsDiagonal(path.parent_path.part_index)) return false;
		depot = dtp.parts[part_index].depots[depot_index];
		depot_part_index = depot.part_index;
	/* Lines.*/
	}else{
		if(path.parent_path == null || !dtp.IsLine(path.parent_path.part_index) ||
			path.child_path == null || !dtp.IsLine(path.child_path.part_index)) return false;
		depot = dtp.parts[part_index].depots[depot_index];
		depot_part_index = depot.part_index;
	}

	if(dtp.IsBoomerang(depot_part_index)){
		for(local i = 0 ; i < 3 ; i++){
			local section = dtp.parts[depot_part_index].sections[i];
			if(i == 1){
				if(!RailroadCommon.CanBuildRailOnLand(depot.offset + tile + section.offset) ||
					!RailroadCommon.CanBuildTrackOnSlope(depot.offset + tile + section.offset , section.track)) return false;
			}else{
				if(!RailroadCommon.CanBuildTrackOnSlope(depot.offset + tile + section.offset , section.track)) return false;
			}
		}
	}

	foreach(depot_position in dtp.parts[depot_part_index].depot_positions){
		local depot_tile = depot_position.offset + tile + depot.offset;
		local depot_front_tile = depot_position.sections[0].offset + tile + depot.offset;
		local problem = false;
		if(!RailroadCommon.CanBuildRailOnLand(depot_tile)) continue;
		{
			local ai_test_mode = AITestMode();
			if(!AIRail.BuildRailDepot(depot_tile , depot_front_tile)) continue;
		}
		foreach(section in depot_position.sections){
			local track = section.track;
			if(!RailroadCommon.CanBuildTrackOnSlope(depot_front_tile , track)){
				problem = true;
				break;
			}
		}
		if(!problem) can_build_depot = true;
	}
	return can_build_depot;
}

function DoubleDepotBuilder::ConvertDepotPart(path , rail_type){
	local pair = path.depot_information;
	local depot_information;
	local part_index = path.part_index;
	local tile = path.tile;
	local dtp = ::ai_instance.dtp;

	if(pair == null) return;
	depot_information = pair.first;
	if(depot_information != null && depot_information.path == path){
		local depot = dtp.parts[part_index].depots[0];
		local depot_part_index = depot.part_index;
		local depot_position = dtp.parts[depot_part_index].depot_positions[depot_information.depot_position_index];
		local depot_tile = depot_position.offset + tile + depot.offset;
		local depot_front_tile = depot_position.sections[0].offset + tile + depot.offset;
		if(dtp.IsBoomerang(depot_part_index))
			AIRail.ConvertRailType(depot_front_tile  , depot_front_tile , rail_type);
		AIRail.ConvertRailType(depot_tile , depot_tile , rail_type);
	}
	depot_information = pair.second;
	if(depot_information != null && depot_information.path == path){
		local depot = dtp.parts[part_index].depots[1];
		local depot_part_index = depot.part_index;
		local depot_position = dtp.parts[depot_part_index].depot_positions[depot_information.depot_position_index];
		local depot_tile = depot_position.offset + tile + depot.offset;
		local depot_front_tile = depot_position.sections[0].offset + tile + depot.offset;
		if(dtp.IsBoomerang(depot_part_index))
			AIRail.ConvertRailType(depot_front_tile  , depot_front_tile , rail_type);
		AIRail.ConvertRailType(depot_tile , depot_tile , rail_type);
	}
}

function DoubleDepotBuilder::BuildDepotPart(path , at_track_with_part_direction){
	local dtp = ::ai_instance.dtp;
	local tile = path.tile;
	local part_index = path.part_index;
	local depot = null;
	local depot_part_index;
	local depot_index;
	local depot_position_index = 0;

	if(at_track_with_part_direction) depot_index = 0;
	else depot_index = 1;

	depot = dtp.parts[part_index].depots[depot_index];
	depot_part_index = depot.part_index;

	if(dtp.parts[depot_part_index].sections != null){
		if(!dtp.BuildDoublePart(tile + depot.offset , depot_part_index)){
			dtp.DemolishDoublePart(tile + depot.offset , depot_part_index);
			return null;
		}
	}

	foreach(depot_position in dtp.parts[depot_part_index].depot_positions){
		local depot_tile = depot_position.offset + tile + depot.offset;
		local depot_front_tile = depot_position.sections[0].offset + tile + depot.offset;

		if(RailroadCommon.CanBuildRailOnLand(depot_tile)){
			if(!AIRail.BuildRailDepot(depot_tile , depot_front_tile)){
				dtp.DemolishDoublePart(tile + depot.offset , depot_part_index);
				return null;
			}

			foreach(section in depot_position.sections){
				if(!AIRail.BuildRailTrack(depot_front_tile , section.track)){
					dtp.DemolishDoublePart(tile + depot.offset , depot_part_index);
					AITile.DemolishTile(depot_tile);
					AITile.DemolishTile(depot_front_tile);
					return null;
				}
			}

			local depot_information = DepotInformation(path , depot_position_index);
			local pair;
			/* Bends. */
			if(dtp.IsBend(part_index)){
				pair = Pair();
				if(at_track_with_part_direction){
					pair.first = depot_information;
				}else{
					pair.second = depot_information;
				}
				path.depot_information = pair;
			/* Diagonals.*/
			}else if(dtp.IsDiagonal(part_index)){
				if(path.depot_information != null){
					pair = path.depot_information;
					assert(typeof(pair) == "Pair");
				}else{
					pair = Pair();
					path.depot_information = pair;
				}
				if(at_track_with_part_direction){
					assert(pair.first == null);
					pair.first = depot_information;
				}else{
					assert(pair.second == null);
					pair.second = depot_information;
				}

				path = path.parent_path;
				if(path.depot_information != null){
					pair = path.depot_information;
					assert(typeof(pair) == "Pair");
				}else{
					pair = Pair();
					path.depot_information = pair;
				}
				if(at_track_with_part_direction){
					assert(pair.first == null);
					pair.first = depot_information;
				}else{
					assert(pair.second == null);
					pair.second = depot_information;
				}

			/* Lines.*/
			}else{
				if(path.depot_information != null){
					pair = path.depot_information;
					assert(typeof(pair) == "Pair");
				}else{
					pair = Pair();
					path.depot_information = pair;
				}
				if(at_track_with_part_direction){
					assert(pair.first == null);
					pair.first = depot_information;
				}else{
					assert(pair.second == null);
					pair.second = depot_information;
				}
			}

			return depot_tile;
		}
		depot_position_index++;
	}
	return null;
}

function DoubleDepotBuilder::DemolishDepotPart(path , at_track_with_part_direction){
	local dtp = ::ai_instance.dtp;
	local tile = path.tile;
	local part_index = path.part_index;
	local depot = null;
	local depot_part_index;
	local depot_index;
	local depot_position;
	local depot_position_index;
	local depot_information;
	local depot_tile , depot_front_tile;
	local pair;

	pair = path.depot_information;
	if(pair == null) return;
	assert(typeof(pair) == "Pair");

	if(at_track_with_part_direction){
		depot_index = 0;
		depot_information = pair.first;
		if(depot_information == null || depot_information.path != path) return;
		pair.first = null;
	}else{
		depot_index = 1;
		depot_information = pair.second;
		if(depot_information == null || depot_information.path != path) return;
		pair.second = null;
	}
	if(pair.first == null && pair.second == null)
		path.depot_information = null;

	depot = dtp.parts[part_index].depots[depot_index];
	depot_part_index = depot.part_index;
	depot_position_index = depot_information.depot_position_index;
	depot_position = dtp.parts[depot_part_index].depot_positions[depot_position_index];
	depot_tile = depot_position.offset + tile + depot.offset;
	depot_front_tile = depot_position.sections[0].offset + tile + depot.offset;

	/* Finally demolish the depot and its tracks. */
	dtp.DemolishDoublePart(tile + depot.offset , depot_part_index);
	AITile.DemolishTile(depot_tile);
	AITile.DemolishTile(depot_front_tile);

	/* Diagonals.*/
	if(dtp.IsDiagonal(part_index)){
		path = path.parent_path;
		pair = path.depot_information;
		assert(typeof(pair) == "Pair");
		if(at_track_with_part_direction){
			pair.first = null;
		}else{
			pair.second = null;
		}
		if(pair.first == null && pair.second == null)
			path.depot_information = null;
	}
}
