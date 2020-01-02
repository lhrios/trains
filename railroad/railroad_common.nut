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


class RailroadCommon {
	/* Public: */

	static CLOCKWISE = 0;
	static COUNTERCLOCKWISE = 1;
	static DOUBLE_SENSE = 2;
	static INVALID_SENSE = 3;

	static function BuildSignal(tile , rail_track , sense);
	static function RemoveSignal(tile , rail_track , sense);
	static function CanBuildRailOnLand(tile);
	static function CanBuildTrackOnSlope(tile , track);
	static function CanBuildTrackOnCoastSlope(tile , track);
	static function IsRailBlocked(tile , next_tile_offset);
	static function LandToBuildBridgeOver(tile);
	static function IsTrackLevel(tile , track);
}

function RailroadCommon::CanBuildRailOnLand(tile){
	return AIMap.IsValidTile(tile) && AITile.IsBuildable(tile) &&
		!(AITile.GetSlope(tile) == AITile.SLOPE_FLAT &&
		AITile.GetCornerHeight(tile , AITile.CORNER_N) == 0);
}

function RailroadCommon::LandToBuildBridgeOver(tile){
	if(AIMap.IsValidTile(tile) && ((AITile.IsWaterTile(tile) && !AITile.IsCoastTile(tile)) ||
		AITile.HasTransportType(tile , AITile.TRANSPORT_RAIL) ||
		AITile.HasTransportType(tile , AITile.TRANSPORT_ROAD) ||
		AITile.HasTransportType(tile , AITile.TRANSPORT_WATER) ||
		(AITile.GetSlope(tile) == AITile.SLOPE_FLAT &&
		AITile.GetCornerHeight(tile , AITile.CORNER_N) == 0))) return true;
	return false;
}

function RailroadCommon::IsRailBlocked(tile , next_tile_offset , rail_track){
	return (AITile.IsCoastTile(tile) &&
			!RailroadCommon.CanBuildTrackOnCoastSlope(tile , rail_track)) ||
		(!AITile.IsCoastTile(tile) && AIMap.IsValidTile(tile + next_tile_offset) &&
			RailroadCommon.LandToBuildBridgeOver(tile + next_tile_offset));
}

function RailroadCommon::BuildSignal(tile , rail_track , sense , signal_type){
	local front_tile = tile;

	if(sense == RailroadCommon.DOUBLE_SENSE) signal_type = signal_type | AIRail.SIGNALTYPE_TWOWAY;

	switch(rail_track){
		case AIRail.RAILTRACK_NE_SW:
			if(sense == RailroadCommon.CLOCKWISE){
				front_tile += AIMap.GetTileIndex(1 , 0);
			}else{
				front_tile += AIMap.GetTileIndex(-1 , 0);
			}
		break;

		case AIRail.RAILTRACK_NW_SE:
			if(sense == RailroadCommon.CLOCKWISE){
				front_tile += AIMap.GetTileIndex(0 , -1);
			}else{
				front_tile += AIMap.GetTileIndex(0 , 1);
			}
		break;

		case AIRail.RAILTRACK_NW_NE:
			if(sense == RailroadCommon.CLOCKWISE){
				front_tile += AIMap.GetTileIndex(0 , -1);
			}else{
				front_tile += AIMap.GetTileIndex(-1 , 0);
			}
		break;

		case AIRail.RAILTRACK_SW_SE:
			if(sense == RailroadCommon.CLOCKWISE){
				front_tile += AIMap.GetTileIndex(1 , 0);
			}else{
				front_tile += AIMap.GetTileIndex(0 , 1);
			}
		break;

		case AIRail.RAILTRACK_NW_SW:
			if(sense == RailroadCommon.CLOCKWISE){
				front_tile += AIMap.GetTileIndex(0 , -1);
			}else{
				front_tile += AIMap.GetTileIndex(1 , 0);
			}
		break;

		case AIRail.RAILTRACK_NE_SE:
			if(sense == RailroadCommon.CLOCKWISE){
				front_tile += AIMap.GetTileIndex(0 , 1);
			}else{
				front_tile += AIMap.GetTileIndex(-1 , 0);
			}
		break;
	}
	return AIRail.BuildSignal(tile , front_tile , signal_type);
}

function RailroadCommon::RemoveSignal(tile , rail_track , sense){
	local front_tile = tile;

	switch(rail_track){
		case AIRail.RAILTRACK_NE_SW:
			if(sense == RailroadCommon.CLOCKWISE){
				front_tile += AIMap.GetTileIndex(1 , 0);
			}else{
				front_tile += AIMap.GetTileIndex(-1 , 0);
			}
		break;

		case AIRail.RAILTRACK_NW_SE:
			if(sense == RailroadCommon.CLOCKWISE){
				front_tile += AIMap.GetTileIndex(0 , -1);
			}else{
				front_tile += AIMap.GetTileIndex(0 , 1);
			}
		break;

		case AIRail.RAILTRACK_NW_NE:
			if(sense == RailroadCommon.CLOCKWISE){
				front_tile += AIMap.GetTileIndex(0 , -1);
			}else{
				front_tile += AIMap.GetTileIndex(-1 , 0);
			}
		break;

		case AIRail.RAILTRACK_SW_SE:
			if(sense == RailroadCommon.CLOCKWISE){
				front_tile += AIMap.GetTileIndex(1 , 0);
			}else{
				front_tile += AIMap.GetTileIndex(0 , 1);
			}
		break;

		case AIRail.RAILTRACK_NW_SW:
			if(sense == RailroadCommon.CLOCKWISE){
				front_tile += AIMap.GetTileIndex(0 , -1);
			}else{
				front_tile += AIMap.GetTileIndex(1 , 0);
			}
		break;

		case AIRail.RAILTRACK_NE_SE:
			if(sense == RailroadCommon.CLOCKWISE){
				front_tile += AIMap.GetTileIndex(0 , 1);
			}else{
				front_tile += AIMap.GetTileIndex(-1 , 0);
			}
		break;
	}
	if( AIRail.GetSignalType(tile , front_tile) != AIRail.SIGNALTYPE_NONE  )
		return AIRail.RemoveSignal(tile , front_tile);
	else return true;
}

function RailroadCommon::CanBuildTrackOnCoastSlope(tile , track){
	local slope = AITile.GetSlope(tile);
	if(track == AIRail.RAILTRACK_INVALID) return true;

	switch(slope){
		case AITile.SLOPE_NWS:
		case AITile.SLOPE_WSE:
		case AITile.SLOPE_SEN:
		case AITile.SLOPE_ENW:
		case AITile.SLOPE_EW:
		case AITile.SLOPE_NS:
		case AITile.SLOPE_ELEVATED:
		case AITile.SLOPE_FLAT:
			return true;
		break;

		case AITile.SLOPE_S:
			if(track == AIRail.RAILTRACK_SW_SE) return true;
		break;
		case AITile.SLOPE_N:
			if(track == AIRail.RAILTRACK_NW_NE) return true;
		break;
		case AITile.SLOPE_W:
			if(track == AIRail.RAILTRACK_NW_SW) return true;
		break;
		case AITile.SLOPE_E:
			if(track == AIRail.RAILTRACK_NE_SE) return true;
		break;

		case AITile.SLOPE_STEEP_S:
		case AITile.SLOPE_STEEP_N:
			switch(track){
				case AIRail.RAILTRACK_NW_SW:
				case AIRail.RAILTRACK_NE_SE:
					return false;
				default:
					return true;
			}

		case AITile.SLOPE_STEEP_E:
		case AITile.SLOPE_STEEP_W:
			switch(track){
				case AIRail.RAILTRACK_NW_NE:
				case AIRail.RAILTRACK_SW_SE:
					return false;
				default:
					return true;
			}

		case AITile.SLOPE_NW:
			switch(track){
				case AIRail.RAILTRACK_NW_SE:
				case AIRail.RAILTRACK_NE_SE:
				case AIRail.RAILTRACK_SW_SE:
					return false;
				default:
					return true;
			}

		case AITile.SLOPE_SW:
			switch(track){
				case AIRail.RAILTRACK_NE_SW:
				case AIRail.RAILTRACK_NE_SE:
				case AIRail.RAILTRACK_NW_NE:
					return false;
				default:
					return true;
			}

		case AITile.SLOPE_SE:
			switch(track){
				case AIRail.RAILTRACK_NW_SE:
				case AIRail.RAILTRACK_NW_NE:
				case AIRail.RAILTRACK_NW_SW:
					return false;
				default:
					return true;
			}

		case AITile.SLOPE_NE:
			switch(track){
				case AIRail.RAILTRACK_NE_SW:
				case AIRail.RAILTRACK_SW_SE:
				case AIRail.RAILTRACK_NW_SW:
					return false;
				default:
					return true;
			}
	}
	return false;
}

function RailroadCommon::CanBuildTrackOnSlope(tile , track){
	local slope = AITile.GetSlope(tile);

	if(AITile.IsCoastTile(tile)) return RailroadCommon.CanBuildTrackOnCoastSlope(tile , track);
	if(track == AIRail.RAILTRACK_INVALID) return true;

	switch(slope){
		case AITile.SLOPE_NWS:
		case AITile.SLOPE_WSE:
		case AITile.SLOPE_SEN:
		case AITile.SLOPE_ENW:
		case AITile.SLOPE_EW:
		case AITile.SLOPE_NS:
		case AITile.SLOPE_ELEVATED:
		case AITile.SLOPE_FLAT:
			return true;
		break;

		case AITile.SLOPE_STEEP_S:
		case AITile.SLOPE_STEEP_N:
		case AITile.SLOPE_S:
		case AITile.SLOPE_N:
			switch(track){
				case AIRail.RAILTRACK_NW_SW:
				case AIRail.RAILTRACK_NE_SE:
					return false;
				default:
					return true;
			}

		case AITile.SLOPE_STEEP_E:
		case AITile.SLOPE_STEEP_W:
		case AITile.SLOPE_W:
		case AITile.SLOPE_E:
			switch(track){
				case AIRail.RAILTRACK_NW_NE:
				case AIRail.RAILTRACK_SW_SE:
					return false;
				default:
					return true;
			}

		case AITile.SLOPE_NW:
			switch(track){
				case AIRail.RAILTRACK_NE_SE:
				case AIRail.RAILTRACK_SW_SE:
					return false;
				default:
					return true;
			}

		case AITile.SLOPE_SW:
			switch(track){
				case AIRail.RAILTRACK_NE_SE:
				case AIRail.RAILTRACK_NW_NE:
					return false;
				default:
					return true;
			}

		case AITile.SLOPE_SE:
			switch(track){
				case AIRail.RAILTRACK_NW_NE:
				case AIRail.RAILTRACK_NW_SW:
					return false;
				default:
					return true;
			}

		case AITile.SLOPE_NE:
			switch(track){
				case AIRail.RAILTRACK_SW_SE:
				case AIRail.RAILTRACK_NW_SW:
					return false;
				default:
					return true;
			}
	}
	return false;
}

function RailroadCommon::IsTrackLevel(tile , track){
	local slope = AITile.GetSlope(tile);

	if(track != AIRail.RAILTRACK_NE_SW && track != AIRail.RAILTRACK_NW_SE) return true;

	switch(slope){
		case AITile.SLOPE_W:
		case AITile.SLOPE_E:
		case AITile.SLOPE_S:
		case AITile.SLOPE_N:
		case AITile.SLOPE_STEEP_S:
		case AITile.SLOPE_STEEP_N:
		case AITile.SLOPE_STEEP_E:
		case AITile.SLOPE_STEEP_W:
			return false;

		case AITile.SLOPE_EW:
		case AITile.SLOPE_NS:
		case AITile.SLOPE_NWS:
		case AITile.SLOPE_WSE:
		case AITile.SLOPE_SEN:
		case AITile.SLOPE_ENW:
		case AITile.SLOPE_ELEVATED:
		case AITile.SLOPE_FLAT:
			return true;

		case AITile.SLOPE_NE:
		case AITile.SLOPE_SW:
			if(track == AIRail.RAILTRACK_NE_SW) return false;
			else return true;

		case AITile.SLOPE_NW:
		case AITile.SLOPE_SE:
			if(track == AIRail.RAILTRACK_NW_SE) return false;
			else return true;
	}
	assert(false);
}
