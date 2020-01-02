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

class DoubleRailroadStation {
	/* Public: */
	/* All possible positions for PRE_SIGNALED stations. */
	static SOUTH_EAST = 0;
	static SOUTH_WEST = 1;
	static NORTH_EAST = 2;
	static NORTH_WEST = 3;
	static EAST_NORTH = 4;
	static EAST_SOUTH = 5;
	static WEST_NORTH = 6;
	static WEST_SOUTH = 7;

	/* The station types. */
	static PRE_SIGNALED = 0;
	static TERMINUS = 1;

	exit_direction = null;
	exit_part_tile = null;
	exit_part = null;
	land = null;
	n_plataforms = null;
	plataform_length = null;
	station_tile = null;
	station_position = null;
	station_type = null;

	function BuildRailroadStation();
	function ConvertRailroadStation(rail_type);
	function DecideRailroadStationPosition();
	function DemolishRailroadStation();
	function EstimateCostToConvertRailroadStation(rail_type);
	function GetCargoAcceptance(cargo);
	function GetCargoProduction(cargo);
	function GetRailroadStationTracksCost(track_base_cost , signal_base_cost);

	/* Private: */
	static function BuildRailTrack(tile , rail_track , unused);
	static function BuildRailSignal(tile , rail_track , unused);
	static function DemolishRailTrack(tile , rail_track , unused);
	static function DummyRailSignal(unused1 , unused2 , unused3 , unused4 , unused5);
	static function ConvertRailTrack(tile , unused , rail_type);
	static function GetRailTrackCost(unused1 , unused2 , tracks_cost);
	static function GetRailSignalCost(unused1 , unused2 , unused3 , unused4 , signals_cost);

	function IterateOverTracksOfTerminusStation(track_callback , track_callback_param ,
		signal_callback , signal_callback_param);
	function IterateOverTracksOfPreSignaledStation(track_callback , track_callback_param ,
		signal_callback , signal_callback_param);
}

function DoubleRailroadStation::GetCargoAcceptance(cargo){
	return AITile.GetCargoAcceptance(station_tile , cargo , (land.swaped_w_h ? plataform_length : n_plataforms) ,
			(land.swaped_w_h ? n_plataforms : plataform_length) , AIStation.GetCoverageRadius(AIStation.STATION_TRAIN));
}

function DoubleRailroadStation::GetCargoProduction(cargo){
	return AITile.GetCargoProduction(station_tile , cargo , (land.swaped_w_h ? plataform_length : n_plataforms) ,
			(land.swaped_w_h ? n_plataforms : plataform_length) , AIStation.GetCoverageRadius(AIStation.STATION_TRAIN));
}

function DoubleRailroadStation::EstimateCostToConvertRailroadStation(rail_type){
	local ai_test_mode = AITestMode();
	local cost =  AIAccounting();

	ConvertRailroadStation(rail_type);
	return cost.GetCosts();
}

function DoubleRailroadStation::GetRailroadStationTracksCost(track_base_cost , signal_base_cost){
	local tracks_cost = Pair(0 , track_base_cost);
	local signals_cost = Pair(0 , signal_base_cost);

	switch(station_type){
		case DoubleRailroadStation.PRE_SIGNALED:
			IterateOverTracksOfPreSignaledStation(DoubleRailroadStation.GetRailTrackCost , tracks_cost ,
				DoubleRailroadStation.GetRailSignalCost , signals_cost);
		break;
		case DoubleRailroadStation.TERMINUS:
			IterateOverTracksOfTerminusStation(DoubleRailroadStation.GetRailTrackCost , tracks_cost ,
				DoubleRailroadStation.GetRailSignalCost , signals_cost);
		break;
	}

	return tracks_cost.first + signals_cost.first;
}


function DoubleRailroadStation::DecideRailroadStationPosition(main_exit_direction ,
	secondary_exit_direction , target_tile){
	local exit_directions = array(0);

	exit_direction = Direction.INVALID_DIRECTION;

	/* The tracks will be parallel to X axis. */
	if(land.swaped_w_h){
		if(main_exit_direction == Direction.WEST || secondary_exit_direction == Direction.WEST){
			exit_directions.push(Direction.WEST);
			exit_directions.push(Direction.EAST);
		}else{
			exit_directions.push(Direction.EAST);
			exit_directions.push(Direction.WEST);
		}
	/* The tracks will be parallel to Y axis. */
	}else{
		if(main_exit_direction == Direction.SOUTH || secondary_exit_direction == Direction.SOUTH){
			exit_directions.push(Direction.SOUTH);
			exit_directions.push(Direction.NORTH);
		}else{
			exit_directions.push(Direction.NORTH);
			exit_directions.push(Direction.SOUTH);
		}
	}

	switch(station_type){
		case DoubleRailroadStation.PRE_SIGNALED:
			foreach(direction in exit_directions){
				exit_part_tile = land.t[0];
				station_tile = land.t[0];

				switch(direction){
					/* The exit will point to WEST. */
					case Direction.WEST:
						station_tile += AIMap.GetTileIndex(5 , 0);
						if(AIMap.GetTileY(target_tile) > AIMap.GetTileY(land.t[0])){
							station_tile += AIMap.GetTileIndex(0 , 2);
							station_position = DoubleRailroadStation.WEST_NORTH;
							exit_part_tile += AIMap.GetTileIndex(3 , 2);
						}else{
							station_position = DoubleRailroadStation.WEST_SOUTH;
							exit_part_tile += AIMap.GetTileIndex(3 , n_plataforms);
						}
						exit_part = DoubleTrackParts.EW_LINE;
						exit_direction = Direction.WEST;
					break;

					/* The exit will point to EAST. */
					case Direction.EAST:
						station_tile += AIMap.GetTileIndex(2 , 0);
						if(AIMap.GetTileY(target_tile) > AIMap.GetTileY(land.t[0])){
							station_tile += AIMap.GetTileIndex(0 , 2);
							station_position = DoubleRailroadStation.EAST_NORTH;
							exit_part_tile += AIMap.GetTileIndex(plataform_length + 4 , 2);
						}else{
							station_position = DoubleRailroadStation.EAST_SOUTH;
							exit_part_tile += AIMap.GetTileIndex(plataform_length + 4 ,
								n_plataforms);
						}
						exit_part = DoubleTrackParts.WE_LINE;
						exit_direction = Direction.EAST;
					break;

					/* The exit will point to SOUTH. */
					case Direction.SOUTH:
						station_tile += AIMap.GetTileIndex(0 , 5);
						if(AIMap.GetTileX(target_tile) > AIMap.GetTileX(land.t[0])){
							station_tile += AIMap.GetTileIndex(2 , 0);
							station_position = DoubleRailroadStation.SOUTH_EAST;
							exit_part_tile += AIMap.GetTileIndex(2 , 3);
						}else{
							station_position = DoubleRailroadStation.SOUTH_WEST;
							exit_part_tile += AIMap.GetTileIndex(n_plataforms , 3);
						}
						exit_part = DoubleTrackParts.NS_LINE;
						exit_direction = Direction.SOUTH;
					break;

					/* The exit will point to NORTH. */
					case Direction.NORTH:
						station_tile += AIMap.GetTileIndex(0 , 2);
						if(AIMap.GetTileX(target_tile) > AIMap.GetTileX(land.t[0])){
							station_tile += AIMap.GetTileIndex(2 , 0);
							station_position = DoubleRailroadStation.NORTH_EAST;
							exit_part_tile += AIMap.GetTileIndex(2 , plataform_length + 4);
						}else{
							station_position = DoubleRailroadStation.NORTH_WEST;
							exit_part_tile += AIMap.GetTileIndex(n_plataforms ,
								plataform_length + 4);
						}
						exit_part = DoubleTrackParts.SN_LINE;
						exit_direction = Direction.NORTH;
					break;
				}
				if(exit_direction != Direction.INVALID_DIRECTION) break;
			}
		break;
		case DoubleRailroadStation.TERMINUS:
			foreach(direction in exit_directions){
				exit_part_tile = land.t[0];
				station_tile = land.t[0];

				switch(direction){
					/* The exit will point to NORTH. */
					case Direction.NORTH:
						exit_part_tile += AIMap.GetTileIndex(1 , plataform_length + 2);
						exit_part = DoubleTrackParts.SN_LINE;
						exit_direction = Direction.NORTH;
						station_position = Direction.NORTH;
					break;

					/* The exit will point to SOUTH. */
					case Direction.SOUTH:
						station_tile += AIMap.GetTileIndex(0 , 5);
						exit_part_tile += AIMap.GetTileIndex(1 , 3);
						exit_part = DoubleTrackParts.NS_LINE;
						exit_direction = Direction.SOUTH;
						station_position = Direction.SOUTH;
					break;

					/* The exit will point to EAST. */
					case Direction.EAST:
						exit_part_tile += AIMap.GetTileIndex(plataform_length + 2 , 1);
						exit_part = DoubleTrackParts.WE_LINE;
						exit_direction = Direction.EAST;
						station_position = Direction.EAST;
					break;

					/* The exit will point to WEST. */
					case Direction.WEST:
						station_tile += AIMap.GetTileIndex(5 , 0);
						exit_part_tile += AIMap.GetTileIndex(3 , 1);
						exit_part = DoubleTrackParts.EW_LINE;
						exit_direction = Direction.WEST;
						station_position = Direction.WEST;
					break;
				}
				if(exit_direction != Direction.INVALID_DIRECTION) break;
			}
		break;
	}
	assert(exit_direction != null && exit_part_tile != null && exit_part != null &&
		station_tile != null && station_position != null && station_type != null);
}

function DoubleRailroadStation::ConvertRailTrack(tile , unused , rail_type){
	AIRail.ConvertRailType(tile , tile , rail_type);
	return true;
}

function DoubleRailroadStation::DemolishRailTrack(tile , rail_track , unused){
	AIRail.RemoveRailTrack(tile , rail_track);
	return true;
}

function DoubleRailroadStation::DummyRailSignal(unused1 , unused2 , unused3 , unused4 , unused5){
	return true;
}

function DoubleRailroadStation::GetRailTrackCost(unused1 , unused2 , tracks_cost){
	tracks_cost.first += tracks_cost.second;
	return true;
}

function DoubleRailroadStation::GetRailSignalCost(unused1 , unused2 , unused3 , unused4 , signals_cost){
	signals_cost.first += signals_cost.second;
	return true;
}

function DoubleRailroadStation::BuildRailTrack(tile , rail_track , unused){
	return AIRail.BuildRailTrack(tile , rail_track);
}

function DoubleRailroadStation::BuildRailSignal(tile , rail_track , sense , signal_type , unused){
	return RailroadCommon.BuildSignal(tile , rail_track , sense , signal_type);
}

function DoubleRailroadStation::IterateOverTracksOfTerminusStation(track_callback , track_callback_param ,
	signal_callback , signal_callback_param){

	if(typeof(track_callback) != "function")
		throw("'track_callback' has to be a function-pointer.");
	if(typeof(signal_callback) != "function")
		throw("'signal_callback' has to be a function-pointer.");

	local t0 = land.t[0];

	switch(station_position){
		case Direction.NORTH:
			for(local i = 0 ; i < n_plataforms ; i++){
				if(!track_callback(t0 + AIMap.GetTileIndex(i , plataform_length) ,
					AIRail.RAILTRACK_NW_SE , track_callback_param)) return false;
				if(!signal_callback(t0 + AIMap.GetTileIndex(i , plataform_length) ,
					AIRail.RAILTRACK_NW_SE , RailroadCommon.DOUBLE_SENSE , AIRail.SIGNALTYPE_EXIT ,
						signal_callback_param)) return false;
			}

			if(!track_callback(t0 + AIMap.GetTileIndex(0 , plataform_length + 2) ,
				AIRail.RAILTRACK_NW_SE , track_callback_param)) return false;
			if(!track_callback(t0 + AIMap.GetTileIndex(1 , plataform_length + 2) ,
				AIRail.RAILTRACK_NW_SE , track_callback_param)) return false;
			if(!signal_callback(t0 + AIMap.GetTileIndex(0 , plataform_length + 2) ,
				AIRail.RAILTRACK_NW_SE , RailroadCommon.CLOCKWISE , AIRail.SIGNALTYPE_NORMAL ,
					signal_callback_param)) return false;
			if(!signal_callback(t0 + AIMap.GetTileIndex(1 , plataform_length + 2) ,
				AIRail.RAILTRACK_NW_SE , RailroadCommon.COUNTERCLOCKWISE , AIRail.SIGNALTYPE_ENTRY ,
					signal_callback_param)) return false;

			if(!track_callback(t0 + AIMap.GetTileIndex(0 , plataform_length + 1) ,
				AIRail.RAILTRACK_NW_SE , track_callback_param)) return false;
			if(!track_callback(t0 + AIMap.GetTileIndex(0 , plataform_length + 1) ,
				AIRail.RAILTRACK_NW_SW , track_callback_param)) return false;
			if(!track_callback(t0 + AIMap.GetTileIndex(0 , plataform_length + 1) ,
				AIRail.RAILTRACK_SW_SE , track_callback_param)) return false;
			if(!track_callback(t0 + AIMap.GetTileIndex(1 , plataform_length + 1) ,
				AIRail.RAILTRACK_NW_SE , track_callback_param)) return false;
			if(!track_callback(t0 + AIMap.GetTileIndex(1 , plataform_length + 1) ,
				AIRail.RAILTRACK_NE_SE , track_callback_param)) return false;
			for(local i = 1 ; i < (n_plataforms - 1) ; i++){
				if(i == 1)
					if(!track_callback(t0 + AIMap.GetTileIndex(1 , plataform_length + 1) ,
						AIRail.RAILTRACK_SW_SE , track_callback_param)) return false;
				if(!track_callback(t0 + AIMap.GetTileIndex(i , plataform_length + 1) ,
					AIRail.RAILTRACK_NE_SW , track_callback_param)) return false;
			}
			for(local i = 1 ; i < n_plataforms ; i++){
				if(!track_callback(t0 + AIMap.GetTileIndex(i , plataform_length + 1) ,
					AIRail.RAILTRACK_NW_NE , track_callback_param)) return false;
			}
		break;

		case Direction.SOUTH:
			for(local i = 0 ; i < n_plataforms ; i++){
				if(!track_callback(t0 + AIMap.GetTileIndex(i , 4) ,
					AIRail.RAILTRACK_NW_SE , track_callback_param)) return false;
				if(!signal_callback(t0 + AIMap.GetTileIndex(i , 4) ,
					AIRail.RAILTRACK_NW_SE , RailroadCommon.DOUBLE_SENSE , AIRail.SIGNALTYPE_EXIT ,
						signal_callback_param)) return false;
			}

			if(!track_callback(t0 + AIMap.GetTileIndex(0 , 2) ,
				AIRail.RAILTRACK_NW_SE , track_callback_param)) return false;
			if(!track_callback(t0 + AIMap.GetTileIndex(1 , 2) ,
				AIRail.RAILTRACK_NW_SE , track_callback_param)) return false;
			if(!signal_callback(t0 + AIMap.GetTileIndex(0 , 2) ,
				AIRail.RAILTRACK_NW_SE , RailroadCommon.CLOCKWISE , AIRail.SIGNALTYPE_ENTRY ,
					signal_callback_param)) return false;
			if(!signal_callback(t0 + AIMap.GetTileIndex(1 , 2) ,
				AIRail.RAILTRACK_NW_SE , RailroadCommon.COUNTERCLOCKWISE , AIRail.SIGNALTYPE_NORMAL ,
					signal_callback_param)) return false;

			if(!track_callback(t0 + AIMap.GetTileIndex(0 , 3) ,
				AIRail.RAILTRACK_NW_SE , track_callback_param)) return false;
			if(!track_callback(t0 + AIMap.GetTileIndex(0 , 3) ,
				AIRail.RAILTRACK_NW_SW , track_callback_param)) return false;
			if(!track_callback(t0 + AIMap.GetTileIndex(0 , 3) ,
				AIRail.RAILTRACK_SW_SE , track_callback_param)) return false;
			if(!track_callback(t0 + AIMap.GetTileIndex(1 , 3) ,
				AIRail.RAILTRACK_NW_SE , track_callback_param)) return false;
			if(!track_callback(t0 + AIMap.GetTileIndex(1 , 3) ,
				AIRail.RAILTRACK_NW_NE , track_callback_param)) return false;
			for(local i = 1 ; i < (n_plataforms - 1) ; i++){
				if(i == 1)
					if(!track_callback(t0 + AIMap.GetTileIndex(1 , 3) ,
						AIRail.RAILTRACK_NW_SW , track_callback_param)) return false;
				if(!track_callback(t0 + AIMap.GetTileIndex(i , 3) ,
					AIRail.RAILTRACK_NE_SW , track_callback_param)) return false;
			}
			for(local i = 1 ; i < n_plataforms ; i++){
				if(!track_callback(t0 + AIMap.GetTileIndex(i , 3) ,
					AIRail.RAILTRACK_NE_SE , track_callback_param)) return false;
			}
		break;

		case Direction.WEST:
			for(local i = 0 ; i < n_plataforms ; i++){
				if(!track_callback(t0 + AIMap.GetTileIndex(4 , i) ,
					AIRail.RAILTRACK_NE_SW , track_callback_param)) return false;
				if(!signal_callback(t0 + AIMap.GetTileIndex(4 , i) ,
					AIRail.RAILTRACK_NE_SW , RailroadCommon.DOUBLE_SENSE , AIRail.SIGNALTYPE_EXIT ,
						signal_callback_param)) return false;
			}

			if(!track_callback(t0 + AIMap.GetTileIndex(2 , 0) ,
				AIRail.RAILTRACK_NE_SW , track_callback_param)) return false;
			if(!track_callback(t0 + AIMap.GetTileIndex(2 , 1) ,
				AIRail.RAILTRACK_NE_SW , track_callback_param)) return false;
			if(!signal_callback(t0 + AIMap.GetTileIndex(2 , 0) ,
				AIRail.RAILTRACK_NE_SW , RailroadCommon.CLOCKWISE , AIRail.SIGNALTYPE_NORMAL ,
					signal_callback_param)) return false;
			if(!signal_callback(t0 + AIMap.GetTileIndex(2 , 1) ,
				AIRail.RAILTRACK_NE_SW , RailroadCommon.COUNTERCLOCKWISE , AIRail.SIGNALTYPE_ENTRY ,
					signal_callback_param)) return false;

			if(!track_callback(t0 + AIMap.GetTileIndex(3 , 0) ,
				AIRail.RAILTRACK_NE_SW , track_callback_param)) return false;
			if(!track_callback(t0 + AIMap.GetTileIndex(3 , 0) ,
				AIRail.RAILTRACK_NE_SE , track_callback_param)) return false;
			if(!track_callback(t0 + AIMap.GetTileIndex(3 , 0) ,
				AIRail.RAILTRACK_SW_SE , track_callback_param)) return false;
			if(!track_callback(t0 + AIMap.GetTileIndex(3 , 1) ,
				AIRail.RAILTRACK_NE_SW , track_callback_param)) return false;
			if(!track_callback(t0 + AIMap.GetTileIndex(3 , 1) ,
				AIRail.RAILTRACK_NW_NE , track_callback_param)) return false;
			for(local i = 1 ; i < (n_plataforms - 1) ; i++){
				if(i == 1)
					if(!track_callback(t0 + AIMap.GetTileIndex(3 , 1) ,
						AIRail.RAILTRACK_NE_SE , track_callback_param)) return false;
				if(!track_callback(t0 + AIMap.GetTileIndex(3 , i) ,
					AIRail.RAILTRACK_NW_SE , track_callback_param)) return false;
			}
			for(local i = 1 ; i < n_plataforms ; i++){
				if(!track_callback(t0 + AIMap.GetTileIndex(3 , i) ,
					AIRail.RAILTRACK_NW_SW , track_callback_param)) return false;
			}
		break;

		case Direction.EAST:
			for(local i = 0 ; i < n_plataforms ; i++){
				if(!track_callback(t0 + AIMap.GetTileIndex(plataform_length , i) ,
					AIRail.RAILTRACK_NE_SW , track_callback_param)) return false;
				if(!signal_callback(t0 + AIMap.GetTileIndex(plataform_length , i) ,
					AIRail.RAILTRACK_NE_SW , RailroadCommon.DOUBLE_SENSE , AIRail.SIGNALTYPE_EXIT ,
						signal_callback_param)) return false;
			}

			if(!track_callback(t0 + AIMap.GetTileIndex(2 + plataform_length , 0) ,
				AIRail.RAILTRACK_NE_SW , track_callback_param)) return false;
			if(!track_callback(t0 + AIMap.GetTileIndex(2 + plataform_length , 1) ,
				AIRail.RAILTRACK_NE_SW , track_callback_param)) return false;
			if(!signal_callback(t0 + AIMap.GetTileIndex(2 + plataform_length , 0) ,
				AIRail.RAILTRACK_NE_SW , RailroadCommon.CLOCKWISE , AIRail.SIGNALTYPE_ENTRY ,
					signal_callback_param)) return false;
			if(!signal_callback(t0 + AIMap.GetTileIndex(2 + plataform_length , 1) ,
				AIRail.RAILTRACK_NE_SW , RailroadCommon.COUNTERCLOCKWISE , AIRail.SIGNALTYPE_NORMAL ,
					signal_callback_param)) return false;

			if(!track_callback(t0 + AIMap.GetTileIndex(1 + plataform_length , 0) ,
				AIRail.RAILTRACK_NE_SW , track_callback_param)) return false;
			if(!track_callback(t0 + AIMap.GetTileIndex(1 + plataform_length , 0) ,
				AIRail.RAILTRACK_NE_SE , track_callback_param)) return false;
			if(!track_callback(t0 + AIMap.GetTileIndex(1 + plataform_length , 0) ,

				AIRail.RAILTRACK_SW_SE , track_callback_param)) return false;
			if(!track_callback(t0 + AIMap.GetTileIndex(1 + plataform_length , 1) ,
				AIRail.RAILTRACK_NE_SW , track_callback_param)) return false;
			if(!track_callback(t0 + AIMap.GetTileIndex(1 + plataform_length , 1) ,
				AIRail.RAILTRACK_NW_SW , track_callback_param)) return false;
			for(local i = 1 ; i < (n_plataforms - 1) ; i++){
				if(i == 1)
					if(!track_callback(t0 + AIMap.GetTileIndex(1 + plataform_length , 1) ,
						AIRail.RAILTRACK_SW_SE , track_callback_param)) return false;
				if(!track_callback(t0 + AIMap.GetTileIndex(1 + plataform_length , i) ,
					AIRail.RAILTRACK_NW_SE , track_callback_param)) return false;
			}
			for(local i = 1 ; i < n_plataforms ; i++){
				if(!track_callback(t0 + AIMap.GetTileIndex(1 + plataform_length , i) ,
					AIRail.RAILTRACK_NW_NE , track_callback_param)) return false;
			}
		break;
	}

	return true;
}

function DoubleRailroadStation::IterateOverTracksOfPreSignaledStation(track_callback , track_callback_param ,
	signal_callback , signal_callback_param){

	if(typeof(track_callback) != "function")
		throw("'track_callback' has to be a function-pointer.");
	if(typeof(signal_callback) != "function")
		throw("'signal_callback' has to be a function-pointer.");

	local t0 = land.t[0];

	switch(station_position){
		case DoubleRailroadStation.SOUTH_WEST:
			for(local i = 1 ; i <= n_plataforms ; i++)
				if(!track_callback(t0 + AIMap.GetTileIndex(i , plataform_length + 6) ,
					AIRail.RAILTRACK_NE_SW , track_callback_param)) return false;
			if(!track_callback(t0 + AIMap.GetTileIndex(1 + n_plataforms , plataform_length + 6) ,
				AIRail.RAILTRACK_NW_NE , track_callback_param)) return false;
			if(!track_callback(t0 + AIMap.GetTileIndex(1 + n_plataforms , plataform_length + 5) ,
				AIRail.RAILTRACK_NW_SE , track_callback_param)) return false;
			if(!track_callback(t0 + AIMap.GetTileIndex(1 + n_plataforms , plataform_length + 4) ,
				AIRail.RAILTRACK_NE_SE , track_callback_param)) return false;
			if(!track_callback(t0 + AIMap.GetTileIndex(n_plataforms , plataform_length + 4) ,
				AIRail.RAILTRACK_NW_SW , track_callback_param)) return false;

			for(local i = 2 ; i <= plataform_length + 3 ; i++){
				if(!track_callback(t0 + AIMap.GetTileIndex(n_plataforms , i) ,
					AIRail.RAILTRACK_NW_SE , track_callback_param)) return false;
				if(!signal_callback(t0 + AIMap.GetTileIndex(n_plataforms , i) ,
					AIRail.RAILTRACK_NW_SE , RailroadCommon.COUNTERCLOCKWISE , AIRail.SIGNALTYPE_NORMAL ,
						signal_callback_param)) return false;
			}

			for(local i = 0 ; i < n_plataforms ; i++){
				if(!track_callback(t0 + AIMap.GetTileIndex(i , 4) ,
					AIRail.RAILTRACK_NW_SE , track_callback_param)) return false;
				if(!signal_callback(t0 + AIMap.GetTileIndex(i , 4) , AIRail.RAILTRACK_NW_SE ,
					RailroadCommon.CLOCKWISE , AIRail.SIGNALTYPE_EXIT , signal_callback_param)) return false;
				if(i < n_plataforms - 1)
					if(!track_callback(t0 + AIMap.GetTileIndex(i , 3) ,
						AIRail.RAILTRACK_SW_SE , track_callback_param)) return false;
				if(i > 0 && i < n_plataforms - 1)
					if(!track_callback(t0 + AIMap.GetTileIndex(i , 3) ,
						AIRail.RAILTRACK_NE_SW , track_callback_param)) return false;
				if(!track_callback(t0 + AIMap.GetTileIndex(i , 5 + plataform_length) ,
					AIRail.RAILTRACK_NW_SE , track_callback_param)) return false;
				if(!signal_callback(t0 + AIMap.GetTileIndex(i , 5 + plataform_length) ,
					AIRail.RAILTRACK_NW_SE , RailroadCommon.CLOCKWISE , AIRail.SIGNALTYPE_NORMAL ,
						signal_callback_param)) return false;
				if(!track_callback(t0 + AIMap.GetTileIndex(i , 6 + plataform_length) ,
					AIRail.RAILTRACK_NW_SW , track_callback_param)) return false;
			}

			if(n_plataforms > 1)
				if(!track_callback(t0 + AIMap.GetTileIndex(n_plataforms - 1 , 3) ,
					AIRail.RAILTRACK_NW_NE , track_callback_param)) return false;

			if(!track_callback(t0 + AIMap.GetTileIndex(n_plataforms - 1 , 2) ,
				AIRail.RAILTRACK_NW_SE , track_callback_param)) return false;
			if(!track_callback(t0 + AIMap.GetTileIndex(n_plataforms - 1 , 3) ,
				AIRail.RAILTRACK_NW_SE , track_callback_param)) return false;

			if(!signal_callback(t0 + AIMap.GetTileIndex(1 + n_plataforms , plataform_length + 5 ) ,
				AIRail.RAILTRACK_NW_SE , RailroadCommon.COUNTERCLOCKWISE , AIRail.SIGNALTYPE_NORMAL ,
					signal_callback_param)) return false;
			if(!signal_callback(t0 + AIMap.GetTileIndex(n_plataforms - 1 , 2) ,
				AIRail.RAILTRACK_NW_SE , RailroadCommon.CLOCKWISE , AIRail.SIGNALTYPE_ENTRY ,
					signal_callback_param)) return false;

		break;

		case DoubleRailroadStation.SOUTH_EAST:
			for(local i = 1 ; i <= n_plataforms ; i++)
				if(!track_callback(t0 + AIMap.GetTileIndex(i , plataform_length + 6) ,
					AIRail.RAILTRACK_NE_SW , track_callback_param)) return false;
			if(!track_callback(t0 + AIMap.GetTileIndex(0 , plataform_length + 6) ,
				AIRail.RAILTRACK_NW_SW , track_callback_param)) return false;
			if(!track_callback(t0 + AIMap.GetTileIndex(0 , plataform_length + 5) ,
				AIRail.RAILTRACK_NW_SE , track_callback_param)) return false;
			if(!track_callback(t0 + AIMap.GetTileIndex(0 , plataform_length + 4) ,
				AIRail.RAILTRACK_SW_SE , track_callback_param)) return false;
			if(!track_callback(t0 + AIMap.GetTileIndex(1 , plataform_length + 4) ,
				AIRail.RAILTRACK_NW_NE , track_callback_param)) return false;

			for(local i = 2 ; i <= plataform_length + 3 ; i++){
				if(!track_callback(t0 + AIMap.GetTileIndex(1 , i) ,
					AIRail.RAILTRACK_NW_SE , track_callback_param)) return false;
				if(!signal_callback(t0 + AIMap.GetTileIndex(1 , i) , AIRail.RAILTRACK_NW_SE ,
					RailroadCommon.CLOCKWISE , AIRail.SIGNALTYPE_NORMAL , signal_callback_param)) return false;
			}

			for(local i = 0 ; i < n_plataforms ; i++){
				if(!track_callback(t0 + AIMap.GetTileIndex(2 + i , 4) ,
					AIRail.RAILTRACK_NW_SE , track_callback_param)) return false;
				if(!signal_callback(t0 + AIMap.GetTileIndex(2 + i , 4) , AIRail.RAILTRACK_NW_SE ,
					RailroadCommon.COUNTERCLOCKWISE , AIRail.SIGNALTYPE_NORMAL , signal_callback_param)) return false;
				if(i > 0)
					if(!track_callback(t0 + AIMap.GetTileIndex(2 + i , 3) ,
						AIRail.RAILTRACK_NE_SE , track_callback_param)) return false;
				if(i > 1)
					if(!track_callback(t0 + AIMap.GetTileIndex(1 + i , 3) ,
						AIRail.RAILTRACK_NE_SW , track_callback_param)) return false;
				if(!track_callback(t0 + AIMap.GetTileIndex(2 + i , 5 + plataform_length) ,
					AIRail.RAILTRACK_NW_SE , track_callback_param)) return false;
				if(!signal_callback(t0 + AIMap.GetTileIndex(2 + i , 5 + plataform_length) ,
					AIRail.RAILTRACK_NW_SE , RailroadCommon.COUNTERCLOCKWISE , AIRail.SIGNALTYPE_EXIT ,
						signal_callback_param)) return false;
				if(!track_callback(t0 + AIMap.GetTileIndex(2 + i , 6 + plataform_length) ,
					AIRail.RAILTRACK_NW_NE , track_callback_param)) return false;
			}

			if(n_plataforms > 1)
				if(!track_callback(t0 + AIMap.GetTileIndex(2 , 3) ,
					AIRail.RAILTRACK_NW_SW , track_callback_param)) return false;

			if(!track_callback(t0 + AIMap.GetTileIndex(2 , 2) ,
				AIRail.RAILTRACK_NW_SE , track_callback_param)) return false;
			if(!track_callback(t0 + AIMap.GetTileIndex(2 , 3) ,
				AIRail.RAILTRACK_NW_SE , track_callback_param)) return false;

			if(!signal_callback(t0 + AIMap.GetTileIndex(2 , 2) , AIRail.RAILTRACK_NW_SE ,
				RailroadCommon.COUNTERCLOCKWISE , AIRail.SIGNALTYPE_NORMAL , signal_callback_param)) return false;
			if(!signal_callback(t0 + AIMap.GetTileIndex(0 , plataform_length + 5) ,
				AIRail.RAILTRACK_NW_SE , RailroadCommon.CLOCKWISE , AIRail.SIGNALTYPE_ENTRY ,
					signal_callback_param)) return false;
		break;

		case DoubleRailroadStation.NORTH_EAST:
			for(local i = 1 ; i <= n_plataforms ; i++)
				if(!track_callback(t0 + AIMap.GetTileIndex(i , 0) ,
					AIRail.RAILTRACK_NE_SW , track_callback_param)) return false;
			if(!track_callback(t0 + AIMap.GetTileIndex(0 , 0) ,
				AIRail.RAILTRACK_SW_SE , track_callback_param)) return false;
			if(!track_callback(t0 + AIMap.GetTileIndex(0 , 1) ,
				AIRail.RAILTRACK_NW_SE , track_callback_param)) return false;
			if(!track_callback(t0 + AIMap.GetTileIndex(0 , 2) ,
				AIRail.RAILTRACK_NW_SW , track_callback_param)) return false;
			if(!track_callback(t0 + AIMap.GetTileIndex(1 , 2) ,
				AIRail.RAILTRACK_NE_SE , track_callback_param)) return false;

			for(local i = 3 ; i <= plataform_length + 4 ; i++){
				if(!track_callback(t0 + AIMap.GetTileIndex(1 , i) ,
					AIRail.RAILTRACK_NW_SE , track_callback_param)) return false;
				if(!signal_callback(t0 + AIMap.GetTileIndex(1 , i) , AIRail.RAILTRACK_NW_SE ,
					RailroadCommon.CLOCKWISE , AIRail.SIGNALTYPE_NORMAL , signal_callback_param)) return false;
			}

			for(local i = 0 ; i < n_plataforms ; i++){
				if(!track_callback(t0 + AIMap.GetTileIndex(2 + i , 1) ,
					AIRail.RAILTRACK_NW_SE , track_callback_param)) return false;
				if(!signal_callback(t0 + AIMap.GetTileIndex(2 + i , 1) , AIRail.RAILTRACK_NW_SE ,
					RailroadCommon.COUNTERCLOCKWISE , AIRail.SIGNALTYPE_NORMAL , signal_callback_param)) return false;
				if(i > 0)
					if(!track_callback(t0 + AIMap.GetTileIndex(2 + i , 3 + plataform_length) ,
						AIRail.RAILTRACK_NW_NE , track_callback_param)) return false;
				if(i > 0 && i < n_plataforms - 1 )
					if(!track_callback(t0 + AIMap.GetTileIndex(2 + i , 3 + plataform_length) ,
						AIRail.RAILTRACK_NE_SW , track_callback_param)) return false;
				if(!track_callback(t0 + AIMap.GetTileIndex(2 + i , 2 + plataform_length) ,
					AIRail.RAILTRACK_NW_SE , track_callback_param)) return false;
				if(!signal_callback(t0 + AIMap.GetTileIndex(2 + i , 2 + plataform_length) ,
					AIRail.RAILTRACK_NW_SE , RailroadCommon.COUNTERCLOCKWISE , AIRail.SIGNALTYPE_EXIT ,
						signal_callback_param)) return false;
				if(!track_callback(t0 + AIMap.GetTileIndex(2 + i , 0) ,
					AIRail.RAILTRACK_NE_SE , track_callback_param)) return false;
			}

			if(n_plataforms > 1)
				if(!track_callback(t0 + AIMap.GetTileIndex(2 , 3 + plataform_length) ,
					AIRail.RAILTRACK_SW_SE , track_callback_param)) return false;

			if(!track_callback(t0 + AIMap.GetTileIndex(2 , 3 + plataform_length) ,
				AIRail.RAILTRACK_NW_SE , track_callback_param)) return false;
			if(!track_callback(t0 + AIMap.GetTileIndex(2 , 4 + plataform_length) ,
				AIRail.RAILTRACK_NW_SE , track_callback_param)) return false;

			if(!signal_callback(t0 + AIMap.GetTileIndex(0 , 1) , AIRail.RAILTRACK_NW_SE ,
				RailroadCommon.CLOCKWISE , AIRail.SIGNALTYPE_NORMAL , signal_callback_param)) return false;
			if(!signal_callback(t0 + AIMap.GetTileIndex(2 , 4 + plataform_length) ,
				AIRail.RAILTRACK_NW_SE , RailroadCommon.COUNTERCLOCKWISE , AIRail.SIGNALTYPE_ENTRY ,
					signal_callback_param)) return false;
		break;

		case DoubleRailroadStation.NORTH_WEST:
			for(local i = 1 ; i <= n_plataforms ; i++)
				if(!track_callback(t0 + AIMap.GetTileIndex(i , 0) ,
					AIRail.RAILTRACK_NE_SW , track_callback_param)) return false;
			if(!track_callback(t0 + AIMap.GetTileIndex(n_plataforms + 1 , 0) ,
				AIRail.RAILTRACK_NE_SE , track_callback_param)) return false;
			if(!track_callback(t0 + AIMap.GetTileIndex(n_plataforms + 1 , 1) ,
				AIRail.RAILTRACK_NW_SE , track_callback_param)) return false;
			if(!track_callback(t0 + AIMap.GetTileIndex(n_plataforms + 1 , 2) ,
				AIRail.RAILTRACK_NW_NE , track_callback_param)) return false;
			if(!track_callback(t0 + AIMap.GetTileIndex(n_plataforms , 2) ,
				AIRail.RAILTRACK_SW_SE , track_callback_param)) return false;

			for(local i = 3 ; i <= plataform_length + 4 ; i++){
				if(!track_callback(t0 + AIMap.GetTileIndex(n_plataforms , i) ,
					AIRail.RAILTRACK_NW_SE , track_callback_param)) return false;
				if(!signal_callback(t0 + AIMap.GetTileIndex(n_plataforms , i) , AIRail.RAILTRACK_NW_SE ,
					RailroadCommon.COUNTERCLOCKWISE , AIRail.SIGNALTYPE_NORMAL , signal_callback_param)) return false;
			}

			for(local i = 0 ; i < n_plataforms ; i++){
				if(!track_callback(t0 + AIMap.GetTileIndex(i , 1) ,
					AIRail.RAILTRACK_NW_SE , track_callback_param)) return false;
				if(!signal_callback(t0 + AIMap.GetTileIndex(i , 1) , AIRail.RAILTRACK_NW_SE ,
					RailroadCommon.CLOCKWISE , AIRail.SIGNALTYPE_EXIT , signal_callback_param)) return false;
				if(i < n_plataforms - 1)
					if(!track_callback(t0 + AIMap.GetTileIndex(i , 3 + plataform_length) ,
						AIRail.RAILTRACK_NW_SW , track_callback_param)) return false;
				if(i > 0 && i < n_plataforms - 1 )
					if(!track_callback(t0 + AIMap.GetTileIndex(i , 3 + plataform_length) ,
						AIRail.RAILTRACK_NE_SW , track_callback_param)) return false;
				if(!track_callback(t0 + AIMap.GetTileIndex(i , 2 + plataform_length) ,
					AIRail.RAILTRACK_NW_SE , track_callback_param)) return false;
				if(!signal_callback(t0 + AIMap.GetTileIndex(i , 2 + plataform_length) ,
					AIRail.RAILTRACK_NW_SE , RailroadCommon.CLOCKWISE , AIRail.SIGNALTYPE_NORMAL ,
						signal_callback_param)) return false;
				if(!track_callback(t0 + AIMap.GetTileIndex(i , 0) ,
					AIRail.RAILTRACK_SW_SE , track_callback_param)) return false;
			}

			if(n_plataforms > 1)
				if(!track_callback(t0 + AIMap.GetTileIndex(n_plataforms - 1 , 3 + plataform_length) ,
					AIRail.RAILTRACK_NE_SE , track_callback_param)) return false;

			if(!track_callback(t0 + AIMap.GetTileIndex(n_plataforms - 1 , 3 + plataform_length) ,
				AIRail.RAILTRACK_NW_SE , track_callback_param)) return false;
			if(!track_callback(t0 + AIMap.GetTileIndex(n_plataforms - 1 , 4 + plataform_length) ,
				AIRail.RAILTRACK_NW_SE , track_callback_param)) return false;

			if(!signal_callback(t0 + AIMap.GetTileIndex(n_plataforms - 1 , 4 + plataform_length ) ,
				AIRail.RAILTRACK_NW_SE , RailroadCommon.CLOCKWISE , AIRail.SIGNALTYPE_NORMAL ,
					signal_callback_param)) return false;
			if(!signal_callback(t0 + AIMap.GetTileIndex(n_plataforms + 1 , 1) ,
				AIRail.RAILTRACK_NW_SE , RailroadCommon.COUNTERCLOCKWISE , AIRail.SIGNALTYPE_ENTRY ,
					signal_callback_param)) return false;
		break;

		case DoubleRailroadStation.EAST_NORTH:
			for(local i = 1 ; i <= n_plataforms ; i++)
				if(!track_callback(t0 + AIMap.GetTileIndex(0 , i) ,
					AIRail.RAILTRACK_NW_SE , track_callback_param)) return false;
			if(!track_callback(t0 + AIMap.GetTileIndex(0 , 0) ,
				AIRail.RAILTRACK_SW_SE , track_callback_param)) return false;
			if(!track_callback(t0 + AIMap.GetTileIndex(1 , 0) ,
				AIRail.RAILTRACK_NE_SW , track_callback_param)) return false;
			if(!track_callback(t0 + AIMap.GetTileIndex(2 , 0) ,
				AIRail.RAILTRACK_NE_SE , track_callback_param)) return false;
			if(!track_callback(t0 + AIMap.GetTileIndex(2 , 1) ,
				AIRail.RAILTRACK_NW_SW , track_callback_param)) return false;

			for(local i = 3 ; i <= plataform_length + 4 ; i++){
				if(!track_callback(t0 + AIMap.GetTileIndex(i , 1) ,
					AIRail.RAILTRACK_NE_SW , track_callback_param)) return false;
				if(!signal_callback(t0 + AIMap.GetTileIndex(i , 1) , AIRail.RAILTRACK_NE_SW ,
					RailroadCommon.CLOCKWISE , AIRail.SIGNALTYPE_NORMAL , signal_callback_param)) return false;
			}

			for(local i = 0 ; i < n_plataforms ; i++){
				if(!track_callback(t0 + AIMap.GetTileIndex(1 , 2 + i) ,
					AIRail.RAILTRACK_NE_SW , track_callback_param)) return false;
				if(!signal_callback(t0 + AIMap.GetTileIndex(1 , 2 + i) , AIRail.RAILTRACK_NE_SW ,
					RailroadCommon.COUNTERCLOCKWISE , AIRail.SIGNALTYPE_EXIT , signal_callback_param)) return false;
				if(i > 0)
					if(!track_callback(t0 + AIMap.GetTileIndex(3 + plataform_length , 2 + i) ,
						AIRail.RAILTRACK_NW_NE , track_callback_param)) return false;
				if(i > 0 && i < n_plataforms - 1 )
					if(!track_callback(t0 + AIMap.GetTileIndex(3 + plataform_length , 2 + i) ,
						AIRail.RAILTRACK_NW_SE , track_callback_param)) return false;
				if(!track_callback(t0 + AIMap.GetTileIndex(2 + plataform_length , 2 + i) ,
					AIRail.RAILTRACK_NE_SW , track_callback_param)) return false;
				if(!signal_callback(t0 + AIMap.GetTileIndex(2 + plataform_length , 2 + i) ,
					AIRail.RAILTRACK_NE_SW , RailroadCommon.COUNTERCLOCKWISE , AIRail.SIGNALTYPE_NORMAL ,
						signal_callback_param)) return false;
				if(!track_callback(t0 + AIMap.GetTileIndex(0 , 2 + i) ,
					AIRail.RAILTRACK_NW_SW , track_callback_param)) return false;
			}

			if(n_plataforms > 1)
				if(!track_callback(t0 + AIMap.GetTileIndex(3 + plataform_length , 2) ,
					AIRail.RAILTRACK_SW_SE , track_callback_param)) return false;

			if(!track_callback(t0 + AIMap.GetTileIndex(3 + plataform_length , 2) ,
				AIRail.RAILTRACK_NE_SW , track_callback_param)) return false;
			if(!track_callback(t0 + AIMap.GetTileIndex(4 + plataform_length , 2) ,
				AIRail.RAILTRACK_NE_SW , track_callback_param)) return false;

			if(!signal_callback(t0 + AIMap.GetTileIndex(4 + plataform_length , 2) ,
				AIRail.RAILTRACK_NE_SW , RailroadCommon.COUNTERCLOCKWISE , AIRail.SIGNALTYPE_NORMAL ,
					signal_callback_param)) return false;
			if(!signal_callback(t0 + AIMap.GetTileIndex(1 , 0) ,
				AIRail.RAILTRACK_NE_SW , RailroadCommon.CLOCKWISE , AIRail.SIGNALTYPE_ENTRY ,
					signal_callback_param)) return false;
		break;

		case DoubleRailroadStation.EAST_SOUTH:
			for(local i = 1 ; i <= n_plataforms ; i++)
				if(!track_callback(t0 + AIMap.GetTileIndex(0 , i) ,
					AIRail.RAILTRACK_NW_SE , track_callback_param)) return false;
			if(!track_callback(t0 + AIMap.GetTileIndex(0 , 1 + n_plataforms) ,
				AIRail.RAILTRACK_NW_SW , track_callback_param)) return false;
			if(!track_callback(t0 + AIMap.GetTileIndex(1 , 1 + n_plataforms) ,
				AIRail.RAILTRACK_NE_SW , track_callback_param)) return false;
			if(!track_callback(t0 + AIMap.GetTileIndex(2 , 1 + n_plataforms) ,
				AIRail.RAILTRACK_NW_NE , track_callback_param)) return false;
			if(!track_callback(t0 + AIMap.GetTileIndex(2 , n_plataforms) ,
				AIRail.RAILTRACK_SW_SE , track_callback_param)) return false;

			for(local i = 3 ; i <= plataform_length + 4 ; i++){
				if(!track_callback(t0 + AIMap.GetTileIndex(i , n_plataforms) ,
					AIRail.RAILTRACK_NE_SW , track_callback_param)) return false;
				if(!signal_callback(t0 + AIMap.GetTileIndex(i , n_plataforms) , AIRail.RAILTRACK_NE_SW ,
					RailroadCommon.COUNTERCLOCKWISE , AIRail.SIGNALTYPE_NORMAL , signal_callback_param)) return false;
			}

			for(local i = 0 ; i < n_plataforms ; i++){
				if(!track_callback(t0 + AIMap.GetTileIndex(1 , i) ,
					AIRail.RAILTRACK_NE_SW , track_callback_param)) return false;
				if(!signal_callback(t0 + AIMap.GetTileIndex(1 , i) , AIRail.RAILTRACK_NE_SW ,
					RailroadCommon.CLOCKWISE , AIRail.SIGNALTYPE_NORMAL , signal_callback_param)) return false;
				if(i < n_plataforms - 1)
					if(!track_callback(t0 + AIMap.GetTileIndex(3 + plataform_length , i) ,
						AIRail.RAILTRACK_NE_SE , track_callback_param)) return false;
				if(i > 0 && i < n_plataforms - 1 )
					if(!track_callback(t0 + AIMap.GetTileIndex(3 + plataform_length , i) ,
						AIRail.RAILTRACK_NW_SE , track_callback_param)) return false;
				if(!track_callback(t0 + AIMap.GetTileIndex(2 + plataform_length , i) ,
					AIRail.RAILTRACK_NE_SW , track_callback_param)) return false;
				if(!signal_callback(t0 + AIMap.GetTileIndex(2 + plataform_length , i) ,
					AIRail.RAILTRACK_NE_SW , RailroadCommon.CLOCKWISE , AIRail.SIGNALTYPE_EXIT ,
						signal_callback_param)) return false;
				if(!track_callback(t0 + AIMap.GetTileIndex(0 , i) ,
					AIRail.RAILTRACK_SW_SE , track_callback_param)) return false;
			}

			if(n_plataforms > 1)
				if(!track_callback(t0 + AIMap.GetTileIndex(3 + plataform_length , n_plataforms - 1) ,
					AIRail.RAILTRACK_NW_SW , track_callback_param)) return false;

			if(!track_callback(t0 + AIMap.GetTileIndex(3 + plataform_length , n_plataforms - 1) ,
				AIRail.RAILTRACK_NE_SW , track_callback_param)) return false;
			if(!track_callback(t0 + AIMap.GetTileIndex(4 + plataform_length , n_plataforms - 1) ,
				AIRail.RAILTRACK_NE_SW , track_callback_param)) return false;

			if(!signal_callback(t0 + AIMap.GetTileIndex(4 + plataform_length , n_plataforms - 1) ,
				AIRail.RAILTRACK_NE_SW , RailroadCommon.CLOCKWISE , AIRail.SIGNALTYPE_ENTRY ,
					signal_callback_param)) return false;
			if(!signal_callback(t0 + AIMap.GetTileIndex(1 , 1 + n_plataforms) ,
				AIRail.RAILTRACK_NE_SW , RailroadCommon.COUNTERCLOCKWISE , AIRail.SIGNALTYPE_NORMAL ,
					signal_callback_param)) return false;
		break;

		case DoubleRailroadStation.WEST_SOUTH:
			for(local i = 1 ; i <= n_plataforms ; i++)
				if(!track_callback(t0 + AIMap.GetTileIndex(plataform_length + 6 , i) ,
					AIRail.RAILTRACK_NW_SE , track_callback_param)) return false;
			if(!track_callback(t0 + AIMap.GetTileIndex(plataform_length + 6 , 1 + n_plataforms) ,
				AIRail.RAILTRACK_NW_NE , track_callback_param)) return false;
			if(!track_callback(t0 + AIMap.GetTileIndex(plataform_length + 5 , 1 + n_plataforms) ,
				AIRail.RAILTRACK_NE_SW , track_callback_param)) return false;
			if(!track_callback(t0 + AIMap.GetTileIndex(plataform_length + 4 , 1 + n_plataforms) ,
				AIRail.RAILTRACK_NW_SW , track_callback_param)) return false;
			if(!track_callback(t0 + AIMap.GetTileIndex(plataform_length + 4 , n_plataforms) ,
				AIRail.RAILTRACK_NE_SE , track_callback_param)) return false;

			for(local i = 2 ; i <= plataform_length + 3 ; i++){
				if(!track_callback(t0 + AIMap.GetTileIndex(i , n_plataforms) ,
					AIRail.RAILTRACK_NE_SW , track_callback_param)) return false;
				if(!signal_callback(t0 + AIMap.GetTileIndex(i , n_plataforms) , AIRail.RAILTRACK_NE_SW ,
					RailroadCommon.COUNTERCLOCKWISE , AIRail.SIGNALTYPE_NORMAL , signal_callback_param)) return false;
			}

			for(local i = 0 ; i < n_plataforms ; i++){
				if(!track_callback(t0 + AIMap.GetTileIndex(4 , i) ,
					AIRail.RAILTRACK_NE_SW , track_callback_param)) return false;
				if(!signal_callback(t0 + AIMap.GetTileIndex(4 , i) , AIRail.RAILTRACK_NE_SW ,
					RailroadCommon.CLOCKWISE , AIRail.SIGNALTYPE_NORMAL , signal_callback_param)) return false;
				if(i < n_plataforms - 1)
					if(!track_callback(t0 + AIMap.GetTileIndex(3 , i) ,
						AIRail.RAILTRACK_SW_SE , track_callback_param)) return false;
				if(i > 0 && i < n_plataforms - 1 )
					if(!track_callback(t0 + AIMap.GetTileIndex(3 , i) ,
						AIRail.RAILTRACK_NW_SE , track_callback_param)) return false;
				if(!track_callback(t0 + AIMap.GetTileIndex(5 + plataform_length , i) ,
					AIRail.RAILTRACK_NE_SW , track_callback_param)) return false;
				if(!signal_callback(t0 + AIMap.GetTileIndex(5 + plataform_length , i) ,
					AIRail.RAILTRACK_NE_SW , RailroadCommon.CLOCKWISE , AIRail.SIGNALTYPE_EXIT ,
					signal_callback_param)) return false;
				if(!track_callback(t0 + AIMap.GetTileIndex(6 + plataform_length , i) ,
					AIRail.RAILTRACK_NE_SE , track_callback_param)) return false;
			}

			if(n_plataforms > 1)
				if(!track_callback(t0 + AIMap.GetTileIndex(3 , n_plataforms - 1) ,
					AIRail.RAILTRACK_NW_NE , track_callback_param)) return false;

			if(!track_callback(t0 + AIMap.GetTileIndex(2 , n_plataforms - 1) ,
				AIRail.RAILTRACK_NE_SW , track_callback_param)) return false;
			if(!track_callback(t0 + AIMap.GetTileIndex(3 , n_plataforms - 1) ,
				AIRail.RAILTRACK_NE_SW , track_callback_param)) return false;

			if(!signal_callback(t0 + AIMap.GetTileIndex(plataform_length + 5 , 1 + n_plataforms) ,
				AIRail.RAILTRACK_NE_SW , RailroadCommon.COUNTERCLOCKWISE , AIRail.SIGNALTYPE_ENTRY ,
					signal_callback_param)) return false;
			if(!signal_callback(t0 + AIMap.GetTileIndex(2 , n_plataforms - 1) ,
				AIRail.RAILTRACK_NE_SW , RailroadCommon.CLOCKWISE , AIRail.SIGNALTYPE_NORMAL ,
					signal_callback_param)) return false;
		break;

		case DoubleRailroadStation.WEST_NORTH:
			for(local i = 1 ; i <= n_plataforms ; i++)
				if(!track_callback(t0 + AIMap.GetTileIndex(6 + plataform_length , i) ,
					AIRail.RAILTRACK_NW_SE , track_callback_param)) return false;
			if(!track_callback(t0 + AIMap.GetTileIndex(6 + plataform_length , 0) ,
				AIRail.RAILTRACK_NE_SE , track_callback_param)) return false;
			if(!track_callback(t0 + AIMap.GetTileIndex(5 + plataform_length , 0) ,
				AIRail.RAILTRACK_NE_SW , track_callback_param)) return false;
			if(!track_callback(t0 + AIMap.GetTileIndex(4 + plataform_length , 0) ,
				AIRail.RAILTRACK_SW_SE , track_callback_param)) return false;
			if(!track_callback(t0 + AIMap.GetTileIndex(4 + plataform_length , 1) ,
				AIRail.RAILTRACK_NW_NE , track_callback_param)) return false;

			for(local i = 2 ; i <= plataform_length + 3 ; i++){
				if(!track_callback(t0 + AIMap.GetTileIndex(i , 1) ,
					AIRail.RAILTRACK_NE_SW , track_callback_param)) return false;
				if(!signal_callback(t0 + AIMap.GetTileIndex(i , 1) , AIRail.RAILTRACK_NE_SW ,
					RailroadCommon.CLOCKWISE , AIRail.SIGNALTYPE_NORMAL , signal_callback_param)) return false;
			}

			for(local i = 0 ; i < n_plataforms ; i++){
				if(!track_callback(t0 + AIMap.GetTileIndex(4 , 2 + i) ,
					AIRail.RAILTRACK_NE_SW , track_callback_param)) return false;
				if(!signal_callback(t0 + AIMap.GetTileIndex(4 , 2 + i) , AIRail.RAILTRACK_NE_SW ,
					RailroadCommon.COUNTERCLOCKWISE , AIRail.SIGNALTYPE_EXIT , signal_callback_param)) return false;
				if(i > 0)
					if(!track_callback(t0 + AIMap.GetTileIndex(3 , 2 + i) ,
						AIRail.RAILTRACK_NW_SW , track_callback_param)) return false;
				if(i > 1 )
					if(!track_callback(t0 + AIMap.GetTileIndex(3 , 1 + i) ,
						AIRail.RAILTRACK_NW_SE , track_callback_param)) return false;
				if(!track_callback(t0 + AIMap.GetTileIndex(5 + plataform_length , 2 + i) ,
					AIRail.RAILTRACK_NE_SW , track_callback_param)) return false;
				if(!signal_callback(t0 + AIMap.GetTileIndex(5 + plataform_length , 2 + i) ,
					AIRail.RAILTRACK_NE_SW , RailroadCommon.COUNTERCLOCKWISE , AIRail.SIGNALTYPE_NORMAL ,
						signal_callback_param)) return false;
				if(!track_callback(t0 + AIMap.GetTileIndex(6 + plataform_length , 2 + i) ,
					AIRail.RAILTRACK_NW_NE , track_callback_param)) return false;
			}

			if(n_plataforms > 1)
				if(!track_callback(t0 + AIMap.GetTileIndex(3 , 2) ,
					AIRail.RAILTRACK_NE_SE , track_callback_param)) return false;

			if(!track_callback(t0 + AIMap.GetTileIndex(2 , 2) ,
				AIRail.RAILTRACK_NE_SW , track_callback_param)) return false;
			if(!track_callback(t0 + AIMap.GetTileIndex(3 , 2) ,
				AIRail.RAILTRACK_NE_SW , track_callback_param)) return false;

			if(!signal_callback(t0 + AIMap.GetTileIndex(2 , 2) ,
				AIRail.RAILTRACK_NE_SW , RailroadCommon.COUNTERCLOCKWISE , AIRail.SIGNALTYPE_ENTRY ,
					signal_callback_param)) return false;
			if(!signal_callback(t0 + AIMap.GetTileIndex(5 + plataform_length , 0) ,
				AIRail.RAILTRACK_NE_SW , RailroadCommon.CLOCKWISE , AIRail.SIGNALTYPE_NORMAL ,
					signal_callback_param)) return false;
		break;
	}

	return true;
}

function DoubleRailroadStation::BuildRailroadStation(){
	/* Build the station. */
	local station_direction;
	if(exit_direction == Direction.SOUTH ||
		exit_direction == Direction.NORTH) station_direction = AIRail.RAILTRACK_NW_SE;
	else station_direction = AIRail.RAILTRACK_NE_SW;

	if(!AIRail.BuildRailStation(station_tile , station_direction , n_plataforms ,
		plataform_length , AIStation.STATION_NEW )) return false;

	/* Build the station tracks. */
	switch(station_type){
		case PRE_SIGNALED:
			return IterateOverTracksOfPreSignaledStation(DoubleRailroadStation.BuildRailTrack , null ,
				DoubleRailroadStation.BuildRailSignal , null);
		break;
		case TERMINUS:
			return IterateOverTracksOfTerminusStation(DoubleRailroadStation.BuildRailTrack , null ,
				DoubleRailroadStation.BuildRailSignal , null);
		break;
	}
}

function DoubleRailroadStation::ConvertRailroadStation(rail_type){
	local tile = station_tile;
	local station_direction;

	if(exit_direction == Direction.SOUTH || exit_direction == Direction.NORTH)
		station_direction = AIRail.RAILTRACK_NW_SE;
	else station_direction = AIRail.RAILTRACK_NE_SW;
	if(station_direction == AIRail.RAILTRACK_NE_SW){
		tile += AIMap.GetTileIndex(plataform_length - 1 , n_plataforms - 1);
	}else{
		tile += AIMap.GetTileIndex(n_plataforms - 1 , plataform_length - 1);
	}
	AIRail.ConvertRailType(station_tile , tile , rail_type);

	switch(station_type){
		case DoubleRailroadStation.PRE_SIGNALED:
			DoubleRailroadStation.IterateOverTracksOfPreSignaledStation(DoubleRailroadStation.ConvertRailTrack ,
				rail_type , DoubleRailroadStation.DummyRailSignal , null);
		break;
		case DoubleRailroadStation.TERMINUS:
			DoubleRailroadStation.IterateOverTracksOfTerminusStation(DoubleRailroadStation.ConvertRailTrack ,
				rail_type , DoubleRailroadStation.DummyRailSignal , null);
		break;
	}
}

function DoubleRailroadStation::DemolishRailroadStation(){
	AITile.DemolishTile(station_tile);

	switch(station_type){
		case DoubleRailroadStation.PRE_SIGNALED:
			DoubleRailroadStation.IterateOverTracksOfPreSignaledStation(DoubleRailroadStation.DemolishRailTrack ,
				null , DoubleRailroadStation.DummyRailSignal , null);
		break;
		case DoubleRailroadStation.TERMINUS:
			DoubleRailroadStation.IterateOverTracksOfTerminusStation(DoubleRailroadStation.DemolishRailTrack ,
				null , DoubleRailroadStation.DummyRailSignal , null);
		break;
	}
}
