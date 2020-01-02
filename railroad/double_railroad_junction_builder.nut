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


class JunctionInformation {
	path = null;
	junction_part_index = null;
	tile = null;

	constructor(path , junction_part_index , tile){
		this.path = path;
		this.junction_part_index = junction_part_index;
		this.tile = tile;
	}

	function _typeof(){
		return "JunctionInformation";
	}
}

class PossibleJunction {
	distance = null;
	junction_information = null;

	constructor(path , junction_part_index , distance , tile){
		this.junction_information = JunctionInformation(path , junction_part_index , tile);
		this.distance = distance;
	}

	function _cmp(other){
		return compare(this , other);
	}

	static function compare(pj1 , pj2){
		return pj1.distance - pj2.distance;
	}
}

class DoubleJunctionBuilder {
	/* Public: */
	start_paths = null;
	from_tile = null;
	gap_size = null;
	max_distance = null;
	possible_junctions = null;
	dtp = null;

	constructor(paths , from_tile , gap_size , max_distance){
		this.dtp = ::ai_instance.dtp;
		this.start_paths = paths;
		this.from_tile = from_tile;
		this.gap_size = gap_size;
		this.max_distance = max_distance;
		CalculatePossibleJunctions();
	}
	function GetBestPossibleJunction(){
		if(possible_junctions.len() < 1) return null;
		else return possible_junctions[0];
	}
	function BuildJunction(prefered_direction);
	static function DemolishJunction(junction_information);
	static function ConvertJunction(junction_information , rail_type);

	/* Private: */
	function CalculatePossibleJunctions();
	static function BuildJunctionPart(path , junction_part_index);
	static function CanBuildJunction(path , junction_part_index);
}


function DoubleJunctionBuilder::ConvertJunction(path , rail_type){
	local dtp = ::ai_instance.dtp;
	local junction_information = path.junction_information;
	local tile;

	if(junction_information == null || junction_information.path != path) return;
	tile = junction_information.tile;
	foreach(section in dtp.parts[junction_information.junction_part_index].sections){
		if(section.track != AIRail.RAILTRACK_INVALID)
		AIRail.ConvertRailType(section.offset + tile , section.offset + tile , rail_type);
	}
}

/* FIXME: if it is the prefered_direction the other can be selected too. */
function DoubleJunctionBuilder::BuildJunction(prefered_direction){
	local i = 0;
	local tries = 0;
	local max_tries = 25;
	local dtp = ::ai_instance.dtp;

	if(possible_junctions.len() <= 0) return null;
	while(i < possible_junctions.len()){
		local possible_junction = possible_junctions[i];
		if(Direction.GetOppositeDirection(prefered_direction) ==
				dtp.parts[possible_junction.junction_information.junction_part_index].entry_direction &&
			DoubleJunctionBuilder.CanBuildJunction(possible_junction.junction_information.path ,
			possible_junction.junction_information.junction_part_index)){
			if(!DoubleJunctionBuilder.BuildJunctionPart(possible_junction.junction_information)){
				if(AIError.GetLastError() == AIError.ERR_VEHICLE_IN_THE_WAY){
					tries++;
					if(tries < max_tries){
						::ai_instance.Sleep(50);
						continue;
					}
				}
				DoubleJunctionBuilder.DemolishJunction(possible_junction.junction_information);
			}else return possible_junction.junction_information;
		}
		i++;
		tries = 0;
	}
	return null;
}

function DoubleJunctionBuilder::CalculatePossibleJunctions(){
	local dtp = ::ai_instance.dtp;
	possible_junctions = array(0);

	foreach(path in start_paths){
		local length = path.Count();
		local c = 0;

		/* Provide a gap after source industry station. */
		while(path != null && c++ < gap_size){
			path = path.child_path;
		}
		/* Also provide a gap before destination industry station. */
		while(path != null && c++ < length - gap_size){
			local tile = path.tile;
			local part_index = path.part_index;
			if(dtp.IsLineBendOrDiagonal(part_index)){
				local distance = Tile.EuclideanDistance(from_tile , tile);
				foreach(junction in dtp.parts[part_index].junctions){
					local directions = Direction.GetDirectionsToTile(tile , from_tile);
					if(gap_size < distance && distance < max_distance &&
						(dtp.parts[junction.part_index].entry_direction == directions.first ||
						dtp.parts[junction.part_index].entry_direction == directions.second) &&
						DoubleJunctionBuilder.CanBuildJunction(path , junction.part_index)){
							possible_junctions.push(
								PossibleJunction(path , junction.part_index , distance ,
									tile + junction.offset));
					}
				}
			}
			path = path.child_path;
		}
	}
	if(possible_junctions.len() > 0) possible_junctions.sort(PossibleJunction.compare);
}

function DoubleJunctionBuilder::CanBuildJunction(path , junction_part_index){
	local tile = path.tile;
	local part_index = path.part_index;
	local junction = null;
	local constructed_tiles = BinaryTree();
	local dtp = ::ai_instance.dtp;

	/* Bends.*/
	if(dtp.IsBend(part_index)){
		if(path.parent_path == null || path.child_path == null ||
			!dtp.IsLineBendOrDiagonal(path.parent_path.part_index) ||
			!dtp.IsLineBendOrDiagonal(path.child_path.part_index) ||
			!dtp.AreTracksOnSameHeight(path.tile , path.part_index) ||
			path.parent_path.junction_information != null ||
			path.child_path.junction_information != null ||
			path.parent_path.depot_information != null ||
			path.child_path.depot_information != null ||
			path.depot_information != null ||
			path.junction_information != null) return false;

		foreach(section in dtp.parts[part_index].sections){
			if(!constructed_tiles.Exists(tile + section.offset))
				constructed_tiles.Insert(tile + section.offset);
		}

	/* Lines.*/
	}else if(dtp.IsLine(part_index)){
		if(path.parent_path == null || !dtp.IsLine(path.parent_path.part_index) ||
			path.parent_path.parent_path == null ||
			path.child_path == null ||
			!dtp.IsLineBendOrDiagonal(path.parent_path.parent_path.part_index) ||
			!dtp.IsLine(path.child_path.part_index) ||
			!dtp.IsLineLevel(path.tile , path.part_index) ||
			!dtp.IsLineLevel(path.parent_path.tile , path.parent_path.part_index) ||
			!dtp.AreTracksOnSameHeight(path.tile , path.part_index) ||
			!dtp.AreTracksOnSameHeight(path.parent_path.tile , path.parent_path.part_index) ||

			path.parent_path.parent_path.junction_information != null ||
			path.child_path.junction_information != null ||
			path.parent_path.parent_path.depot_information != null ||
			path.child_path.depot_information != null ||

			path.depot_information != null || path.parent_path.depot_information != null ||
			path.junction_information != null || path.parent_path.junction_information != null)
			return false;

		local parent_tile = path.parent_path.tile;
		foreach(section in dtp.parts[part_index].sections){
			if(!constructed_tiles.Exists(tile + section.offset))
				constructed_tiles.Insert(tile + section.offset);
			if(!constructed_tiles.Exists(parent_tile + section.offset))
				constructed_tiles.Insert(parent_tile + section.offset);
		}

	/* Diagonals.*/
	}else{
		if(path.parent_path == null || !dtp.IsDiagonal(path.parent_path.part_index) ||
			path.parent_path.parent_path == null ||
			path.child_path == null ||
			!dtp.IsLineBendOrDiagonal(path.parent_path.parent_path.part_index) ||
			!dtp.IsLineBendOrDiagonal(path.child_path.part_index) ||
			!dtp.AreTracksOnSameHeight(path.tile , path.part_index) ||
			!dtp.AreTracksOnSameHeight(path.parent_path.tile , path.parent_path.part_index) ||

			path.parent_path.parent_path.junction_information != null ||
			path.child_path.junction_information != null ||
			path.parent_path.parent_path.depot_information != null ||
			path.child_path.depot_information != null ||

			path.depot_information != null || path.parent_path.depot_information != null ||
			path.junction_information != null || path.parent_path.junction_information != null)
			return false;

		local parent_tile = path.parent_path.tile;
		foreach(section in dtp.parts[part_index].sections){
			if(!constructed_tiles.Exists(tile + section.offset))
				constructed_tiles.Insert(tile + section.offset);
			if(!constructed_tiles.Exists(parent_tile + section.offset))
				constructed_tiles.Insert(parent_tile + section.offset);
		}
	}
	foreach(j in dtp.parts[part_index].junctions){
		if(j.part_index == junction_part_index){
			junction = j;
			break;
		}
	}
	if(junction != null){
		foreach(section in dtp.parts[junction_part_index].sections){
			local junction_tile = section.offset + tile + junction.offset;
			local track = section.track;
			if(!constructed_tiles.Exists(junction_tile) &&
				!RailroadCommon.CanBuildRailOnLand(junction_tile)) return false;
		}
	}else assert(false);
	return true;
}

function DoubleJunctionBuilder::DemolishJunction(junction_information){
	local path = junction_information.path;
	local junction_part_index = junction_information.junction_part_index;
	local tile = path.tile;
	local part_index = path.part_index;
	local junction = null;
	local dtp = ::ai_instance.dtp;

	/* Bends.*/
	if(dtp.IsBend(part_index)){
		tile = path.parent_path.tile;
		part_index = path.parent_path.part_index;
		dtp.RemoveDoublePartSignals(tile , part_index);
		dtp.BuildDoublePartSignals(tile , part_index , AIRail.SIGNALTYPE_NORMAL);

		tile = path.child_path.tile;
		part_index = path.child_path.part_index;
		dtp.RemoveDoublePartSignals(tile , part_index);
		dtp.BuildDoublePartSignals(tile , part_index , AIRail.SIGNALTYPE_NORMAL);

	/* Lines and Diagonals.*/
	}else{
		tile = path.parent_path.parent_path.tile;
		part_index = path.parent_path.parent_path.part_index;
		dtp.RemoveDoublePartSignals(tile , part_index);
		dtp.BuildDoublePartSignals(tile , part_index , AIRail.SIGNALTYPE_NORMAL);

		tile = path.child_path.tile;
		part_index = path.child_path.part_index;
		dtp.RemoveDoublePartSignals(tile , part_index);
		dtp.BuildDoublePartSignals(tile , part_index , AIRail.SIGNALTYPE_NORMAL);
	}
	tile = path.tile;
	part_index = path.part_index;
	foreach(j in dtp.parts[part_index].junctions){
		if(j.part_index == junction_part_index){
			junction = j;
			break;
		}
	}
	assert(junction != null);
	dtp.DemolishDoublePart(junction.offset + tile , junction.part_index);
}

function DoubleJunctionBuilder::BuildJunctionPart(junction_information){
	local path = junction_information.path;
	local junction_part_index = junction_information.junction_part_index;
	local dtp = ::ai_instance.dtp;
	local tile = path.tile;
	local part_index = path.part_index;
	local junction = null;
	local height = dtp.GetDoublePartMainTileHeight(tile , part_index);

	/* Bends.*/
	if(dtp.IsBend(part_index)){
		tile = path.tile;
		part_index = path.part_index;
		if(!dtp.RemoveDoublePartSignals(tile , part_index)) return false;

		tile = path.parent_path.tile;
		part_index = path.parent_path.part_index;
		if(!dtp.RemoveDoublePartSignals(tile , part_index)) return false;
		if(!dtp.BuildDoublePartSignals(tile , part_index , AIRail.SIGNALTYPE_PBS_ONEWAY)) return false;

		tile = path.child_path.tile;
		part_index = path.child_path.part_index;
		if(!dtp.RemoveDoublePartSignals(tile , part_index)) return false;
		if(!dtp.BuildDoublePartSignals(tile , part_index , AIRail.SIGNALTYPE_PBS_ONEWAY)) return false;

	/* Lines and Diagonals.*/
	}else{
		tile = path.parent_path.tile;
		part_index = path.parent_path.part_index;
		if(!dtp.RemoveDoublePartSignals(tile , part_index)) return false;

		tile = path.tile;
		part_index = path.part_index;
		if(!dtp.RemoveDoublePartSignals(tile , part_index)) return false;

		tile = path.parent_path.parent_path.tile;
		part_index = path.parent_path.parent_path.part_index;
		if(!dtp.RemoveDoublePartSignals(tile , part_index)) return false;
		if(!dtp.BuildDoublePartSignals(tile , part_index , AIRail.SIGNALTYPE_PBS_ONEWAY)) return false;

		tile = path.child_path.tile;
		part_index = path.child_path.part_index;
		if(!dtp.RemoveDoublePartSignals(tile , part_index)) return false;
		if(!dtp.BuildDoublePartSignals(tile , part_index , AIRail.SIGNALTYPE_PBS_ONEWAY)) return false;
	}

	tile = path.tile;
	part_index = path.part_index;
	foreach(j in dtp.parts[part_index].junctions){
		if(j.part_index == junction_part_index){
			junction = j;
			break;
		}
	}
	assert(junction != null);
	/* Try to level the junction part. */
	dtp.LevelPart(junction_information.tile , junction.part_index , height);

	if(!dtp.BuildDoublePart(junction_information.tile , junction.part_index)) return false;
	if(!dtp.BuildDoublePartSignals(junction_information.tile ,
		junction.part_index , AIRail.SIGNALTYPE_PBS_ONEWAY)) return false;

	/* Now, insert the junction_information in the path nodes that were affected. */
	/* Bends.*/
	if(dtp.IsBend(part_index)){
		assert(path.junction_information == null);
		path.junction_information = junction_information;
	/* Lines and Diagonals.*/
	}else{
		assert(path.junction_information == null);
		path.junction_information = junction_information;
		assert(path.parent_path.junction_information == null);
		path.parent_path.junction_information = junction_information;
	}
	return true;
}
