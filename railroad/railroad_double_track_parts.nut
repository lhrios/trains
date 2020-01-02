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


/**
* Orientation:
*                                            /\                  / \
*          Y                              S /  \ W              /   \
*          ^                               /    \             X/     \Y
*          |      N                        \    /
*          |   W     E                    E \  / N
*          |      S                          \/
*          |___________> X
*
*
*/

class Section {
	offset = null;
	track = null;
	constructor(offset , track){
		this.offset = offset;
		this.track = track;
	}
}

class Point {
	tile = null;
	height = null;
	constructor(tile , height){
		this.tile = tile;
		this.height = height;
	}

	function _tostring(){
		local s = Tile.ToString(tile);
		s += " : " + height.tostring();
		return s;
	}
}

class Part {
	sections = null;
	points = null
	signal_senses = null;
}

class ConventionalPart extends Part {
	next_tile = null;
	continuation_parts = null;
	previous_parts = null;
	depots = null;
	junctions = null;
	parts_keep_direction = null;
}

class JunctionPart extends Part {
	entry_direction = null;
	previous_part = null;
	previous_part_offset = null;
}

class DepotPart extends Part {
	depot_positions = null;
}

class Junction {
	offset = null;
	part_index = null;
	constructor(offset , part_index){
		this.offset = offset;
		this.part_index = part_index;
	}
}

class DepotPosition {
	sections = null;
	offset = null;
	points = null;
}

class Depot {
	offset = null;
	part_index = null;

	constructor(offset , part_index){
		this.offset = offset;
		this.part_index = part_index;
	}
}

class DoubleTrackParts {
	/* Public: */
	static EW_LINE = 0;
	static WE_LINE = 1;

	static NS_LINE = 2;
	static SN_LINE = 3;

	static NE_BEND = 4;
	static EN_BEND = 5;

	static SW_BEND = 6;
	static WS_BEND = 7;

	static ES_BEND = 8;
	static SE_BEND = 9;

	static NW_BEND = 10;
	static WN_BEND = 11;

	static NS_P_DIAGONAL = 12;
	static SN_P_DIAGONAL = 13;

	static WE_P_DIAGONAL = 14
	static EW_P_DIAGONAL = 15;

	static NS_S_DIAGONAL = 16;
	static SN_S_DIAGONAL = 17;

	static WE_S_DIAGONAL = 18;
	static EW_S_DIAGONAL = 19;

	static TUNNEL = 20;
	static BRIDGE = 21;

	/* Junctions: */
	static J_EW_RECTANGLE = 22;
	static J_WE_RECTANGLE = 23;

	static J_NS_RECTANGLE = 24;
	static J_SN_RECTANGLE = 25;

	static J_WN_HOOK = 26;
	static J_NW_HOOK = 27;

	static J_SE_HOOK = 28;
	static J_ES_HOOK = 29;

	static J_EN_HOOK = 30;
	static J_NE_HOOK = 31;

	static J_SW_HOOK = 32;
	static J_WS_HOOK = 33;

	/* Depot Parts: */
	static EN_BOOMERANG = 34;
	static SW_BOOMERANG = 35;
	static SE_BOOMERANG = 36;
	static WN_BOOMERANG = 37;

	static SWE_V = 38;
	static NWS_V = 39;
	static SEN_V = 40;
	static NEW_V = 41;

	static N_PARTS = 42;

	static parts_names = ["EW_LINE" , "WE_LINE" , "NS_LINE" , "SN_LINE" ,
		"NE_BEND" , "EN_BEND" , "SW_BEND" , "WS_BEND" ,
		"ES_BEND" , "SE_BEND" , "NW_BEND" , "WN_BEND" ,
		"NS_P_DIAGONAL" , "SN_P_DIAGONAL" , "WE_P_DIAGONAL" , "EW_P_DIAGONAL" ,
		"NS_S_DIAGONAL" , "SN_S_DIAGONAL" , "WE_S_DIAGONAL" , "EW_S_DIAGONAL" ,
		"TUNNEL" , "BRIDGE" ,
		"J_EW_RECTANGLE" , "J_WE_RECTANGLE" , "J_NS_RECTANGLE" , "J_SN_RECTANGLE" ,
		"J_WN_HOOK" , "J_NW_HOOK" , "J_SE_HOOK" , "J_ES_HOOK" ,
		"J_EN_HOOK" , "J_NE_HOOK" , "J_SW_HOOK" , "J_WS_HOOK" ,
		"EN_BOOMERANG" , "SW_BOOMERANG" , "SE_BOOMERANG" , "WN_BOOMERANG" ,
		"SWE_V" , "NWS_V" , "SEN_V" , "NEW_V" ,
		"N_PARTS"];

	parts = null;

	constructor(){
		Initialize();
	}

	/* Debug: */
	function BuildAllDepotParts(tile);
	function BuildAllParts(tile);
	function BuildAllJunctionParts(tile);
	function ToString(part_index);
	function ConvertAllParts(tile , rail_type);

	function BuildDoublePart(tile , part_index);
	function BuildDoublePartSignals(tile , part_index , signal_type);
	function RemoveDoublePartSignals(tile , part_index);
	function DemolishDoublePart(tile , part_index);
	function LandToBuildDoublePart(tile , part_index);
	function SlopesToBuildDoublePart(tile , part_index);
	function ChangedDirection(parent_part , children_part);
	function IsLineBendOrDiagonal(part_index);
	function IsLine(part_index);
	function IsNotLine(part_index);
	function IsBend(part_index);
	function IsDiagonal(part_index);
	function GetDoublePartTilesHeight(tile , part_index);
	function GetEntryPartHeight(tile , part_index);
	function LevelPart(tile , part_index , height);
	function GetOppositePart(part_index);
	function GetOppositePartTile(tile , part_index);
	function ConvertDoublePart(tile , part_index , rail_type);
	function IsJunction(part_index);
	function IsDepot(part_index);
	function IsLineLevel(tile , part_index);
	function AreTracksOnSameHeight(tile , part_index);
	function IsBoomerang(part_index);
	function IsBridgeOrTunnel(part_index);

	/* Private: */
	function Initialize();
}

function DoubleTrackParts::IsBridgeOrTunnel(part_index){
	return part_index == BRIDGE || part_index == TUNNEL;
}

function DoubleTrackParts::AreTracksOnSameHeight(tile , part_index){
	/* Lines. */
	if(IsLine(part_index)){
		local heights = array(0);
		foreach(section in parts[part_index].sections){
			heights.push(Tile.GetFlatSlopeTileHeight(tile + section.offset));
		}
		if(heights[0] != heights[1]) return false;
		return true;
	/* Bends and Diagonals.*/
	}else{
		local tiles = BinaryTree();
		local main_tile;
		foreach(section in parts[part_index].sections){
			if(tiles.Exists(tile + section.offset)){
				main_tile = tile + section.offset;
				break;
			}else{
				tiles.Insert(tile + section.offset);
			}
		}
		local slope = AITile.GetSlope(main_tile);
		switch(slope){
			case AITile.SLOPE_W:
			case AITile.SLOPE_E:
			case AITile.SLOPE_S:
			case AITile.SLOPE_N:
				return false;
			default:
				return true;
		}
	}
}

function DoubleTrackParts::IsLineLevel(tile , part_index){
	if(!IsLine(part_index)) throw("This function only supports lines.");
	foreach(section in parts[part_index].sections){
		if(!RailroadCommon.IsTrackLevel(tile + section.offset , section.track)) return false;
	}
	return true;
}

function DoubleTrackParts::GetDoublePartMainTileHeight(tile , part_index){
	local tiles = BinaryTree();

	/* Bends and Diagonals.*/
	if(!IsLine(part_index)){
		foreach(section in parts[part_index].sections){
			if(tiles.Exists(tile + section.offset)){
				return Tile.GetFlatSlopeTileHeight(tile + section.offset);
			}else{
				tiles.Insert(tile + section.offset);
			}
		}
	/* Lines.*/
	}else if(IsLine(part_index)){
		return Tile.GetFlatSlopeTileHeight(tile);
	}else{
		throw("This function this not support " + ToString(part_index) + ".");
	}
}

function DoubleTrackParts::IsJunction(part_index){
	return J_EW_RECTANGLE <= part_index && part_index <= J_WS_HOOK;
}

function DoubleTrackParts::IsDepot(part_index){
	return EN_BOOMERANG <= part_index && part_index <= NEW_V;
}

function DoubleTrackParts::IsBoomerang(part_index){
	return EN_BOOMERANG <= part_index && part_index <= WN_BOOMERANG;
}

function DoubleTrackParts::Initialize(){
	local i , part;
	parts = array(N_PARTS);
	for(i = 0 ; i < N_PARTS ; i++){
		if(IsJunction(i))
			parts[i] = JunctionPart();
		else if(IsDepot(i))
			parts[i] = DepotPart();
		else if(IsLineBendOrDiagonal(i))
			parts[i] = ConventionalPart();
	}

	/* Depot Parts: */

	/* NEW_V */
	part = parts[NEW_V];

	part.depot_positions = array(1);
	part.depot_positions[0] = DepotPosition();
	part.depot_positions[0].sections = array(2);
	part.depot_positions[0].sections[0] = Section(
		AIMap.GetTileIndex(0 , 0) , AIRail.RAILTRACK_SW_SE);
	part.depot_positions[0].sections[1] = Section(
		AIMap.GetTileIndex(0 , 0) , AIRail.RAILTRACK_NE_SE);
	part.depot_positions[0].offset = AIMap.GetTileIndex(0 , 1);

	/* SWE_V */
	part = parts[SWE_V];

	part.depot_positions = array(1);
	part.depot_positions[0] = DepotPosition();
	part.depot_positions[0].sections = array(2);
	part.depot_positions[0].sections[0] = Section(
		AIMap.GetTileIndex(0 , 0) , AIRail.RAILTRACK_NW_NE);
	part.depot_positions[0].sections[1] = Section(
		AIMap.GetTileIndex(0 , 0) , AIRail.RAILTRACK_NW_SW);
	part.depot_positions[0].offset = AIMap.GetTileIndex(0 , -1);

	/* SEN_V */
	part = parts[SEN_V];

	part.depot_positions = array(1);
	part.depot_positions[0] = DepotPosition();
	part.depot_positions[0].sections = array(2);
	part.depot_positions[0].sections[0] = Section(
		AIMap.GetTileIndex(0 , 0) , AIRail.RAILTRACK_SW_SE);
	part.depot_positions[0].sections[1] = Section(
		AIMap.GetTileIndex(0 , 0) , AIRail.RAILTRACK_NW_SW);
	part.depot_positions[0].offset = AIMap.GetTileIndex(1 , 0);

	/* NWS_V */
	part = parts[NWS_V];

	part.depot_positions = array(1);
	part.depot_positions[0] = DepotPosition();
	part.depot_positions[0].sections = array(2);
	part.depot_positions[0].sections[0] = Section(
		AIMap.GetTileIndex(0 , 0) , AIRail.RAILTRACK_NW_NE);
	part.depot_positions[0].sections[1] = Section(
		AIMap.GetTileIndex(0 , 0) , AIRail.RAILTRACK_NE_SE);
	part.depot_positions[0].offset = AIMap.GetTileIndex(-1 , 0);

	/* EN_BOOMERANG */
	part = parts[EN_BOOMERANG];
	part.sections = array(3);
	part.sections[0] = Section(
		AIMap.GetTileIndex(0 , 0) , AIRail.RAILTRACK_NW_SE);
	part.sections[1] = Section(
		AIMap.GetTileIndex(0 , -1) , AIRail.RAILTRACK_SW_SE);
	part.sections[2] = Section(
		AIMap.GetTileIndex(1 , -1) , AIRail.RAILTRACK_NE_SW);

	part.depot_positions = array(2);
	part.depot_positions[0] = DepotPosition();
	part.depot_positions[0].sections = array(2);
	part.depot_positions[0].sections[0] = Section(
		AIMap.GetTileIndex(0 , -1) , AIRail.RAILTRACK_NW_SE);
	part.depot_positions[0].sections[1] = Section(
		AIMap.GetTileIndex(0 , -1) , AIRail.RAILTRACK_NW_SW);
	part.depot_positions[0].offset = AIMap.GetTileIndex(0 , -2);

	part.depot_positions[1] = DepotPosition();
	part.depot_positions[1].sections = array(2);
	part.depot_positions[1].sections[0] = Section(
		AIMap.GetTileIndex(0 , -1) , AIRail.RAILTRACK_NE_SW);
	part.depot_positions[1].sections[1] = Section(
		AIMap.GetTileIndex(0 , -1) , AIRail.RAILTRACK_NE_SE);
	part.depot_positions[1].offset = AIMap.GetTileIndex(-1 , -1);

	/* SW_BOOMERANG */
	part = parts[SW_BOOMERANG];
	part.sections = array(3);
	part.sections[0] = Section(
		AIMap.GetTileIndex(0 , 0) , AIRail.RAILTRACK_NE_SW);
	part.sections[1] = Section(
		AIMap.GetTileIndex(1 , 0) , AIRail.RAILTRACK_NW_NE);
	part.sections[2] = Section(
		AIMap.GetTileIndex(1 , -1) , AIRail.RAILTRACK_NW_SE);

	part.depot_positions = array(2);
	part.depot_positions[0] = DepotPosition();
	part.depot_positions[0].sections = array(2);
	part.depot_positions[0].sections[0] = Section(
		AIMap.GetTileIndex(1 , 0) , AIRail.RAILTRACK_NW_SE);
	part.depot_positions[0].sections[1] = Section(
		AIMap.GetTileIndex(1 , 0) , AIRail.RAILTRACK_NE_SE);
	part.depot_positions[0].offset = AIMap.GetTileIndex(1 , 1);

	part.depot_positions[1] = DepotPosition();
	part.depot_positions[1].sections = array(2);
	part.depot_positions[1].sections[0] = Section(
		AIMap.GetTileIndex(1 , 0) , AIRail.RAILTRACK_NE_SW);
	part.depot_positions[1].sections[1] = Section(
		AIMap.GetTileIndex(1 , 0) , AIRail.RAILTRACK_NW_SW);
	part.depot_positions[1].offset = AIMap.GetTileIndex(2 , 0);

	/* SE_BOOMERANG */
	part = parts[SE_BOOMERANG];
	part.sections = array(3);
	part.sections[0] = Section(
		AIMap.GetTileIndex(0 , 0) , AIRail.RAILTRACK_NE_SW);
	part.sections[1] = Section(
		AIMap.GetTileIndex(-1 , 0) , AIRail.RAILTRACK_NW_SW);
	part.sections[2] = Section(
		AIMap.GetTileIndex(-1 , -1) , AIRail.RAILTRACK_NW_SE);

	part.depot_positions = array(2);
	part.depot_positions[0] = DepotPosition();
	part.depot_positions[0].sections = array(2);
	part.depot_positions[0].sections[0] = Section(
		AIMap.GetTileIndex(-1 , 0) , AIRail.RAILTRACK_NE_SW);
	part.depot_positions[0].sections[1] = Section(
		AIMap.GetTileIndex(-1 , 0) , AIRail.RAILTRACK_NW_NE);
	part.depot_positions[0].offset = AIMap.GetTileIndex(-2 , 0);

	part.depot_positions[1] = DepotPosition();
	part.depot_positions[1].sections = array(2);
	part.depot_positions[1].sections[0] = Section(
		AIMap.GetTileIndex(-1 , 0) , AIRail.RAILTRACK_NW_SE);
	part.depot_positions[1].sections[1] = Section(
		AIMap.GetTileIndex(-1 , 0) , AIRail.RAILTRACK_SW_SE);
	part.depot_positions[1].offset = AIMap.GetTileIndex(-1 , 1);

	/* WN_BOOMERANG */
	part = parts[WN_BOOMERANG];
	part.sections = array(3);
	part.sections[0] = Section(
		AIMap.GetTileIndex(0 , 0) , AIRail.RAILTRACK_NW_SE);
	part.sections[1] = Section(
		AIMap.GetTileIndex(0 , -1) , AIRail.RAILTRACK_NE_SE);
	part.sections[2] = Section(
		AIMap.GetTileIndex(-1 , -1) , AIRail.RAILTRACK_NE_SW);

	part.depot_positions = array(2);
	part.depot_positions[0] = DepotPosition();
	part.depot_positions[0].sections = array(2);
	part.depot_positions[0].sections[0] = Section(
		AIMap.GetTileIndex(0 , -1) , AIRail.RAILTRACK_NW_SE);
	part.depot_positions[0].sections[1] = Section(
		AIMap.GetTileIndex(0 , -1) , AIRail.RAILTRACK_NW_NE);
	part.depot_positions[0].offset = AIMap.GetTileIndex(0 , -2);

	part.depot_positions[1] = DepotPosition();
	part.depot_positions[1].sections = array(2);
	part.depot_positions[1].sections[0] = Section(
		AIMap.GetTileIndex(0 , -1) , AIRail.RAILTRACK_NE_SW);
	part.depot_positions[1].sections[1] = Section(
		AIMap.GetTileIndex(0 , -1) , AIRail.RAILTRACK_SW_SE);
	part.depot_positions[1].offset = AIMap.GetTileIndex(1 , -1);

	/* Junctions: */

	/* J_EW_RECTANGLE */
	part = parts[J_EW_RECTANGLE];
	part.entry_direction = Direction.EAST;
	part.previous_part = EW_LINE;
	part.previous_part_offset = AIMap.GetTileIndex(1 , 0);

	part.sections = array(10);
	part.sections[0] = Section(
		AIMap.GetTileIndex(0 , 0) , AIRail.RAILTRACK_NE_SW);
	part.sections[1] = Section(
		AIMap.GetTileIndex(-1 , 0) , AIRail.RAILTRACK_NE_SW);
	part.sections[2] = Section(
		AIMap.GetTileIndex(-2 , 0) , AIRail.RAILTRACK_NE_SW);
	part.sections[3] = Section(
		AIMap.GetTileIndex(0 , -1) , AIRail.RAILTRACK_NE_SW);
	part.sections[4] = Section(
		AIMap.GetTileIndex(-1 , -1) , AIRail.RAILTRACK_NE_SW);
	part.sections[5] = Section(
		AIMap.GetTileIndex(-2 , -1) , AIRail.RAILTRACK_NE_SW);
	part.sections[6] = Section(
		AIMap.GetTileIndex(1 , -1) , AIRail.RAILTRACK_INVALID);
	part.sections[7] = Section(
		AIMap.GetTileIndex(2 , -1) , AIRail.RAILTRACK_INVALID);
	part.sections[8] = Section(
		AIMap.GetTileIndex(1 , 0) , AIRail.RAILTRACK_INVALID);
	part.sections[9] = Section(
		AIMap.GetTileIndex(2 , 0) , AIRail.RAILTRACK_INVALID);

	part.points = array(18);
	part.points[0] = AIMap.GetTileIndex(-2 , -1);
	part.points[1] = AIMap.GetTileIndex(-2 , 0);
	part.points[2] = AIMap.GetTileIndex(-2 , 1);
	part.points[3] = AIMap.GetTileIndex(-1 , -1);
	part.points[4] = AIMap.GetTileIndex(-1 , 0);
	part.points[5] = AIMap.GetTileIndex(-1 , 1);
	part.points[6] = AIMap.GetTileIndex(0 , -1);
	part.points[7] = AIMap.GetTileIndex(0 , 0);
	part.points[8] = AIMap.GetTileIndex(0 , 1);
	part.points[9] = AIMap.GetTileIndex(1 , -1);
	part.points[10] = AIMap.GetTileIndex(1 , 0);
	part.points[11] = AIMap.GetTileIndex(1 , 1);
	part.points[12] = AIMap.GetTileIndex(2 , -1);
	part.points[13] = AIMap.GetTileIndex(2 , 0);
	part.points[14] = AIMap.GetTileIndex(2 , 1);
	part.points[15] = AIMap.GetTileIndex(3 , -1);
	part.points[16] = AIMap.GetTileIndex(3 , 0);
	part.points[17] = AIMap.GetTileIndex(3 , 1);

	part.signal_senses = array(10);
	part.signal_senses[0] = RailroadCommon.COUNTERCLOCKWISE;
	part.signal_senses[1] = RailroadCommon.INVALID_SENSE;
	part.signal_senses[2] = RailroadCommon.INVALID_SENSE;
	part.signal_senses[3] = RailroadCommon.CLOCKWISE;
	part.signal_senses[4] = RailroadCommon.INVALID_SENSE;
	part.signal_senses[5] = RailroadCommon.INVALID_SENSE;
	part.signal_senses[6] = RailroadCommon.INVALID_SENSE;
	part.signal_senses[7] = RailroadCommon.INVALID_SENSE;
	part.signal_senses[8] = RailroadCommon.INVALID_SENSE;
	part.signal_senses[9] = RailroadCommon.INVALID_SENSE;

	/* J_WE_RECTANGLE */
	part = parts[J_WE_RECTANGLE];
	part.entry_direction = Direction.WEST;
	part.previous_part = WE_LINE;
	part.previous_part_offset = AIMap.GetTileIndex(-2 , 1);

	part.sections = array(10);
	part.sections[0] = Section(
		AIMap.GetTileIndex(0 , 0) , AIRail.RAILTRACK_NE_SW);
	part.sections[1] = Section(
		AIMap.GetTileIndex(-1 , 1) , AIRail.RAILTRACK_NE_SW);
	part.sections[2] = Section(
		AIMap.GetTileIndex(-2 , 1) , AIRail.RAILTRACK_NE_SW);
	part.sections[3] = Section(
		AIMap.GetTileIndex(-1 , 0) , AIRail.RAILTRACK_NE_SW);
	part.sections[4] = Section(
		AIMap.GetTileIndex(-2 , 0) , AIRail.RAILTRACK_NE_SW);
	part.sections[5] = Section(
		AIMap.GetTileIndex(0 , 1) , AIRail.RAILTRACK_NE_SW);
	part.sections[6] = Section(
		AIMap.GetTileIndex(-3 , 0) , AIRail.RAILTRACK_INVALID);
	part.sections[7] = Section(
		AIMap.GetTileIndex(-3 , 1) , AIRail.RAILTRACK_INVALID);
	part.sections[8] = Section(
		AIMap.GetTileIndex(-4 , 0) , AIRail.RAILTRACK_INVALID);
	part.sections[9] = Section(
		AIMap.GetTileIndex(-4 , 1) , AIRail.RAILTRACK_INVALID);

	part.points = array(18);
	part.points[0] = AIMap.GetTileIndex(1 , 2);
	part.points[1] = AIMap.GetTileIndex(1 , 1);
	part.points[2] = AIMap.GetTileIndex(1 , 0);
	part.points[3] = AIMap.GetTileIndex(0 , 2);
	part.points[4] = AIMap.GetTileIndex(0 , 1);
	part.points[5] = AIMap.GetTileIndex(0 , 0);
	part.points[6] = AIMap.GetTileIndex(-1 , 2);
	part.points[7] = AIMap.GetTileIndex(-1 , 1);
	part.points[8] = AIMap.GetTileIndex(-1 , 0);
	part.points[9] = AIMap.GetTileIndex(-2 , 2);
	part.points[10] = AIMap.GetTileIndex(-2 , 1);
	part.points[11] = AIMap.GetTileIndex(-2 , 0);
	part.points[12] = AIMap.GetTileIndex(-3 , 2);
	part.points[13] = AIMap.GetTileIndex(-3 , 1);
	part.points[14] = AIMap.GetTileIndex(-3 , 0);
	part.points[15] = AIMap.GetTileIndex(-4 , 2);
	part.points[16] = AIMap.GetTileIndex(-4 , 1);
	part.points[17] = AIMap.GetTileIndex(-4 , 0);

	part.signal_senses = array(10);
	part.signal_senses[0] = RailroadCommon.INVALID_SENSE;
	part.signal_senses[1] = RailroadCommon.INVALID_SENSE;
	part.signal_senses[2] = RailroadCommon.COUNTERCLOCKWISE;
	part.signal_senses[3] = RailroadCommon.INVALID_SENSE;
	part.signal_senses[4] = RailroadCommon.CLOCKWISE;
	part.signal_senses[5] = RailroadCommon.INVALID_SENSE;
	part.signal_senses[6] = RailroadCommon.INVALID_SENSE;
	part.signal_senses[7] = RailroadCommon.INVALID_SENSE;
	part.signal_senses[8] = RailroadCommon.INVALID_SENSE;
	part.signal_senses[9] = RailroadCommon.INVALID_SENSE;

	/* J_NS_RECTANGLE */
	part = parts[J_NS_RECTANGLE];
	part.entry_direction = Direction.NORTH;
	part.previous_part = NS_LINE;
	part.previous_part_offset = AIMap.GetTileIndex(1 , 3);

	part.sections = array(10);
	part.sections[0] = Section(
		AIMap.GetTileIndex(0 , 0) , AIRail.RAILTRACK_NW_SE);
	part.sections[1] = Section(
		AIMap.GetTileIndex(0 , 1) , AIRail.RAILTRACK_NW_SE);
	part.sections[2] = Section(
		AIMap.GetTileIndex(0 , 2) , AIRail.RAILTRACK_NW_SE);
	part.sections[3] = Section(
		AIMap.GetTileIndex(1 , 0) , AIRail.RAILTRACK_NW_SE);
	part.sections[4] = Section(
		AIMap.GetTileIndex(1 , 1) , AIRail.RAILTRACK_NW_SE);
	part.sections[5] = Section(
		AIMap.GetTileIndex(1 , 2) , AIRail.RAILTRACK_NW_SE);
	part.sections[6] = Section(
		AIMap.GetTileIndex(0 , 3) , AIRail.RAILTRACK_INVALID);
	part.sections[7] = Section(
		AIMap.GetTileIndex(0 , 4) , AIRail.RAILTRACK_INVALID);
	part.sections[8] = Section(
		AIMap.GetTileIndex(1 , 3) , AIRail.RAILTRACK_INVALID);
	part.sections[9] = Section(
		AIMap.GetTileIndex(1 , 4) , AIRail.RAILTRACK_INVALID);

	part.points = array(18);
	part.points[0] = AIMap.GetTileIndex(2 , 0);
	part.points[1] = AIMap.GetTileIndex(1 , 0);
	part.points[2] = AIMap.GetTileIndex(0 , 0);
	part.points[3] = AIMap.GetTileIndex(2 , 1);
	part.points[4] = AIMap.GetTileIndex(1 , 1);
	part.points[5] = AIMap.GetTileIndex(0 , 1);
	part.points[6] = AIMap.GetTileIndex(2 , 2);
	part.points[7] = AIMap.GetTileIndex(1 , 2);
	part.points[8] = AIMap.GetTileIndex(0 , 2);
	part.points[9] = AIMap.GetTileIndex(2 , 3);
	part.points[10] = AIMap.GetTileIndex(1 , 3);
	part.points[11] = AIMap.GetTileIndex(0 , 3);
	part.points[12] = AIMap.GetTileIndex(2 , 4);
	part.points[13] = AIMap.GetTileIndex(1 , 4);
	part.points[14] = AIMap.GetTileIndex(0 , 4);
	part.points[15] = AIMap.GetTileIndex(2 , 5);
	part.points[16] = AIMap.GetTileIndex(1 , 5);
	part.points[17] = AIMap.GetTileIndex(0 , 5);

	part.signal_senses = array(10);
	part.signal_senses[0] = RailroadCommon.INVALID_SENSE;
	part.signal_senses[1] = RailroadCommon.INVALID_SENSE;
	part.signal_senses[2] = RailroadCommon.CLOCKWISE;
	part.signal_senses[3] = RailroadCommon.INVALID_SENSE;
	part.signal_senses[4] = RailroadCommon.INVALID_SENSE;
	part.signal_senses[5] = RailroadCommon.COUNTERCLOCKWISE;
	part.signal_senses[6] = RailroadCommon.INVALID_SENSE;
	part.signal_senses[7] = RailroadCommon.INVALID_SENSE;
	part.signal_senses[8] = RailroadCommon.INVALID_SENSE;
	part.signal_senses[9] = RailroadCommon.INVALID_SENSE;

	/* J_SN_RECTANGLE */
	part = parts[J_SN_RECTANGLE];
	part.entry_direction = Direction.SOUTH;
	part.previous_part = SN_LINE;
	part.previous_part_offset = AIMap.GetTileIndex(0 , 0);

	part.sections = array(10);
	part.sections[0] = Section(
		AIMap.GetTileIndex(0 , 0) , AIRail.RAILTRACK_NW_SE);
	part.sections[1] = Section(
		AIMap.GetTileIndex(0 , 1) , AIRail.RAILTRACK_NW_SE);
	part.sections[2] = Section(
		AIMap.GetTileIndex(0 , 2) , AIRail.RAILTRACK_NW_SE);
	part.sections[3] = Section(
		AIMap.GetTileIndex(-1 , 0) , AIRail.RAILTRACK_NW_SE);
	part.sections[4] = Section(
		AIMap.GetTileIndex(-1 , 1) , AIRail.RAILTRACK_NW_SE);
	part.sections[5] = Section(
		AIMap.GetTileIndex(-1 , 2) , AIRail.RAILTRACK_NW_SE);
	part.sections[6] = Section(
		AIMap.GetTileIndex(-1 , -1) , AIRail.RAILTRACK_INVALID);
	part.sections[7] = Section(
		AIMap.GetTileIndex(-1 , -2) , AIRail.RAILTRACK_INVALID);
	part.sections[8] = Section(
		AIMap.GetTileIndex(0 , -1) , AIRail.RAILTRACK_INVALID);
	part.sections[9] = Section(
		AIMap.GetTileIndex(0 , -2) , AIRail.RAILTRACK_INVALID);

	part.signal_senses = array(10);
	part.signal_senses[0] = RailroadCommon.COUNTERCLOCKWISE;
	part.signal_senses[1] = RailroadCommon.INVALID_SENSE;
	part.signal_senses[2] = RailroadCommon.INVALID_SENSE;
	part.signal_senses[3] = RailroadCommon.CLOCKWISE;
	part.signal_senses[4] = RailroadCommon.INVALID_SENSE;
	part.signal_senses[5] = RailroadCommon.INVALID_SENSE;
	part.signal_senses[6] = RailroadCommon.INVALID_SENSE;
	part.signal_senses[7] = RailroadCommon.INVALID_SENSE;
	part.signal_senses[8] = RailroadCommon.INVALID_SENSE;
	part.signal_senses[9] = RailroadCommon.INVALID_SENSE;

	part.points = array(18);
	part.points[0] = AIMap.GetTileIndex(-1 , 3);
	part.points[1] = AIMap.GetTileIndex(0 , 3);
	part.points[2] = AIMap.GetTileIndex(1 , 3);
	part.points[3] = AIMap.GetTileIndex(-1 , 2);
	part.points[4] = AIMap.GetTileIndex(0 , 2);
	part.points[5] = AIMap.GetTileIndex(1 , 2);
	part.points[6] = AIMap.GetTileIndex(-1 , 1);
	part.points[7] = AIMap.GetTileIndex(0 , 1);
	part.points[8] = AIMap.GetTileIndex(1 , 1);
	part.points[9] = AIMap.GetTileIndex(-1 , 0);
	part.points[10] = AIMap.GetTileIndex(0 , 0);
	part.points[11] = AIMap.GetTileIndex(1 , 0);
	part.points[12] = AIMap.GetTileIndex(-1 , -1);
	part.points[13] = AIMap.GetTileIndex(0 , -1);
	part.points[14] = AIMap.GetTileIndex(1 , -1);
	part.points[15] = AIMap.GetTileIndex(-1 , -2);
	part.points[16] = AIMap.GetTileIndex(0 , -2);
	part.points[17] = AIMap.GetTileIndex(1 , -2);

	/* J_SW_HOOK.*/
	part = parts[J_SW_HOOK];
	part.entry_direction = Direction.SOUTH;
	part.previous_part = SN_LINE;
	part.previous_part_offset = AIMap.GetTileIndex(1 , -2);

	part.sections = array(10);
	part.sections[0] = Section(
		AIMap.GetTileIndex(0 , 0) , AIRail.RAILTRACK_NW_NE);
	part.sections[1] = Section(
		AIMap.GetTileIndex(0 , -1) , AIRail.RAILTRACK_NW_NE);
	part.sections[2] = Section(
		AIMap.GetTileIndex(0 , -1) , AIRail.RAILTRACK_SW_SE);
	part.sections[3] = Section(
		AIMap.GetTileIndex(0 , -2) , AIRail.RAILTRACK_NW_SE);
	part.sections[4] = Section(
		AIMap.GetTileIndex(0 , -3) , AIRail.RAILTRACK_INVALID);
	part.sections[5] = Section(
		AIMap.GetTileIndex(0 , -4) , AIRail.RAILTRACK_INVALID);
	part.sections[6] = Section(
		AIMap.GetTileIndex(1 , -1) , AIRail.RAILTRACK_NW_NE);
	part.sections[7] = Section(
		AIMap.GetTileIndex(1 , -2) , AIRail.RAILTRACK_NW_SE);
	part.sections[8] = Section(
		AIMap.GetTileIndex(1 , -3) , AIRail.RAILTRACK_INVALID);
	part.sections[9] = Section(
		AIMap.GetTileIndex(1 , -4) , AIRail.RAILTRACK_INVALID);

	part.signal_senses = array(10);
	part.signal_senses[0] = RailroadCommon.INVALID_SENSE;
	part.signal_senses[1] = RailroadCommon.INVALID_SENSE;
	part.signal_senses[2] = RailroadCommon.INVALID_SENSE;
	part.signal_senses[3] = RailroadCommon.CLOCKWISE;
	part.signal_senses[4] = RailroadCommon.INVALID_SENSE;
	part.signal_senses[5] = RailroadCommon.INVALID_SENSE;
	part.signal_senses[6] = RailroadCommon.INVALID_SENSE;
	part.signal_senses[7] = RailroadCommon.COUNTERCLOCKWISE;
	part.signal_senses[8] = RailroadCommon.INVALID_SENSE;
	part.signal_senses[9] = RailroadCommon.INVALID_SENSE;

	part.points = array(15);
	part.points[0] = AIMap.GetTileIndex(0 , -1);
	part.points[1] = AIMap.GetTileIndex(0 , 0);
	part.points[2] = AIMap.GetTileIndex(0 , 1);
	part.points[3] = AIMap.GetTileIndex(1 , 0);
	part.points[4] = AIMap.GetTileIndex(1 , -1);
	part.points[5] = AIMap.GetTileIndex(2 , -1);
	part.points[6] = AIMap.GetTileIndex(0 , -2);
	part.points[7] = AIMap.GetTileIndex(1 , -2);
	part.points[8] = AIMap.GetTileIndex(2 , -2);
	part.points[9] = AIMap.GetTileIndex(0 , -3);
	part.points[10] = AIMap.GetTileIndex(1 , -3);
	part.points[11] = AIMap.GetTileIndex(2 , -3);
	part.points[12] = AIMap.GetTileIndex(0 , -4);
	part.points[13] = AIMap.GetTileIndex(1 , -4);
	part.points[14] = AIMap.GetTileIndex(2 , -4);

	/* J_NW_HOOK.*/
	part = parts[J_NW_HOOK];
	part.entry_direction = Direction.NORTH;
	part.previous_part = NS_LINE;
	part.previous_part_offset = AIMap.GetTileIndex(1 , 3);

	part.sections = array(10);
	part.sections[0] = Section(
		AIMap.GetTileIndex(0 , 0) , AIRail.RAILTRACK_NE_SE);
	part.sections[1] = Section(
		AIMap.GetTileIndex(0 , 1) , AIRail.RAILTRACK_NW_SW);
	part.sections[2] = Section(
		AIMap.GetTileIndex(0 , 1) , AIRail.RAILTRACK_NE_SE);
	part.sections[3] = Section(
		AIMap.GetTileIndex(0 , 2) , AIRail.RAILTRACK_NW_SE);
	part.sections[4] = Section(
		AIMap.GetTileIndex(0 , 3) , AIRail.RAILTRACK_INVALID);
	part.sections[5] = Section(
		AIMap.GetTileIndex(0 , 4) , AIRail.RAILTRACK_INVALID);
	part.sections[6] = Section(
		AIMap.GetTileIndex(1 , 1) , AIRail.RAILTRACK_NE_SE);
	part.sections[7] = Section(
		AIMap.GetTileIndex(1 , 2) , AIRail.RAILTRACK_NW_SE);
	part.sections[8] = Section(
		AIMap.GetTileIndex(1 , 3) , AIRail.RAILTRACK_INVALID);
	part.sections[9] = Section(
		AIMap.GetTileIndex(1 , 4) , AIRail.RAILTRACK_INVALID);

	part.signal_senses = array(10);
	part.signal_senses[0] = RailroadCommon.INVALID_SENSE;
	part.signal_senses[1] = RailroadCommon.INVALID_SENSE;
	part.signal_senses[2] = RailroadCommon.INVALID_SENSE;
	part.signal_senses[3] = RailroadCommon.CLOCKWISE;
	part.signal_senses[4] = RailroadCommon.INVALID_SENSE;
	part.signal_senses[5] = RailroadCommon.INVALID_SENSE;
	part.signal_senses[6] = RailroadCommon.INVALID_SENSE;
	part.signal_senses[7] = RailroadCommon.COUNTERCLOCKWISE;
	part.signal_senses[8] = RailroadCommon.INVALID_SENSE;
	part.signal_senses[9] = RailroadCommon.INVALID_SENSE;

	part.points = array(15);
	part.points[0] = AIMap.GetTileIndex(0 , 2);
	part.points[1] = AIMap.GetTileIndex(0 , 1);
	part.points[2] = AIMap.GetTileIndex(0 , 0);
	part.points[3] = AIMap.GetTileIndex(1 , 1);
	part.points[4] = AIMap.GetTileIndex(1 , 2);
	part.points[5] = AIMap.GetTileIndex(2 , 2);
	part.points[6] = AIMap.GetTileIndex(0 , 3);
	part.points[7] = AIMap.GetTileIndex(1 , 3);
	part.points[8] = AIMap.GetTileIndex(2 , 3);
	part.points[9] = AIMap.GetTileIndex(0 , 4);
	part.points[10] = AIMap.GetTileIndex(1 , 4);
	part.points[11] = AIMap.GetTileIndex(2 , 4);
	part.points[12] = AIMap.GetTileIndex(0 , 5);
	part.points[13] = AIMap.GetTileIndex(1 , 5);
	part.points[14] = AIMap.GetTileIndex(2 , 5);

	/* J_SE_HOOK.*/
	part = parts[J_SE_HOOK];
	part.entry_direction = Direction.SOUTH;
	part.previous_part = SN_LINE;
	part.previous_part_offset = AIMap.GetTileIndex(0 , -2);

	part.sections = array(10);
	part.sections[0] = Section(
		AIMap.GetTileIndex(0 , 0) , AIRail.RAILTRACK_NW_SW);
	part.sections[1] = Section(
		AIMap.GetTileIndex(0 , -1) , AIRail.RAILTRACK_NW_SW);
	part.sections[2] = Section(
		AIMap.GetTileIndex(0 , -1) , AIRail.RAILTRACK_NE_SE);
	part.sections[3] = Section(
		AIMap.GetTileIndex(0 , -2) , AIRail.RAILTRACK_NW_SE);
	part.sections[4] = Section(
		AIMap.GetTileIndex(0 , -3) , AIRail.RAILTRACK_INVALID);
	part.sections[5] = Section(
		AIMap.GetTileIndex(0 , -4) , AIRail.RAILTRACK_INVALID);
	part.sections[6] = Section(
		AIMap.GetTileIndex(-1 , -1) , AIRail.RAILTRACK_NW_SW);
	part.sections[7] = Section(
		AIMap.GetTileIndex(-1 , -2) , AIRail.RAILTRACK_NW_SE);
	part.sections[8] = Section(
		AIMap.GetTileIndex(-1 , -3) , AIRail.RAILTRACK_INVALID);
	part.sections[9] = Section(
		AIMap.GetTileIndex(-1 , -4) , AIRail.RAILTRACK_INVALID);

	part.signal_senses = array(10);
	part.signal_senses[0] = RailroadCommon.INVALID_SENSE;
	part.signal_senses[1] = RailroadCommon.INVALID_SENSE;
	part.signal_senses[2] = RailroadCommon.INVALID_SENSE;
	part.signal_senses[3] = RailroadCommon.COUNTERCLOCKWISE;
	part.signal_senses[4] = RailroadCommon.INVALID_SENSE;
	part.signal_senses[5] = RailroadCommon.INVALID_SENSE;
	part.signal_senses[6] = RailroadCommon.INVALID_SENSE;
	part.signal_senses[7] = RailroadCommon.CLOCKWISE;
	part.signal_senses[8] = RailroadCommon.INVALID_SENSE;
	part.signal_senses[9] = RailroadCommon.INVALID_SENSE;

	part.points = array(15);
	part.points[0] = AIMap.GetTileIndex(1 , -1);
	part.points[1] = AIMap.GetTileIndex(1 , 0);
	part.points[2] = AIMap.GetTileIndex(1 , 1);
	part.points[3] = AIMap.GetTileIndex(0 , 0);
	part.points[4] = AIMap.GetTileIndex(0 , -1);
	part.points[5] = AIMap.GetTileIndex(-1 , -1);
	part.points[6] = AIMap.GetTileIndex(1 , -2);
	part.points[7] = AIMap.GetTileIndex(0 , -2);
	part.points[8] = AIMap.GetTileIndex(-1 , -2);
	part.points[9] = AIMap.GetTileIndex(1 , -3);
	part.points[10] = AIMap.GetTileIndex(0 , -3);
	part.points[11] = AIMap.GetTileIndex(-1 , -3);
	part.points[12] = AIMap.GetTileIndex(1 , -4);
	part.points[13] = AIMap.GetTileIndex(0 , -4);
	part.points[14] = AIMap.GetTileIndex(-1 , -4);

	/* J_NE_HOOK.*/
	part = parts[J_NE_HOOK];
	part.entry_direction = Direction.NORTH;
	part.previous_part = NS_LINE;
	part.previous_part_offset = AIMap.GetTileIndex(0 , 3);

	part.sections = array(10);
	part.sections[0] = Section(
		AIMap.GetTileIndex(0 , 0) , AIRail.RAILTRACK_SW_SE);
	part.sections[1] = Section(
		AIMap.GetTileIndex(0 , 1) , AIRail.RAILTRACK_NW_NE);
	part.sections[2] = Section(
		AIMap.GetTileIndex(0 , 1) , AIRail.RAILTRACK_SW_SE);
	part.sections[3] = Section(
		AIMap.GetTileIndex(0 , 2) , AIRail.RAILTRACK_NW_SE);
	part.sections[4] = Section(
		AIMap.GetTileIndex(0 , 3) , AIRail.RAILTRACK_INVALID);
	part.sections[5] = Section(
		AIMap.GetTileIndex(0 , 4) , AIRail.RAILTRACK_INVALID);
	part.sections[6] = Section(
		AIMap.GetTileIndex(-1 , 1) , AIRail.RAILTRACK_SW_SE);
	part.sections[7] = Section(
		AIMap.GetTileIndex(-1 , 2) , AIRail.RAILTRACK_NW_SE);
	part.sections[8] = Section(
		AIMap.GetTileIndex(-1 , 3) , AIRail.RAILTRACK_INVALID);
	part.sections[9] = Section(
		AIMap.GetTileIndex(-1 , 4) , AIRail.RAILTRACK_INVALID);

	part.signal_senses = array(10);
	part.signal_senses[0] = RailroadCommon.INVALID_SENSE;
	part.signal_senses[1] = RailroadCommon.INVALID_SENSE;
	part.signal_senses[2] = RailroadCommon.INVALID_SENSE;
	part.signal_senses[3] = RailroadCommon.COUNTERCLOCKWISE;
	part.signal_senses[4] = RailroadCommon.INVALID_SENSE;
	part.signal_senses[5] = RailroadCommon.INVALID_SENSE;
	part.signal_senses[6] = RailroadCommon.INVALID_SENSE;
	part.signal_senses[7] = RailroadCommon.CLOCKWISE;
	part.signal_senses[8] = RailroadCommon.INVALID_SENSE;
	part.signal_senses[9] = RailroadCommon.INVALID_SENSE;

	part.points = array(15);
	part.points[0] = AIMap.GetTileIndex(1 , 2);
	part.points[1] = AIMap.GetTileIndex(1 , 1);
	part.points[2] = AIMap.GetTileIndex(1 , 0);
	part.points[3] = AIMap.GetTileIndex(0 , 1);
	part.points[4] = AIMap.GetTileIndex(0 , 2);
	part.points[5] = AIMap.GetTileIndex(-1 , 2);
	part.points[6] = AIMap.GetTileIndex(1 , 3);
	part.points[7] = AIMap.GetTileIndex(0 , 3);
	part.points[8] = AIMap.GetTileIndex(-1 , 3);
	part.points[9] = AIMap.GetTileIndex(1 , 4);
	part.points[10] = AIMap.GetTileIndex(0 , 4);
	part.points[11] = AIMap.GetTileIndex(-1 , 4);
	part.points[12] = AIMap.GetTileIndex(1 , 5);
	part.points[13] = AIMap.GetTileIndex(0 , 5);
	part.points[14] = AIMap.GetTileIndex(-1 , 5);

	/* J_WS_HOOK.*/
	part = parts[J_WS_HOOK];
	part.entry_direction = Direction.WEST;
	part.previous_part = WE_LINE;
	part.previous_part_offset = AIMap.GetTileIndex(-2 , 1);

	part.sections = array(10);
	part.sections[0] = Section(
		AIMap.GetTileIndex(0 , 0) , AIRail.RAILTRACK_NW_NE);
	part.sections[1] = Section(
		AIMap.GetTileIndex(-1 , 0) , AIRail.RAILTRACK_NW_NE);
	part.sections[2] = Section(
		AIMap.GetTileIndex(-1 , 0) , AIRail.RAILTRACK_SW_SE);
	part.sections[3] = Section(
		AIMap.GetTileIndex(-2 , 0) , AIRail.RAILTRACK_NE_SW);
	part.sections[4] = Section(
		AIMap.GetTileIndex(-3 , 0) , AIRail.RAILTRACK_INVALID);
	part.sections[5] = Section(
		AIMap.GetTileIndex(-4 , 0) , AIRail.RAILTRACK_INVALID);
	part.sections[6] = Section(
		AIMap.GetTileIndex(-1 , 1) , AIRail.RAILTRACK_NW_NE);
	part.sections[7] = Section(
		AIMap.GetTileIndex(-2 , 1) , AIRail.RAILTRACK_NE_SW);
	part.sections[8] = Section(
		AIMap.GetTileIndex(-3 , 1) , AIRail.RAILTRACK_INVALID);
	part.sections[9] = Section(
		AIMap.GetTileIndex(-4 , 1) , AIRail.RAILTRACK_INVALID);

	part.signal_senses = array(10);
	part.signal_senses[0] = RailroadCommon.INVALID_SENSE;
	part.signal_senses[1] = RailroadCommon.INVALID_SENSE;
	part.signal_senses[2] = RailroadCommon.INVALID_SENSE;
	part.signal_senses[3] = RailroadCommon.CLOCKWISE;
	part.signal_senses[4] = RailroadCommon.INVALID_SENSE;
	part.signal_senses[5] = RailroadCommon.INVALID_SENSE;
	part.signal_senses[6] = RailroadCommon.INVALID_SENSE;
	part.signal_senses[7] = RailroadCommon.COUNTERCLOCKWISE;
	part.signal_senses[8] = RailroadCommon.INVALID_SENSE;
	part.signal_senses[9] = RailroadCommon.INVALID_SENSE;

	part.points = array(15);
	part.points[0] = AIMap.GetTileIndex(-1 , 0);
	part.points[1] = AIMap.GetTileIndex(0 , 0);
	part.points[2] = AIMap.GetTileIndex(1 , 0);
	part.points[3] = AIMap.GetTileIndex(0 , 1);
	part.points[4] = AIMap.GetTileIndex(-1 , 1);
	part.points[5] = AIMap.GetTileIndex(-1 , 2);
	part.points[6] = AIMap.GetTileIndex(-2 , 0);
	part.points[7] = AIMap.GetTileIndex(-2 , 1);
	part.points[8] = AIMap.GetTileIndex(-2 , 2);
	part.points[9] = AIMap.GetTileIndex(-3 , 0);
	part.points[10] = AIMap.GetTileIndex(-3 , 1);
	part.points[11] = AIMap.GetTileIndex(-3 , 2);
	part.points[12] = AIMap.GetTileIndex(-4 , 0);
	part.points[13] = AIMap.GetTileIndex(-4 , 1);
	part.points[14] = AIMap.GetTileIndex(-4 , 2);

	/* J_ES_HOOK.*/
	part = parts[J_ES_HOOK];
	part.entry_direction = Direction.EAST;
	part.previous_part = EW_LINE;
	part.previous_part_offset = AIMap.GetTileIndex(3 , 1);

	part.sections = array(10);
	part.sections[0] = Section(
		AIMap.GetTileIndex(0 , 0) , AIRail.RAILTRACK_NW_SW);
	part.sections[1] = Section(
		AIMap.GetTileIndex(1 , 0) , AIRail.RAILTRACK_NW_SW);
	part.sections[2] = Section(
		AIMap.GetTileIndex(1 , 0) , AIRail.RAILTRACK_NE_SE);
	part.sections[3] = Section(
		AIMap.GetTileIndex(2 , 0) , AIRail.RAILTRACK_NE_SW);
	part.sections[4] = Section(
		AIMap.GetTileIndex(3 , 0) , AIRail.RAILTRACK_INVALID);
	part.sections[5] = Section(
		AIMap.GetTileIndex(4 , 0) , AIRail.RAILTRACK_INVALID);
	part.sections[6] = Section(
		AIMap.GetTileIndex(1 , 1) , AIRail.RAILTRACK_NW_SW);
	part.sections[7] = Section(
		AIMap.GetTileIndex(2 , 1) , AIRail.RAILTRACK_NE_SW);
	part.sections[8] = Section(
		AIMap.GetTileIndex(3 , 1) , AIRail.RAILTRACK_INVALID);
	part.sections[9] = Section(
		AIMap.GetTileIndex(4 , 1) , AIRail.RAILTRACK_INVALID);

	part.signal_senses = array(10);
	part.signal_senses[0] = RailroadCommon.INVALID_SENSE;
	part.signal_senses[1] = RailroadCommon.INVALID_SENSE;
	part.signal_senses[2] = RailroadCommon.INVALID_SENSE;
	part.signal_senses[3] = RailroadCommon.CLOCKWISE;
	part.signal_senses[4] = RailroadCommon.INVALID_SENSE;
	part.signal_senses[5] = RailroadCommon.INVALID_SENSE;
	part.signal_senses[6] = RailroadCommon.INVALID_SENSE;
	part.signal_senses[7] = RailroadCommon.COUNTERCLOCKWISE;
	part.signal_senses[8] = RailroadCommon.INVALID_SENSE;
	part.signal_senses[9] = RailroadCommon.INVALID_SENSE;

	part.points = array(15);
	part.points[0] = AIMap.GetTileIndex(2 , 0);
	part.points[1] = AIMap.GetTileIndex(1 , 0);
	part.points[2] = AIMap.GetTileIndex(0 , 0);
	part.points[3] = AIMap.GetTileIndex(1 , 1);
	part.points[4] = AIMap.GetTileIndex(2 , 1);
	part.points[5] = AIMap.GetTileIndex(2 , 2);
	part.points[6] = AIMap.GetTileIndex(3 , 0);
	part.points[7] = AIMap.GetTileIndex(3 , 1);
	part.points[8] = AIMap.GetTileIndex(3 , 2);
	part.points[9] = AIMap.GetTileIndex(4 , 0);
	part.points[10] = AIMap.GetTileIndex(4 , 1);
	part.points[11] = AIMap.GetTileIndex(4 , 2);
	part.points[12] = AIMap.GetTileIndex(5 , 0);
	part.points[13] = AIMap.GetTileIndex(5 , 1);
	part.points[14] = AIMap.GetTileIndex(5 , 2);

	/* J_EN_HOOK.*/
	part = parts[J_EN_HOOK];
	part.entry_direction = Direction.EAST;
	part.previous_part = EW_LINE;
	part.previous_part_offset = AIMap.GetTileIndex(3 , 0);

	part.sections = array(10);
	part.sections[0] = Section(
		AIMap.GetTileIndex(0 , 0) , AIRail.RAILTRACK_SW_SE);
	part.sections[1] = Section(
		AIMap.GetTileIndex(1 , 0) , AIRail.RAILTRACK_NW_NE);
	part.sections[2] = Section(
		AIMap.GetTileIndex(1 , 0) , AIRail.RAILTRACK_SW_SE);
	part.sections[3] = Section(
		AIMap.GetTileIndex(2 , 0) , AIRail.RAILTRACK_NE_SW);
	part.sections[4] = Section(
		AIMap.GetTileIndex(3 , 0) , AIRail.RAILTRACK_INVALID);
	part.sections[5] = Section(
		AIMap.GetTileIndex(4 , 0) , AIRail.RAILTRACK_INVALID);
	part.sections[6] = Section(
		AIMap.GetTileIndex(1 , -1) , AIRail.RAILTRACK_SW_SE);
	part.sections[7] = Section(
		AIMap.GetTileIndex(2 , -1) , AIRail.RAILTRACK_NE_SW);
	part.sections[8] = Section(
		AIMap.GetTileIndex(3 , -1) , AIRail.RAILTRACK_INVALID);
	part.sections[9] = Section(
		AIMap.GetTileIndex(4 , -1) , AIRail.RAILTRACK_INVALID);

	part.signal_senses = array(10);
	part.signal_senses[0] = RailroadCommon.INVALID_SENSE;
	part.signal_senses[1] = RailroadCommon.INVALID_SENSE;
	part.signal_senses[2] = RailroadCommon.INVALID_SENSE;
	part.signal_senses[3] = RailroadCommon.COUNTERCLOCKWISE;
	part.signal_senses[4] = RailroadCommon.INVALID_SENSE;
	part.signal_senses[5] = RailroadCommon.INVALID_SENSE;
	part.signal_senses[6] = RailroadCommon.INVALID_SENSE;
	part.signal_senses[7] = RailroadCommon.CLOCKWISE;
	part.signal_senses[8] = RailroadCommon.INVALID_SENSE;
	part.signal_senses[9] = RailroadCommon.INVALID_SENSE;

	part.points = array(15);
	part.points[0] = AIMap.GetTileIndex(0 , 1);
	part.points[1] = AIMap.GetTileIndex(1 , 1);
	part.points[2] = AIMap.GetTileIndex(2 , 1);
	part.points[3] = AIMap.GetTileIndex(1 , 0);
	part.points[4] = AIMap.GetTileIndex(2 , 0);
	part.points[5] = AIMap.GetTileIndex(2 , -1);
	part.points[6] = AIMap.GetTileIndex(3 , -1);
	part.points[7] = AIMap.GetTileIndex(3 , 0);
	part.points[8] = AIMap.GetTileIndex(3 , 1);
	part.points[9] = AIMap.GetTileIndex(4 , -1);
	part.points[10] = AIMap.GetTileIndex(4 , 0);
	part.points[11] = AIMap.GetTileIndex(4 , 1);
	part.points[12] = AIMap.GetTileIndex(5 , -1);
	part.points[13] = AIMap.GetTileIndex(5 , 0);
	part.points[14] = AIMap.GetTileIndex(5 , 1);

	/* J_WN_HOOK.*/
	part = parts[J_WN_HOOK];
	part.entry_direction = Direction.WEST;
	part.previous_part = WE_LINE;
	part.previous_part_offset = AIMap.GetTileIndex(-2 , 0);

	part.sections = array(10);
	part.sections[0] = Section(
		AIMap.GetTileIndex(0 , 0) , AIRail.RAILTRACK_NE_SE);
	part.sections[1] = Section(
		AIMap.GetTileIndex(-1 , 0) , AIRail.RAILTRACK_NW_SW);
	part.sections[2] = Section(
		AIMap.GetTileIndex(-2 , 0) , AIRail.RAILTRACK_NE_SW);
	part.sections[3] = Section(
		AIMap.GetTileIndex(-3 , 0) , AIRail.RAILTRACK_INVALID);
	part.sections[4] = Section(
		AIMap.GetTileIndex(-4 , 0) , AIRail.RAILTRACK_INVALID);
	part.sections[5] = Section(
		AIMap.GetTileIndex(-1 , 0) , AIRail.RAILTRACK_NE_SE);
	part.sections[6] = Section(
		AIMap.GetTileIndex(-1 , -1) , AIRail.RAILTRACK_NE_SE);
	part.sections[7] = Section(
		AIMap.GetTileIndex(-2 , -1) , AIRail.RAILTRACK_NE_SW);
	part.sections[8] = Section(
		AIMap.GetTileIndex(-3 , -1) , AIRail.RAILTRACK_INVALID);
	part.sections[9] = Section(
		AIMap.GetTileIndex(-4 , -1) , AIRail.RAILTRACK_INVALID);

	part.signal_senses = array(10);
	part.signal_senses[0] = RailroadCommon.INVALID_SENSE;
	part.signal_senses[1] = RailroadCommon.INVALID_SENSE;
	part.signal_senses[2] = RailroadCommon.COUNTERCLOCKWISE;
	part.signal_senses[3] = RailroadCommon.INVALID_SENSE;
	part.signal_senses[4] = RailroadCommon.INVALID_SENSE;
	part.signal_senses[5] = RailroadCommon.INVALID_SENSE;
	part.signal_senses[6] = RailroadCommon.INVALID_SENSE;
	part.signal_senses[7] = RailroadCommon.CLOCKWISE;
	part.signal_senses[8] = RailroadCommon.INVALID_SENSE;
	part.signal_senses[9] = RailroadCommon.INVALID_SENSE;

	part.points = array(15);
	part.points[0] = AIMap.GetTileIndex(-1 , 1);
	part.points[1] = AIMap.GetTileIndex(0 , 1);
	part.points[2] = AIMap.GetTileIndex(1 , 1);
	part.points[3] = AIMap.GetTileIndex(0 , 0);
	part.points[4] = AIMap.GetTileIndex(-1 , 0);
	part.points[5] = AIMap.GetTileIndex(-1 , -1);
	part.points[6] = AIMap.GetTileIndex(-2 , -1);
	part.points[7] = AIMap.GetTileIndex(-2 , 0);
	part.points[8] = AIMap.GetTileIndex(-2 , 1);
	part.points[9] = AIMap.GetTileIndex(-3 , -1);
	part.points[10] = AIMap.GetTileIndex(-3 , 0);
	part.points[11] = AIMap.GetTileIndex(-3 , 1);
	part.points[12] = AIMap.GetTileIndex(-4 , -1);
	part.points[13] = AIMap.GetTileIndex(-4 , 0);
	part.points[14] = AIMap.GetTileIndex(-4 , 1);

	/* Bends: */

	/* NE_BEND */
	part = parts[NE_BEND];
	part.next_tile = AIMap.GetTileIndex(1 , -1);
	part.sections = array(4);
	part.sections[0] = Section(
		AIMap.GetTileIndex(0 , -1) , AIRail.RAILTRACK_SW_SE);
	part.sections[1] = Section(
		AIMap.GetTileIndex(0 , -1) , AIRail.RAILTRACK_NW_NE);
	part.sections[2] = Section(
		AIMap.GetTileIndex(0 , -2) , AIRail.RAILTRACK_SW_SE);
	part.sections[3] = Section(
		AIMap.GetTileIndex(-1 , -1) , AIRail.RAILTRACK_SW_SE);

	part.continuation_parts = array(3);
	part.continuation_parts[0] = WE_S_DIAGONAL;
	part.continuation_parts[1] = WS_BEND;
	part.continuation_parts[2] = WE_LINE;

	part.previous_parts = array(3);
	part.previous_parts[0] = NS_S_DIAGONAL;
	part.previous_parts[1] = WS_BEND;
	part.previous_parts[2] = NS_LINE;

	part.points = array(6);
	part.points[0] = AIMap.GetTileIndex(1 , 0);
	part.points[1] = AIMap.GetTileIndex(1 , -1);
	part.points[2] = AIMap.GetTileIndex(1 , -2);
	part.points[3] = AIMap.GetTileIndex(0 , -1);
	part.points[4] = AIMap.GetTileIndex(0 , 0);
	part.points[5] = AIMap.GetTileIndex(-1 , 0);

	part.signal_senses = array(4);
	part.signal_senses[0] = RailroadCommon.COUNTERCLOCKWISE;
	part.signal_senses[1] = RailroadCommon.INVALID_SENSE;
	part.signal_senses[2] = RailroadCommon.CLOCKWISE;
	part.signal_senses[3] = RailroadCommon.CLOCKWISE;

	part.junctions = array(1);
	part.junctions[0] = Junction(AIMap.GetTileIndex(0 , -2) , J_WE_RECTANGLE);

	part.depots = array(2);
	part.depots[1] = Depot(AIMap.GetTileIndex(-1 , -1) , EN_BOOMERANG);

	part.parts_keep_direction = array(22);
	for(local i = 0 ; i < 22 ; i++)
		part.parts_keep_direction[i] = false;
	part.parts_keep_direction[WE_S_DIAGONAL] = true;
	part.parts_keep_direction[WS_BEND] = true;

	/* EN_BEND */
	part = parts[EN_BEND];
	part.next_tile = AIMap.GetTileIndex(-1 , 1);
	part.sections = array(4);
	part.sections[0] = Section(
		AIMap.GetTileIndex(-1 , 0) , AIRail.RAILTRACK_SW_SE);
	part.sections[1] = Section(
		AIMap.GetTileIndex(-1 , 0) , AIRail.RAILTRACK_NW_NE);
	part.sections[2] = Section(
		AIMap.GetTileIndex(-1 , -1) , AIRail.RAILTRACK_SW_SE);
	part.sections[3] = Section(
		AIMap.GetTileIndex(-2 , 0) , AIRail.RAILTRACK_SW_SE);

	part.continuation_parts = array(3);
	part.continuation_parts[0] = SN_S_DIAGONAL;
	part.continuation_parts[1] = SW_BEND;
	part.continuation_parts[2] = SN_LINE;

	part.previous_parts = array(3);
	part.previous_parts[0] = EW_S_DIAGONAL;
	part.previous_parts[1] = SW_BEND;
	part.previous_parts[2] = EW_LINE;

	part.points = array(6);
	part.points[0] = AIMap.GetTileIndex(0 , 1);
	part.points[1] = AIMap.GetTileIndex(-1 , 1);
	part.points[2] = AIMap.GetTileIndex(-2 , 1);
	part.points[3] = AIMap.GetTileIndex(-1 , 0);
	part.points[4] = AIMap.GetTileIndex(0 , 0);
	part.points[5] = AIMap.GetTileIndex(0 , -1);

	part.signal_senses = array(4);
	part.signal_senses[0] = RailroadCommon.COUNTERCLOCKWISE;
	part.signal_senses[1] = RailroadCommon.INVALID_SENSE;
	part.signal_senses[2] = RailroadCommon.CLOCKWISE;
	part.signal_senses[3] = RailroadCommon.CLOCKWISE;

	part.junctions = array(1);
	part.junctions[0] = Junction(AIMap.GetTileIndex(-1 , -2) , J_SN_RECTANGLE);

	part.depots = array(2);
	part.depots[0] = Depot(AIMap.GetTileIndex(-2 , 0) , EN_BOOMERANG);

	part.parts_keep_direction = array(22);
	for(local i = 0 ; i < 22 ; i++)
		part.parts_keep_direction[i] = false;
	part.parts_keep_direction[SN_S_DIAGONAL] = true;
	part.parts_keep_direction[SW_BEND] = true;

	/* WN_BEND */
	part = parts[WN_BEND];
	part.next_tile = AIMap.GetTileIndex(1 , 1);
	part.sections = array(4);
	part.sections[0] = Section(
		AIMap.GetTileIndex(0 , 0) , AIRail.RAILTRACK_NW_SW);
	part.sections[1] = Section(
		AIMap.GetTileIndex(0 , 0) , AIRail.RAILTRACK_NE_SE);
	part.sections[2] = Section(
		AIMap.GetTileIndex(1 , 0) , AIRail.RAILTRACK_NE_SE);
	part.sections[3] = Section(
		AIMap.GetTileIndex(0 , -1) , AIRail.RAILTRACK_NE_SE);

	part.continuation_parts = array(3);
	part.continuation_parts[0] = SN_P_DIAGONAL;
	part.continuation_parts[1] = SE_BEND;
	part.continuation_parts[2] = SN_LINE;

	part.previous_parts = array(3);
	part.previous_parts[0] = WE_P_DIAGONAL;
	part.previous_parts[1] = SE_BEND;
	part.previous_parts[2] = WE_LINE;

	part.points = array(6);
	part.points[0] = AIMap.GetTileIndex(0 , 1);
	part.points[1] = AIMap.GetTileIndex(1 , 1);
	part.points[2] = AIMap.GetTileIndex(2 , 1);
	part.points[3] = AIMap.GetTileIndex(1 , 0);
	part.points[4] = AIMap.GetTileIndex(0 , 0);
	part.points[5] = AIMap.GetTileIndex(0 , -1);

	part.signal_senses = array(4);
	part.signal_senses[0] = RailroadCommon.INVALID_SENSE;
	part.signal_senses[1] = RailroadCommon.COUNTERCLOCKWISE;
	part.signal_senses[2] = RailroadCommon.CLOCKWISE;
	part.signal_senses[3] = RailroadCommon.CLOCKWISE;

	part.junctions = array(1);
	part.junctions[0] = Junction(AIMap.GetTileIndex(1 , -2) , J_SN_RECTANGLE);

	part.depots = array(2);
	part.depots[1] = Depot(AIMap.GetTileIndex(1 , 0) , WN_BOOMERANG);

	part.parts_keep_direction = array(22);
	for(local i = 0 ; i < 22 ; i++)
		part.parts_keep_direction[i] = false;
	part.parts_keep_direction[SN_P_DIAGONAL] = true;
	part.parts_keep_direction[SE_BEND] = true;

	/* NW_BEND */
	part = parts[NW_BEND];
	part.next_tile = AIMap.GetTileIndex(-1 , -1);
	part.sections = array(4);
	part.sections[0] = Section(
		AIMap.GetTileIndex(-1 , -1) , AIRail.RAILTRACK_NE_SE);
	part.sections[1] = Section(
		AIMap.GetTileIndex(-1 , -1) , AIRail.RAILTRACK_NW_SW);
	part.sections[2] = Section(
		AIMap.GetTileIndex(0 , -1) , AIRail.RAILTRACK_NE_SE);
	part.sections[3] = Section(
		AIMap.GetTileIndex(-1 , -2) , AIRail.RAILTRACK_NE_SE);

	part.continuation_parts = array(3);
	part.continuation_parts[0] = EW_P_DIAGONAL;
	part.continuation_parts[1] = ES_BEND;
	part.continuation_parts[2] = EW_LINE;

	part.previous_parts = array(3);
	part.previous_parts[0] = NS_P_DIAGONAL;
	part.previous_parts[1] = ES_BEND;
	part.previous_parts[2] = NS_LINE;

	part.points = array(6);
	part.points[0] = AIMap.GetTileIndex(-1 , 0);
	part.points[1] = AIMap.GetTileIndex(-1 , -1);
	part.points[2] = AIMap.GetTileIndex(-1 , -2);
	part.points[3] = AIMap.GetTileIndex(0 , -1);
	part.points[4] = AIMap.GetTileIndex(0 , 0);
	part.points[5] = AIMap.GetTileIndex(1 , 0);

	part.signal_senses = array(4);
	part.signal_senses[0] = RailroadCommon.COUNTERCLOCKWISE;
	part.signal_senses[1] = RailroadCommon.INVALID_SENSE;
	part.signal_senses[2] = RailroadCommon.CLOCKWISE;
	part.signal_senses[3] = RailroadCommon.CLOCKWISE;

	part.junctions = array(1);
	part.junctions[0] = Junction(AIMap.GetTileIndex(1 , -1) , J_EW_RECTANGLE);

	part.depots = array(2);
	part.depots[0] = Depot(AIMap.GetTileIndex(0 , -1) , WN_BOOMERANG);

	part.parts_keep_direction = array(22);
	for(local i = 0 ; i < 22 ; i++)
		part.parts_keep_direction[i] = false;
	part.parts_keep_direction[EW_P_DIAGONAL] = true;
	part.parts_keep_direction[ES_BEND] = true;

	/* SW_BEND */
	part = parts[SW_BEND];
	part.next_tile = AIMap.GetTileIndex(-1 , 1);
	part.sections = array(4);
	part.sections[0] = Section(
		AIMap.GetTileIndex(-1 , 0) , AIRail.RAILTRACK_NW_NE);
	part.sections[1] = Section(
		AIMap.GetTileIndex(-1 , 0) , AIRail.RAILTRACK_SW_SE);
	part.sections[2] = Section(
		AIMap.GetTileIndex(0 , 0) , AIRail.RAILTRACK_NW_NE);
	part.sections[3] = Section(
		AIMap.GetTileIndex(-1 , 1) , AIRail.RAILTRACK_NW_NE);

	part.continuation_parts = array(3);
	part.continuation_parts[0] = EW_S_DIAGONAL;
	part.continuation_parts[1] = EN_BEND;
	part.continuation_parts[2] = EW_LINE;

	part.previous_parts = array(3);
	part.previous_parts[0] = SN_S_DIAGONAL;
	part.previous_parts[1] = EN_BEND;
	part.previous_parts[2] = SN_LINE;

	part.points = array(6);
	part.points[0] = AIMap.GetTileIndex(-1 , 0);
	part.points[1] = AIMap.GetTileIndex(-1 , 1);
	part.points[2] = AIMap.GetTileIndex(-1 , 2);
	part.points[3] = AIMap.GetTileIndex(0 , 1);
	part.points[4] = AIMap.GetTileIndex(0 , 0);
	part.points[5] = AIMap.GetTileIndex(1 , 0);

	part.signal_senses = array(4);
	part.signal_senses[0] = RailroadCommon.CLOCKWISE;
	part.signal_senses[1] = RailroadCommon.INVALID_SENSE;
	part.signal_senses[2] = RailroadCommon.COUNTERCLOCKWISE;
	part.signal_senses[3] = RailroadCommon.COUNTERCLOCKWISE;

	part.junctions = array(1);
	part.junctions[0] = Junction(AIMap.GetTileIndex(1 , 1) , J_EW_RECTANGLE);

	part.depots = array(2);
	part.depots[1] = Depot(AIMap.GetTileIndex(-1 , 1) , SW_BOOMERANG);

	part.parts_keep_direction = array(22);
	for(local i = 0 ; i < 22 ; i++)
		part.parts_keep_direction[i] = false;
	part.parts_keep_direction[EW_S_DIAGONAL] = true;
	part.parts_keep_direction[EN_BEND] = true;

	/* WS_BEND */
	part = parts[WS_BEND];
	part.next_tile = AIMap.GetTileIndex(1 , -1);
	part.sections = array(4);
	part.sections[0] = Section(
		AIMap.GetTileIndex(0 , -1) , AIRail.RAILTRACK_NW_NE);
	part.sections[1] = Section(
		AIMap.GetTileIndex(0 , -1) , AIRail.RAILTRACK_SW_SE);
	part.sections[2] = Section(
		AIMap.GetTileIndex(0 , 0) , AIRail.RAILTRACK_NW_NE);
	part.sections[3] = Section(
		AIMap.GetTileIndex(1 , -1) , AIRail.RAILTRACK_NW_NE);

	part.continuation_parts = array(3);
	part.continuation_parts[0] = NS_S_DIAGONAL;
	part.continuation_parts[1] = NE_BEND;
	part.continuation_parts[2] = NS_LINE;

	part.previous_parts = array(3);
	part.previous_parts[0] = WE_S_DIAGONAL;
	part.previous_parts[1] = NE_BEND;
	part.previous_parts[2] = WE_LINE;

	part.points = array(6);
	part.points[0] = AIMap.GetTileIndex(0 , -1);
	part.points[1] = AIMap.GetTileIndex(1 , -1);
	part.points[2] = AIMap.GetTileIndex(2 , -1);
	part.points[3] = AIMap.GetTileIndex(1 , 0);
	part.points[4] = AIMap.GetTileIndex(0 , 0);
	part.points[5] = AIMap.GetTileIndex(0 , 1);

	part.signal_senses = array(4);
	part.signal_senses[0] = RailroadCommon.CLOCKWISE;
	part.signal_senses[1] = RailroadCommon.INVALID_SENSE;
	part.signal_senses[2] = RailroadCommon.COUNTERCLOCKWISE;
	part.signal_senses[3] = RailroadCommon.COUNTERCLOCKWISE;

	part.junctions = array(1);
	part.junctions[0] = Junction(AIMap.GetTileIndex(0 , -1) , J_NS_RECTANGLE);

	part.depots = array(2);
	part.depots[0] = Depot(AIMap.GetTileIndex(0 , 0) , SW_BOOMERANG);

	part.parts_keep_direction = array(22);
	for(local i = 0 ; i < 22 ; i++)
		part.parts_keep_direction[i] = false;
	part.parts_keep_direction[NS_S_DIAGONAL] = true;
	part.parts_keep_direction[NE_BEND] = true;

	/* SE_BEND */
	part = parts[SE_BEND];
	part.next_tile = AIMap.GetTileIndex(1 , 1);
	part.sections = array(4);
	part.sections[0] = Section(
		AIMap.GetTileIndex(0 , 0) , AIRail.RAILTRACK_NE_SE);
	part.sections[1] = Section(
		AIMap.GetTileIndex(0 , 0) , AIRail.RAILTRACK_NW_SW);
	part.sections[2] = Section(
		AIMap.GetTileIndex(-1 , 0) , AIRail.RAILTRACK_NW_SW);
	part.sections[3] = Section(
		AIMap.GetTileIndex(0 , 1) , AIRail.RAILTRACK_NW_SW);

	part.continuation_parts = array(3);
	part.continuation_parts[0] = WE_P_DIAGONAL;
	part.continuation_parts[1] = WN_BEND;
	part.continuation_parts[2] = WE_LINE;

	part.previous_parts = array(3);
	part.previous_parts[0] = SN_P_DIAGONAL;
	part.previous_parts[1] = WN_BEND;
	part.previous_parts[2] = SN_LINE;

	part.points = array(6);
	part.points[0] = AIMap.GetTileIndex(1 , 0);
	part.points[1] = AIMap.GetTileIndex(1 , 1);
	part.points[2] = AIMap.GetTileIndex(1 , 2);
	part.points[3] = AIMap.GetTileIndex(0 , 1);
	part.points[4] = AIMap.GetTileIndex(0 , 0);
	part.points[5] = AIMap.GetTileIndex(-1 , 0);

	part.signal_senses = array(4);
	part.signal_senses[0] = RailroadCommon.INVALID_SENSE;
	part.signal_senses[1] = RailroadCommon.COUNTERCLOCKWISE;
	part.signal_senses[2] = RailroadCommon.CLOCKWISE;
	part.signal_senses[3] = RailroadCommon.CLOCKWISE;

	part.junctions = array(1);
	part.junctions[0] = Junction(AIMap.GetTileIndex(0 , 0) , J_WE_RECTANGLE);

	part.depots = array(2);
	part.depots[0] = Depot(AIMap.GetTileIndex(0 , 1) , SE_BOOMERANG);

	part.parts_keep_direction = array(22);
	for(local i = 0 ; i < 22 ; i++)
		part.parts_keep_direction[i] = false;
	part.parts_keep_direction[WE_P_DIAGONAL] = true;
	part.parts_keep_direction[WN_BEND] = true;

	/* ES_BEND */
	part = parts[ES_BEND];
	part.next_tile = AIMap.GetTileIndex(-1 , -1);
	part.sections = array(4);
	part.sections[0] = Section(
		AIMap.GetTileIndex(-1 , -1) , AIRail.RAILTRACK_NE_SE);
	part.sections[1] = Section(
		AIMap.GetTileIndex(-1 , -1) , AIRail.RAILTRACK_NW_SW);
	part.sections[2] = Section(
		AIMap.GetTileIndex(-1 , 0) , AIRail.RAILTRACK_NW_SW);
	part.sections[3] = Section(
		AIMap.GetTileIndex(-2 , -1) , AIRail.RAILTRACK_NW_SW);

	part.continuation_parts = array(3);
	part.continuation_parts[0] = NS_P_DIAGONAL;
	part.continuation_parts[1] = NW_BEND;
	part.continuation_parts[2] = NS_LINE;

	part.previous_parts = array(3);
	part.previous_parts[0] = EW_P_DIAGONAL;
	part.previous_parts[1] = NW_BEND;
	part.previous_parts[2] = EW_LINE;

	part.points = array(6);
	part.points[0] = AIMap.GetTileIndex(0 , -1);
	part.points[1] = AIMap.GetTileIndex(-1 , -1);
	part.points[2] = AIMap.GetTileIndex(-2 , -1);
	part.points[3] = AIMap.GetTileIndex(-1 , 0);
	part.points[4] = AIMap.GetTileIndex(0 , 0);
	part.points[5] = AIMap.GetTileIndex(0 , 1);

	part.signal_senses = array(4);
	part.signal_senses[0] = RailroadCommon.INVALID_SENSE;
	part.signal_senses[1] = RailroadCommon.COUNTERCLOCKWISE;
	part.signal_senses[2] = RailroadCommon.CLOCKWISE;
	part.signal_senses[3] = RailroadCommon.CLOCKWISE;

	part.junctions = array(1);
	part.junctions[0] = Junction(AIMap.GetTileIndex(-2 , -1) , J_NS_RECTANGLE);

	part.depots = array(2);
	part.depots[1] = Depot(AIMap.GetTileIndex(-1 , 0) , SE_BOOMERANG);

	part.parts_keep_direction = array(22);
	for(local i = 0 ; i < 22 ; i++)
		part.parts_keep_direction[i] = false;
	part.parts_keep_direction[NS_P_DIAGONAL] = true;
	part.parts_keep_direction[NW_BEND] = true;

	/* Lines: */

	/* WE_LINE */
	part = parts[WE_LINE];
	part.next_tile = AIMap.GetTileIndex(1 , 0);
	part.sections = array(2);
	part.sections[0] = Section(
		AIMap.GetTileIndex(0 , 0) , AIRail.RAILTRACK_NE_SW);
	part.sections[1] = Section(
		AIMap.GetTileIndex(0 , -1) , AIRail.RAILTRACK_NE_SW);

	part.continuation_parts = array(5);
	part.continuation_parts[0] = WE_LINE;
	part.continuation_parts[1] = WE_P_DIAGONAL;
	part.continuation_parts[2] = WE_S_DIAGONAL;
	part.continuation_parts[3] = WN_BEND;
	part.continuation_parts[4] = WS_BEND;

	part.previous_parts = array(5);
	part.previous_parts[0] = WE_LINE;
	part.previous_parts[1] = WE_P_DIAGONAL;
	part.previous_parts[2] = WE_S_DIAGONAL;
	part.previous_parts[3] = SE_BEND;
	part.previous_parts[4] = NE_BEND;

	part.points = array(6);
	part.points[0] = AIMap.GetTileIndex(1 , 1);
	part.points[1] = AIMap.GetTileIndex(1 , 0);
	part.points[2] = AIMap.GetTileIndex(1 , -1);
	part.points[3] = AIMap.GetTileIndex(0 , 1);
	part.points[4] = AIMap.GetTileIndex(0 , 0);
	part.points[5] = AIMap.GetTileIndex(0 , -1);

	part.signal_senses = array(2);
	part.signal_senses[0] = RailroadCommon.COUNTERCLOCKWISE;
	part.signal_senses[1] = RailroadCommon.CLOCKWISE;

	part.junctions = array(2);
	part.junctions[0] = Junction(AIMap.GetTileIndex(0 , -1) , J_NE_HOOK);
	part.junctions[1] = Junction(AIMap.GetTileIndex(0 , 0) , J_SE_HOOK);

	part.depots = array(2);
	part.depots[0] = Depot(AIMap.GetTileIndex(0 , 0) , NEW_V);
	part.depots[1] = Depot(AIMap.GetTileIndex(0 , -1) , SWE_V);

	part.parts_keep_direction = array(22);
	for(local i = 0 ; i < 22 ; i++)
		part.parts_keep_direction[i] = false;
	part.parts_keep_direction[WE_LINE] = true;
	part.parts_keep_direction[TUNNEL] = true;
	part.parts_keep_direction[BRIDGE] = true;

	/* EW_LINE */
	part = parts[EW_LINE];
	part.next_tile = AIMap.GetTileIndex(-1 , 0);
	part.sections = array(2);
	part.sections[0] = Section(
		AIMap.GetTileIndex(-1 , 0) , AIRail.RAILTRACK_NE_SW);
	part.sections[1] = Section(
		AIMap.GetTileIndex(-1 , -1) , AIRail.RAILTRACK_NE_SW);

	part.continuation_parts = array(5);
	part.continuation_parts[0] = EW_LINE;
	part.continuation_parts[1] = EW_P_DIAGONAL;
	part.continuation_parts[2] = EW_S_DIAGONAL;
	part.continuation_parts[3] = EN_BEND;
	part.continuation_parts[4] = ES_BEND;

	part.previous_parts = array(5);
	part.previous_parts[0] = EW_LINE;
	part.previous_parts[1] = EW_P_DIAGONAL;
	part.previous_parts[2] = EW_S_DIAGONAL;
	part.previous_parts[3] = NW_BEND;
	part.previous_parts[4] = SW_BEND;

	part.points = array(6);
	part.points[0] = AIMap.GetTileIndex(-1 , -1);
	part.points[1] = AIMap.GetTileIndex(-1 , 0);
	part.points[2] = AIMap.GetTileIndex(-1 , 1);
	part.points[3] = AIMap.GetTileIndex(0 , -1);
	part.points[4] = AIMap.GetTileIndex(0 , 0);
	part.points[5] = AIMap.GetTileIndex(0 , 1);

	part.signal_senses = array(2);
	part.signal_senses[0] = RailroadCommon.COUNTERCLOCKWISE;
	part.signal_senses[1] = RailroadCommon.CLOCKWISE;

	part.junctions = array(2);
	part.junctions[0] = Junction(AIMap.GetTileIndex(-1 , -1) , J_NW_HOOK);
	part.junctions[1] = Junction(AIMap.GetTileIndex(-1 , 0) , J_SW_HOOK);

	part.depots = array(2);
	part.depots[0] = Depot(AIMap.GetTileIndex(-1 , -1) , SWE_V);
	part.depots[1] = Depot(AIMap.GetTileIndex(-1 , 0) , NEW_V);

	part.parts_keep_direction = array(22);
	for(local i = 0 ; i < 22 ; i++)
		part.parts_keep_direction[i] = false;
	part.parts_keep_direction[EW_LINE] = true;
	part.parts_keep_direction[TUNNEL] = true;
	part.parts_keep_direction[BRIDGE] = true;

	/* SN_LINE */
	part = parts[SN_LINE];
	part.next_tile = AIMap.GetTileIndex(0 , 1);
	part.sections = array(2);
	part.sections[0] = Section(
		AIMap.GetTileIndex(0 , 0) , AIRail.RAILTRACK_NW_SE);
	part.sections[1] = Section(
		AIMap.GetTileIndex(-1 , 0) , AIRail.RAILTRACK_NW_SE);

	part.continuation_parts = array(5);
	part.continuation_parts[0] = SN_LINE;
	part.continuation_parts[1] = SN_P_DIAGONAL;
	part.continuation_parts[2] = SN_S_DIAGONAL;
	part.continuation_parts[3] = SE_BEND;
	part.continuation_parts[4] = SW_BEND;

	part.previous_parts = array(5);
	part.previous_parts[0] = SN_LINE;
	part.previous_parts[1] = SN_P_DIAGONAL;
	part.previous_parts[2] = SN_S_DIAGONAL;
	part.previous_parts[3] = WN_BEND;
	part.previous_parts[4] = EN_BEND;

	part.points = array(6);
	part.points[0] = AIMap.GetTileIndex(-1 , 1);
	part.points[1] = AIMap.GetTileIndex(0 , 1);
	part.points[2] = AIMap.GetTileIndex(1 , 1);
	part.points[3] = AIMap.GetTileIndex(-1 , 0);
	part.points[4] = AIMap.GetTileIndex(0 , 0);
	part.points[5] = AIMap.GetTileIndex(1 , 0);

	part.signal_senses = array(2);
	part.signal_senses[0] = RailroadCommon.COUNTERCLOCKWISE;
	part.signal_senses[1] = RailroadCommon.CLOCKWISE;

	part.junctions = array(2);
	part.junctions[0] = Junction(AIMap.GetTileIndex(0 , 0) , J_WN_HOOK);
	part.junctions[1] = Junction(AIMap.GetTileIndex(-1 , 0) , J_EN_HOOK);

	part.depots = array(2);
	part.depots[0] = Depot(AIMap.GetTileIndex(-1 , 0) , NWS_V);
	part.depots[1] = Depot(AIMap.GetTileIndex(0 , 0) , SEN_V);

	part.parts_keep_direction = array(22);
	for(local i = 0 ; i < 22 ; i++)
		part.parts_keep_direction[i] = false;
	part.parts_keep_direction[SN_LINE] = true;
	part.parts_keep_direction[TUNNEL] = true;
	part.parts_keep_direction[BRIDGE] = true;

	/* NS_LINE */
	part = parts[NS_LINE];
	part.next_tile = AIMap.GetTileIndex(0 , -1);
	part.sections = array(2);
	part.sections[0] = Section(
		AIMap.GetTileIndex(0 , -1) , AIRail.RAILTRACK_NW_SE);
	part.sections[1] = Section(
		AIMap.GetTileIndex(-1 , -1) , AIRail.RAILTRACK_NW_SE);

	part.continuation_parts = array(5);
	part.continuation_parts[0] = NS_LINE;
	part.continuation_parts[1] = NS_P_DIAGONAL;
	part.continuation_parts[2] = NS_S_DIAGONAL;
	part.continuation_parts[3] = NE_BEND;
	part.continuation_parts[4] = NW_BEND;

	part.previous_parts = array(5);
	part.previous_parts[0] = NS_LINE;
	part.previous_parts[1] = NS_P_DIAGONAL;
	part.previous_parts[2] = NS_S_DIAGONAL;
	part.previous_parts[3] = WS_BEND;
	part.previous_parts[4] = ES_BEND;

	part.points = array(6);
	part.points[0] = AIMap.GetTileIndex(1 , -1);
	part.points[1] = AIMap.GetTileIndex(0 , -1);
	part.points[2] = AIMap.GetTileIndex(-1 , -1);
	part.points[3] = AIMap.GetTileIndex(1 , 0);
	part.points[4] = AIMap.GetTileIndex(0 , 0);
	part.points[5] = AIMap.GetTileIndex(-1 , 0);

	part.signal_senses = array(2);
	part.signal_senses[0] = RailroadCommon.COUNTERCLOCKWISE;
	part.signal_senses[1] = RailroadCommon.CLOCKWISE;

	part.junctions = array(2);
	part.junctions[0] = Junction(AIMap.GetTileIndex(-1 , -1) , J_ES_HOOK);
	part.junctions[1] = Junction(AIMap.GetTileIndex(0 , -1) , J_WS_HOOK);

	part.depots = array(2);
	part.depots[0] = Depot(AIMap.GetTileIndex(0 , -1) , SEN_V);
	part.depots[1] = Depot(AIMap.GetTileIndex(-1 , -1) , NWS_V);

	part.parts_keep_direction = array(22);
	for(local i = 0 ; i < 22 ; i++)
		part.parts_keep_direction[i] = false;
	part.parts_keep_direction[NS_LINE] = true;
	part.parts_keep_direction[TUNNEL] = true;
	part.parts_keep_direction[BRIDGE] = true;

	/* Diagonals: */

	/* EW_S_DIAGONAL */
	part = parts[EW_S_DIAGONAL];
	part.next_tile = AIMap.GetTileIndex(-1 , 1);
	part.sections = array(4);
	part.sections[0] = Section(
		AIMap.GetTileIndex(-1 , 0) , AIRail.RAILTRACK_SW_SE);
	part.sections[1] = Section(
		AIMap.GetTileIndex(-1 , 0) , AIRail.RAILTRACK_NW_NE);
	part.sections[2] = Section(
		AIMap.GetTileIndex(-1 , -1) , AIRail.RAILTRACK_SW_SE);
	part.sections[3] = Section(
		AIMap.GetTileIndex(-1 , 1) , AIRail.RAILTRACK_NW_NE);

	part.continuation_parts = array(3);
	part.continuation_parts[0] = EW_S_DIAGONAL;
	part.continuation_parts[1] = EN_BEND;
	part.continuation_parts[2] = EW_LINE;

	part.previous_parts = array(3);
	part.previous_parts[0] = EW_S_DIAGONAL;
	part.previous_parts[1] = SW_BEND;
	part.previous_parts[2] = EW_LINE;

	part.points = array(6);
	part.points[0] = AIMap.GetTileIndex(-1 , 0);
	part.points[1] = AIMap.GetTileIndex(-1 , 1);
	part.points[2] = AIMap.GetTileIndex(-1 , 2);
	part.points[3] = AIMap.GetTileIndex(0 , -1);
	part.points[4] = AIMap.GetTileIndex(0 , 0);
	part.points[5] = AIMap.GetTileIndex(0 , 1);

	part.signal_senses = array(4);
	part.signal_senses[0] = RailroadCommon.COUNTERCLOCKWISE;
	part.signal_senses[1] = RailroadCommon.INVALID_SENSE;
	part.signal_senses[2] = RailroadCommon.CLOCKWISE;
	part.signal_senses[3] = RailroadCommon.INVALID_SENSE;

	part.junctions = array(2);
	part.junctions[0] = Junction(AIMap.GetTileIndex(1 , 1) , J_EW_RECTANGLE);
	part.junctions[1] = Junction(AIMap.GetTileIndex(0 , -3) , J_SN_RECTANGLE);

	part.depots = array(2);
	part.depots[0] = Depot(AIMap.GetTileIndex(-1 , -1) , EN_BOOMERANG);
	part.depots[1] = Depot(AIMap.GetTileIndex(-1 , 1) , SW_BOOMERANG);

	part.parts_keep_direction = array(22);
	for(local i = 0 ; i < 22 ; i++)
		part.parts_keep_direction[i] = false;
	part.parts_keep_direction[EW_S_DIAGONAL] = true;
	part.parts_keep_direction[EN_BEND] = true;

	/* WE_S_DIAGONAL */
	part = parts[WE_S_DIAGONAL];
	part.next_tile = AIMap.GetTileIndex(1 , -1);
	part.sections = array(4);
	part.sections[0] = Section(
		AIMap.GetTileIndex(0 , -1) , AIRail.RAILTRACK_SW_SE);
	part.sections[1] = Section(
		AIMap.GetTileIndex(0 , -1) , AIRail.RAILTRACK_NW_NE);
	part.sections[2] = Section(
		AIMap.GetTileIndex(0 , -2) , AIRail.RAILTRACK_SW_SE);
	part.sections[3] = Section(
		AIMap.GetTileIndex(0 , 0) , AIRail.RAILTRACK_NW_NE);

	part.continuation_parts = array(3);
	part.continuation_parts[0] = WE_S_DIAGONAL;
	part.continuation_parts[1] = WS_BEND;
	part.continuation_parts[2] = WE_LINE;

	part.previous_parts = array(3);
	part.previous_parts[0] = WE_S_DIAGONAL;
	part.previous_parts[1] = NE_BEND;
	part.previous_parts[2] = WE_LINE;

	part.points = array(6);
	part.points[0] = AIMap.GetTileIndex(1 , 0);
	part.points[1] = AIMap.GetTileIndex(1 , -1);
	part.points[2] = AIMap.GetTileIndex(1 , -2);
	part.points[3] = AIMap.GetTileIndex(0 , 1);
	part.points[4] = AIMap.GetTileIndex(0 , 0);
	part.points[5] = AIMap.GetTileIndex(0 , -1);

	part.signal_senses = array(4);
	part.signal_senses[0] = RailroadCommon.COUNTERCLOCKWISE;
	part.signal_senses[1] = RailroadCommon.INVALID_SENSE;
	part.signal_senses[2] = RailroadCommon.CLOCKWISE;
	part.signal_senses[3] = RailroadCommon.INVALID_SENSE;

	part.junctions = array(2);
	part.junctions[0] = Junction(AIMap.GetTileIndex(0 , -2) , J_WE_RECTANGLE);
	part.junctions[1] = Junction(AIMap.GetTileIndex(-1 , 0) , J_NS_RECTANGLE);

	part.depots = array(2);
	part.depots[0] = Depot(AIMap.GetTileIndex(-1 , 1) , SW_BOOMERANG);
	part.depots[1] = Depot(AIMap.GetTileIndex(-1 , -1) , EN_BOOMERANG);

	part.parts_keep_direction = array(22);
	for(local i = 0 ; i < 22 ; i++)
		part.parts_keep_direction[i] = false;
	part.parts_keep_direction[WE_S_DIAGONAL] = true;
	part.parts_keep_direction[WS_BEND] = true;

	/* NS_S_DIAGONAL */
	part = parts[NS_S_DIAGONAL];
	part.next_tile = AIMap.GetTileIndex(1 , -1);
	part.sections = array(4);
	part.sections[0] = Section(
		AIMap.GetTileIndex(0 , -1) , AIRail.RAILTRACK_NW_NE);
	part.sections[1] = Section(
		AIMap.GetTileIndex(0 , -1) , AIRail.RAILTRACK_SW_SE);
	part.sections[2] = Section(
		AIMap.GetTileIndex(-1 , -1) , AIRail.RAILTRACK_SW_SE);
	part.sections[3] = Section(
		AIMap.GetTileIndex(1 , -1) , AIRail.RAILTRACK_NW_NE);

	part.continuation_parts = array(3);
	part.continuation_parts[0] = NS_S_DIAGONAL;
	part.continuation_parts[1] = NE_BEND;
	part.continuation_parts[2] = NS_LINE;

	part.previous_parts = array(3);
	part.previous_parts[0] = NS_S_DIAGONAL;
	part.previous_parts[1] = WS_BEND;
	part.previous_parts[2] = NS_LINE;

	part.points = array(6);
	part.points[0] = AIMap.GetTileIndex(2 , -1);
	part.points[1] = AIMap.GetTileIndex(1 , -1);
	part.points[2] = AIMap.GetTileIndex(0 , -1);
	part.points[3] = AIMap.GetTileIndex(1 , 0);
	part.points[4] = AIMap.GetTileIndex(0 , 0);
	part.points[5] = AIMap.GetTileIndex(-1 , 0);

	part.signal_senses = array(4);
	part.signal_senses[0] = RailroadCommon.CLOCKWISE;
	part.signal_senses[1] = RailroadCommon.INVALID_SENSE;
	part.signal_senses[2] = RailroadCommon.INVALID_SENSE;
	part.signal_senses[3] = RailroadCommon.COUNTERCLOCKWISE;

	part.junctions = array(2);
	part.junctions[0] = Junction(AIMap.GetTileIndex(0 , -1) , J_NS_RECTANGLE);
	part.junctions[1] = Junction(AIMap.GetTileIndex(-1 , -1) , J_WE_RECTANGLE);

	part.depots = array(2);
	part.depots[0] = Depot(AIMap.GetTileIndex(0 , 0) , SW_BOOMERANG);
	part.depots[1] = Depot(AIMap.GetTileIndex(-2 , 0) , EN_BOOMERANG);

	part.parts_keep_direction = array(22);
	for(local i = 0 ; i < 22 ; i++)
		part.parts_keep_direction[i] = false;
	part.parts_keep_direction[NS_S_DIAGONAL] = true;
	part.parts_keep_direction[NE_BEND] = true;

	/* SN_S_DIAGONAL */
	part = parts[SN_S_DIAGONAL];
	part.next_tile = AIMap.GetTileIndex(-1 , 1);
	part.sections = array(4);
	part.sections[0] = Section(
		AIMap.GetTileIndex(-1 , 0) , AIRail.RAILTRACK_NW_NE);
	part.sections[1] = Section(
		AIMap.GetTileIndex(-1 , 0) , AIRail.RAILTRACK_SW_SE);
	part.sections[2] = Section(
		AIMap.GetTileIndex(0 , 0) , AIRail.RAILTRACK_NW_NE);
	part.sections[3] = Section(
		AIMap.GetTileIndex(-2 , 0) , AIRail.RAILTRACK_SW_SE);

	part.continuation_parts = array(3);
	part.continuation_parts[0] = SN_S_DIAGONAL;
	part.continuation_parts[1] = SW_BEND;
	part.continuation_parts[2] = SN_LINE;

	part.previous_parts = array(3);
	part.previous_parts[0] = SN_S_DIAGONAL;
	part.previous_parts[1] = EN_BEND;
	part.previous_parts[2] = SN_LINE;

	part.points = array(6);
	part.points[0] = AIMap.GetTileIndex(-2 , 1);
	part.points[1] = AIMap.GetTileIndex(-1 , 1);
	part.points[2] = AIMap.GetTileIndex(0 , 1);
	part.points[3] = AIMap.GetTileIndex(-1 , 0);
	part.points[4] = AIMap.GetTileIndex(0 , 0);
	part.points[5] = AIMap.GetTileIndex(1 , 0);

	part.signal_senses = array(4);
	part.signal_senses[0] = RailroadCommon.INVALID_SENSE;
	part.signal_senses[1] = RailroadCommon.COUNTERCLOCKWISE;
	part.signal_senses[2] = RailroadCommon.INVALID_SENSE;
	part.signal_senses[3] = RailroadCommon.CLOCKWISE;

	part.junctions = array(2);
	part.junctions[0] = Junction(AIMap.GetTileIndex(-1 , -2) , J_SN_RECTANGLE);
	part.junctions[1] = Junction(AIMap.GetTileIndex(2 , 0) , J_EW_RECTANGLE);

	part.depots = array(2);
	part.depots[0] = Depot(AIMap.GetTileIndex(-2 , 0) , EN_BOOMERANG);
	part.depots[1] = Depot(AIMap.GetTileIndex(0 , 0) , SW_BOOMERANG);

	part.parts_keep_direction = array(22);
	for(local i = 0 ; i < 22 ; i++)
		part.parts_keep_direction[i] = false;
	part.parts_keep_direction[SN_S_DIAGONAL] = true;
	part.parts_keep_direction[SW_BEND] = true;

	/* EW_P_DIAGONAL */
	part = parts[EW_P_DIAGONAL];
	part.next_tile = AIMap.GetTileIndex(-1 , -1);
	part.sections = array(4);
	part.sections[0] = Section(
		AIMap.GetTileIndex(-1 , -1) , AIRail.RAILTRACK_NW_SW);
	part.sections[1] = Section(
		AIMap.GetTileIndex(-1 , -1) , AIRail.RAILTRACK_NE_SE);
	part.sections[2] = Section(
		AIMap.GetTileIndex(-1 , 0) , AIRail.RAILTRACK_NW_SW);
	part.sections[3] = Section(
		AIMap.GetTileIndex(-1 , -2) , AIRail.RAILTRACK_NE_SE);

	part.continuation_parts = array(3);
	part.continuation_parts[0] = EW_P_DIAGONAL;
	part.continuation_parts[1] = ES_BEND;
	part.continuation_parts[2] = EW_LINE;

	part.previous_parts = array(3);
	part.previous_parts[0] = EW_P_DIAGONAL;
	part.previous_parts[1] = NW_BEND;
	part.previous_parts[2] = EW_LINE;

	part.points = array(6);
	part.points[0] = AIMap.GetTileIndex(-1 , -2);
	part.points[1] = AIMap.GetTileIndex(-1 , -1);
	part.points[2] = AIMap.GetTileIndex(-1 , 0);
	part.points[3] = AIMap.GetTileIndex(0 , -1);
	part.points[4] = AIMap.GetTileIndex(0 , 0);
	part.points[5] = AIMap.GetTileIndex(0 , 1);

	part.signal_senses = array(4);
	part.signal_senses[0] = RailroadCommon.COUNTERCLOCKWISE;
	part.signal_senses[1] = RailroadCommon.INVALID_SENSE;
	part.signal_senses[2] = RailroadCommon.CLOCKWISE;
	part.signal_senses[3] = RailroadCommon.INVALID_SENSE;

	part.junctions = array(2);
	part.junctions[0] = Junction(AIMap.GetTileIndex(-1 , 0) , J_NS_RECTANGLE);
	part.junctions[1] = Junction(AIMap.GetTileIndex(1 , -1) , J_EW_RECTANGLE);

	part.depots = array(2);
	part.depots[0] = Depot(AIMap.GetTileIndex(0 , -1) , WN_BOOMERANG);
	part.depots[1] = Depot(AIMap.GetTileIndex(0 , 1) , SE_BOOMERANG);

	part.parts_keep_direction = array(22);
	for(local i = 0 ; i < 22 ; i++)
		part.parts_keep_direction[i] = false;
	part.parts_keep_direction[EW_P_DIAGONAL] = true;
	part.parts_keep_direction[ES_BEND] = true;

	/* WE_P_DIAGONAL */
	part = parts[WE_P_DIAGONAL];
	part.next_tile = AIMap.GetTileIndex(1 , 1);
	part.sections = array(4);
	part.sections[0] = Section(
		AIMap.GetTileIndex(0 , 0) , AIRail.RAILTRACK_NW_SW);
	part.sections[1] = Section(
		AIMap.GetTileIndex(0 , 0) , AIRail.RAILTRACK_NE_SE)
	part.sections[2] = Section(
		AIMap.GetTileIndex(0 , -1) , AIRail.RAILTRACK_NE_SE);
	part.sections[3] = Section(
		AIMap.GetTileIndex(0 , 1) , AIRail.RAILTRACK_NW_SW);

	part.continuation_parts = array(3);
	part.continuation_parts[0] = WE_P_DIAGONAL;
	part.continuation_parts[1] = WN_BEND;
	part.continuation_parts[2] = WE_LINE;

	part.previous_parts = array(3);
	part.previous_parts[0] = WE_P_DIAGONAL;
	part.previous_parts[1] = SE_BEND;
	part.previous_parts[2] = WE_LINE;

	part.points = array(6);
	part.points[0] = AIMap.GetTileIndex(1 , 2);
	part.points[1] = AIMap.GetTileIndex(1 , 1);
	part.points[2] = AIMap.GetTileIndex(1 , 0);
	part.points[3] = AIMap.GetTileIndex(0 , 1);
	part.points[4] = AIMap.GetTileIndex(0 , 0);
	part.points[5] = AIMap.GetTileIndex(0 , -1);

	part.signal_senses = array(4);
	part.signal_senses[0] = RailroadCommon.INVALID_SENSE;
	part.signal_senses[1] = RailroadCommon.COUNTERCLOCKWISE;
	part.signal_senses[2] = RailroadCommon.CLOCKWISE;
	part.signal_senses[3] = RailroadCommon.INVALID_SENSE;

	part.junctions = array(2);
	part.junctions[0] = Junction(AIMap.GetTileIndex(0 , 0) , J_WE_RECTANGLE);
	part.junctions[1] = Junction(AIMap.GetTileIndex(0 , -3) , J_SN_RECTANGLE);

	part.depots = array(2);
	part.depots[0] = Depot(AIMap.GetTileIndex(0 , 1) , SE_BOOMERANG);
	part.depots[1] = Depot(AIMap.GetTileIndex(0 , -1) , WN_BOOMERANG);

	part.parts_keep_direction = array(22);
	for(local i = 0 ; i < 22 ; i++)
		part.parts_keep_direction[i] = false;
	part.parts_keep_direction[WE_P_DIAGONAL] = true;
	part.parts_keep_direction[WN_BEND] = true;

	/* NS_P_DIAGONAL */
	part = parts[NS_P_DIAGONAL];
	part.next_tile = AIMap.GetTileIndex(-1 , -1);
	part.sections = array(4);
	part.sections[0] = Section(
		AIMap.GetTileIndex(-1 , -1) , AIRail.RAILTRACK_NE_SE);
	part.sections[1] = Section(
		AIMap.GetTileIndex(-1 , -1) , AIRail.RAILTRACK_NW_SW);
	part.sections[2] = Section(
		AIMap.GetTileIndex(-2 , -1) , AIRail.RAILTRACK_NW_SW);
	part.sections[3] = Section(
		AIMap.GetTileIndex(0 , -1) , AIRail.RAILTRACK_NE_SE);

	part.continuation_parts = array(3);
	part.continuation_parts[0] = NS_P_DIAGONAL;
	part.continuation_parts[1] = NW_BEND;
	part.continuation_parts[2] = NS_LINE;

	part.previous_parts = array(3);
	part.previous_parts[0] = NS_P_DIAGONAL;
	part.previous_parts[1] = ES_BEND;
	part.previous_parts[2] = NS_LINE;

	part.points = array(6);
	part.points[0] = AIMap.GetTileIndex(0 , -1);
	part.points[1] = AIMap.GetTileIndex(-1 , -1);
	part.points[2] = AIMap.GetTileIndex(-2 ,-1);
	part.points[3] = AIMap.GetTileIndex(1 , 0);
	part.points[4] = AIMap.GetTileIndex(0 , 0);
	part.points[5] = AIMap.GetTileIndex(-1 , 0);

	part.signal_senses = array(4);
	part.signal_senses[0] = RailroadCommon.COUNTERCLOCKWISE;
	part.signal_senses[1] = RailroadCommon.INVALID_SENSE;
	part.signal_senses[2] = RailroadCommon.INVALID_SENSE;
	part.signal_senses[3] = RailroadCommon.CLOCKWISE;

	part.junctions = array(2);
	part.junctions[0] = Junction(AIMap.GetTileIndex(-2 , -1) , J_NS_RECTANGLE);
	part.junctions[1] = Junction(AIMap.GetTileIndex(2 , 0) , J_EW_RECTANGLE);

	part.depots = array(2);
	part.depots[0] = Depot(AIMap.GetTileIndex(1 , 0) , WN_BOOMERANG);
	part.depots[1] = Depot(AIMap.GetTileIndex(-1 , 0) , SE_BOOMERANG);

	part.parts_keep_direction = array(22);
	for(local i = 0 ; i < 22 ; i++)
		part.parts_keep_direction[i] = false;
	part.parts_keep_direction[NS_P_DIAGONAL] = true;
	part.parts_keep_direction[NW_BEND] = true;

	/* SN_P_DIAGONAL */
	part = parts[SN_P_DIAGONAL];
	part.next_tile = AIMap.GetTileIndex(1 , 1);
	part.sections = array(4);
	part.sections[0] = Section(
		AIMap.GetTileIndex(0 , 0) , AIRail.RAILTRACK_NE_SE);
	part.sections[1] = Section(
		AIMap.GetTileIndex(0 , 0) , AIRail.RAILTRACK_NW_SW);
	part.sections[2] = Section(
		AIMap.GetTileIndex(-1 , 0) , AIRail.RAILTRACK_NW_SW);
	part.sections[3] = Section(
		AIMap.GetTileIndex(1 , 0) , AIRail.RAILTRACK_NE_SE);

	part.continuation_parts = array(3);
	part.continuation_parts[0] = SN_P_DIAGONAL;
	part.continuation_parts[1] = SE_BEND;
	part.continuation_parts[2] = SN_LINE;

	part.previous_parts = array(3);
	part.previous_parts[0] = SN_P_DIAGONAL;
	part.previous_parts[1] = WN_BEND;
	part.previous_parts[2] = SN_LINE;

	part.points = array(6);
	part.points[0] = AIMap.GetTileIndex(0 , 1);
	part.points[1] = AIMap.GetTileIndex(1 , 1);
	part.points[2] = AIMap.GetTileIndex(2 , 1);
	part.points[3] = AIMap.GetTileIndex(-1 , 0);
	part.points[4] = AIMap.GetTileIndex(0 , 0);
	part.points[5] = AIMap.GetTileIndex(1 , 0);

	part.signal_senses = array(4);
	part.signal_senses[0] = RailroadCommon.COUNTERCLOCKWISE;
	part.signal_senses[1] = RailroadCommon.INVALID_SENSE;
	part.signal_senses[2] = RailroadCommon.INVALID_SENSE;
	part.signal_senses[3] = RailroadCommon.CLOCKWISE;

	part.junctions = array(2);
	part.junctions[0] = Junction(AIMap.GetTileIndex(1 , -2) , J_SN_RECTANGLE);
	part.junctions[1] = Junction(AIMap.GetTileIndex(-1 , -1) , J_WE_RECTANGLE);

	part.depots = array(2);
	part.depots[0] = Depot(AIMap.GetTileIndex(-1 , 0) , SE_BOOMERANG);
	part.depots[1] = Depot(AIMap.GetTileIndex(1 , 0) , WN_BOOMERANG);

	part.parts_keep_direction = array(22);
	for(local i = 0 ; i < 22 ; i++)
		part.parts_keep_direction[i] = false;
	part.parts_keep_direction[SN_P_DIAGONAL] = true;
	part.parts_keep_direction[SE_BEND] = true;
}

function DoubleTrackParts::ConvertDoublePart(tile , part_index , rail_type){
	local converted_tiles = BinaryTree();
	foreach(section in parts[part_index].sections){
		if(section.track != AIRail.RAILTRACK_INVALID && !converted_tiles.Exists(section.offset + tile)){
			converted_tiles.Insert(section.offset + tile);
			if(!AIRail.ConvertRailType(section.offset + tile , section.offset + tile , rail_type)) return false;
		}
	}
	return true;
}

function DoubleTrackParts::BuildAllParts(tile){
	AIRail.SetCurrentRailType(0);
	for(local i = 0 ; i <= J_WS_HOOK ; i++){
		if(parts[i] == null) continue;
		LevelPart(tile , i , 2);
		BuildDoublePart(tile , i);
		BuildDoublePartSignals(tile , i , AIRail.SIGNALTYPE_NORMAL);
		AISign.BuildSign(tile + AIMap.GetTileIndex(-1 , -1), ToString(i));
		if(i % 5 == 0 && i != 0){
			tile += AIMap.GetTileIndex(8 , -8 * 4);
		}else{
			tile += AIMap.GetTileIndex(0 , 8);
		}
	}
}

function DoubleTrackParts::BuildAllDepotParts(tile){
	AIRail.SetCurrentRailType(0);
	local n = 0;
	for(local i = 0 ; i <= EW_S_DIAGONAL ; i++){
		foreach(depot in parts[i].depots){
			if(depot != null){
				foreach(depot_position in parts[depot.part_index].depot_positions){
					BuildDoublePart(tile , i);
					n++;
					if(!IsLine(i))
						BuildDoublePart(tile + depot.offset , depot.part_index);
					foreach(section in depot_position.sections){
						AIRail.BuildRailTrack(depot_position.sections[0].offset + tile + depot.offset , section.track);
					}
					AIRail.BuildRailDepot(depot_position.offset + tile + depot.offset ,
						depot_position.sections[0].offset + tile + depot.offset);
					AISign.BuildSign(tile + AIMap.GetTileIndex(-1 , -1),
						ToString(i) + " " + ToString(depot.part_index));
					if(n % 5 == 0 && n != 0){
						tile += AIMap.GetTileIndex(6 , -6 * 4);
					}else{
						tile += AIMap.GetTileIndex(0 , 6);
					}
				}
			}
		}
	}
}

function DoubleTrackParts::BuildAllJunctionParts(tile){
	AIRail.SetCurrentRailType(0);
	local n = 0;
	for(local i = 0 ; i <= EW_S_DIAGONAL ; i++){
		foreach(junction in parts[i].junctions){
			BuildDoublePart(tile , i);
			n++;
			BuildDoublePart(tile + junction.offset , junction.part_index);
			AISign.BuildSign(tile + AIMap.GetTileIndex(-1 , -1),
				ToString(i) + " " + ToString(junction.part_index));
			if(n % 5 == 0 && n != 0){
				tile += AIMap.GetTileIndex(7 , -7 * 4);
			}else{
				tile += AIMap.GetTileIndex(0 , 7);
			}
		}
	}
}

function DoubleTrackParts::ConvertAllParts(tile , rail_type){
	for(local i = 0 ; i <= J_WS_HOOK ; i++){
		if(parts[i] == null) continue;
		ConvertDoublePart(tile , i , rail_type);

		if(i % 5 == 0 && i != 0){
			tile += AIMap.GetTileIndex(8 , -8 * 4);
		}else{
			tile += AIMap.GetTileIndex(0 , 8);
		}
	}
}

function DoubleTrackParts::BuildDoublePart(tile , part_index){
	foreach(section in parts[part_index].sections){
		if(section.track != AIRail.RAILTRACK_INVALID &&
			!AIRail.BuildRailTrack(tile + section.offset , section.track)) return false;
	}
	return true;
}

function DoubleTrackParts::RemoveDoublePartSignals(tile , part_index){
	if(parts[part_index].signal_senses == null) return true;
	for(local i = 0 ; i < parts[part_index].sections.len() ; i++){


		if(parts[part_index].signal_senses[i] == RailroadCommon.INVALID_SENSE) continue;
		if(!RailroadCommon.RemoveSignal(tile + parts[part_index].sections[i].offset ,
			parts[part_index].sections[i].track ,
			parts[part_index].signal_senses[i])) return false;
	}
	return true;
}

function DoubleTrackParts::BuildDoublePartSignals(tile , part_index , signal_type){
	if(parts[part_index].signal_senses == null) return true;
	for(local i = 0 ; i < parts[part_index].sections.len() ; i++){
		if(parts[part_index].signal_senses[i] == RailroadCommon.INVALID_SENSE) continue;
		if(!RailroadCommon.BuildSignal(tile + parts[part_index].sections[i].offset ,
			parts[part_index].sections[i].track ,
			parts[part_index].signal_senses[i] , signal_type)) return false;
	}
	return true;
}

function DoubleTrackParts::DemolishDoublePart(tile , part_index){
	if(parts[part_index].sections == null) return true;
	foreach(section in parts[part_index].sections){
		if(section.track != AIRail.RAILTRACK_INVALID &&
			!AIRail.RemoveRailTrack(tile + section.offset , section.track)) return false;
	}
	return true;
}

function DoubleTrackParts::LandToBuildDoublePart(tile , part_index){
	foreach(section in parts[part_index].sections){
		if(!RailroadCommon.CanBuildRailOnLand(tile + section.offset))
			return false;
	}
	return true;
}

function DoubleTrackParts::SlopesToBuildDoublePart(tile , part_index){
	foreach(section in parts[part_index].sections){
		if(!RailroadCommon.CanBuildTrackOnSlope(tile + section.offset , section.track)) return false;
	}
	return true;
}

function DoubleTrackParts::ToString(part_index){
	return parts_names[part_index];
}

function DoubleTrackParts::ChangedDirection(parent_part , children_part){
	switch(parent_part){
		case BRIDGE:
		case TUNNEL:
			if(IsLine(children_part)) return false;
			else return true;
		break;
	}

	return !parts[parent_part].parts_keep_direction[children_part];
}

function DoubleTrackParts::IsLineBendOrDiagonal(part_index){
	return (EW_LINE <= part_index && part_index <= EW_S_DIAGONAL);
}

function DoubleTrackParts::IsLine(part_index){
	return (EW_LINE <= part_index && part_index <= SN_LINE);
}

function DoubleTrackParts::IsNotLine(part_index){
	return IsBend(part_index) || IsDiagonal(part_index);
}

function DoubleTrackParts::IsBend(part_index){
	return NE_BEND <= part_index && part_index <= WN_BEND;
}

function DoubleTrackParts::IsDiagonal(part_index){
	return NS_P_DIAGONAL <= part_index && part_index <= EW_S_DIAGONAL;
}

function DoubleTrackParts::GetDoublePartTilesHeight(tile , part_index){
	local heights = array(0);

	foreach(point in parts[part_index].points){
		local t = tile + point;
		heights.push(Point(t , AITile.GetCornerHeight(t , AITile.CORNER_N)));
	}

	return heights;
}

function DoubleTrackParts::GetEntryPartHeight(tile , part_index){
	local heights = GetDoublePartTilesHeight(tile , part_index);
	local height = 0;

	if(IsBend(part_index)){
		local indexes = [0 , 4 , 5];

		foreach(i in indexes){
			if(heights[i].height > height) height = heights[i].height;
		}

	}else{
		for(local i = 3 ; i < 6 ; i++){
			if(heights[i].height > height) height = heights[i].height;
		}
	}

	return height;
}

function DoubleTrackParts::LevelPart(tile , part_index , height){
	local heights = GetDoublePartTilesHeight(tile , part_index);

	foreach(point in heights){
		local current_height = AITile.GetCornerHeight(point.tile , AITile.CORNER_N);

		while(current_height < height){
			if(!AITile.RaiseTile(point.tile , AITile.SLOPE_N)) return false;
			current_height++;
		}

		while(current_height > height){
			if(!AITile.LowerTile(point.tile , AITile.SLOPE_N)) return false;
			current_height--;
		}
	}

	return true;
}

function DoubleTrackParts::GetOppositePart(part_index){
	switch(part_index){
		case NE_BEND: return EN_BEND;
		case EN_BEND: return NE_BEND;
		case SW_BEND: return WS_BEND;
		case WS_BEND: return SW_BEND;
		case ES_BEND: return SE_BEND;
		case SE_BEND: return ES_BEND;
		case NW_BEND: return WN_BEND;
		case WN_BEND: return NW_BEND;
		case EW_LINE: return WE_LINE;
		case WE_LINE: return EW_LINE;
		case NS_LINE: return SN_LINE;
		case SN_LINE: return NS_LINE;
		case NS_P_DIAGONAL: return SN_P_DIAGONAL;
		case SN_P_DIAGONAL: return NS_P_DIAGONAL;
		case WE_P_DIAGONAL: return EW_P_DIAGONAL;
		case EW_P_DIAGONAL: return WE_P_DIAGONAL;
		case NS_S_DIAGONAL: return SN_S_DIAGONAL;
		case SN_S_DIAGONAL: return NS_S_DIAGONAL;
		case WE_S_DIAGONAL: return EW_S_DIAGONAL;
		case EW_S_DIAGONAL: return WE_S_DIAGONAL;
		default:
			throw("Invalid part index.");
		break;
	}
}

function DoubleTrackParts::GetOppositePartTile(tile , part_index){
	switch(part_index){

		case EW_LINE: return tile + AIMap.GetTileIndex(-1 , 0);
		case WE_LINE: return tile + AIMap.GetTileIndex(1 , 0);
		case NS_LINE: return tile + AIMap.GetTileIndex(0 , -1);
		case SN_LINE: return tile + AIMap.GetTileIndex(0 , 1);

		case NE_BEND:
		case EN_BEND:
		case SW_BEND:
		case WS_BEND:
		case ES_BEND:
		case SE_BEND:
		case NW_BEND:
		case WN_BEND:
		case NS_P_DIAGONAL:
		case SN_P_DIAGONAL:
		case WE_P_DIAGONAL:
		case EW_P_DIAGONAL:
		case NS_S_DIAGONAL:
		case SN_S_DIAGONAL:
		case WE_S_DIAGONAL:
		case EW_S_DIAGONAL:
			throw("Currently, this part index is not supported in this function.");
		default:
			throw("Invalid part index.");
		break;
	}
}
