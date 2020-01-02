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

class DoubleRailroadStationBuilder {
	/* Public: */
	constructor(n_plataforms , plataform_length , main_exit_direction , secondary_exit_direction ,
		terraforming_max_cost , station_type){
		this.n_plataforms = n_plataforms;
		this.plataform_length = plataform_length;
		this.main_exit_direction = main_exit_direction;
		this.secondary_exit_direction = secondary_exit_direction;
		this.terraforming_max_cost = terraforming_max_cost;
		this.station_type = station_type;
	}

	function BuildRailroadStation();
	function EstimateRailroadStationCost();

	/* Private: */
	/* Constants: */
	static MAX_TRIES = 3;

	n_plataforms = null;
	plataform_length = null;
	main_exit_direction = null;
	secondary_exit_direction = null;
	terraforming_max_cost = null;
	station_type = null;
}

class DoubleRailroadIndustryStationBuilder extends DoubleRailroadStationBuilder {
	/* Public: */
	constructor(n_plataforms , plataform_length , main_exit_direction , secondary_exit_direction ,
		terraforming_max_cost , station_type , industry , produces){
		local coverage_radius = AIStation.GetCoverageRadius(AIStation.STATION_TRAIN);

		DoubleRailroadStationBuilder.constructor(n_plataforms , plataform_length , main_exit_direction ,
			secondary_exit_direction , terraforming_max_cost , station_type);
		this.industry = industry;
		target_tile = AIIndustry.GetLocation(industry);

		if(produces) covered_tile_list = AITileList_IndustryProducing(industry , coverage_radius);
		else covered_tile_list = AITileList_IndustryAccepting(industry , coverage_radius);
	}

	/* Private: */
	covered_tile_list = null;
	industry = null;
	target_tile = null;

	function StationLandEvaluation(land , self);
	function StationCoversIndustry(station_tile , tracks_parallel_x);
}

class DoubleRailroadTownStationBuilder extends DoubleRailroadStationBuilder {
	/* Public: */
	constructor(n_plataforms , plataform_length , main_exit_direction , secondary_exit_direction ,
		terraforming_max_cost , station_type , town , produces , cargo){

		DoubleRailroadStationBuilder.constructor(n_plataforms , plataform_length , main_exit_direction ,
			secondary_exit_direction , terraforming_max_cost , station_type);
		this.cargo = cargo;
		this.produces = produces;
		this.town = town;
		target_tile = AITown.GetLocation(town);
	}

	/* Private: */
 	cargo = null;
 	produces = null;
	target_tile = null;
	town = null;

	function StationLandEvaluation(land , self);
}

function DoubleRailroadIndustryStationBuilder::StationCoversIndustry(station_tile , tracks_parallel_x){
	local w , h;
	local area_w , area_h;

	if(tracks_parallel_x){
		area_w = plataform_length;
		area_h = n_plataforms;
	}else{
		area_h = plataform_length;
		area_w = n_plataforms;
	}

 	for(w = 0 ; w < area_w ; w++){
		for(h = 0 ; h < area_h ; h++){
			if(covered_tile_list.HasItem(station_tile + AIMap.GetTileIndex(w , h)))
				return true;
		}
	}
	return false;
}

function DoubleRailroadIndustryStationBuilder::StationLandEvaluation(land , self){
	this = self;
	local double_railroad_station = DoubleRailroadStation();

	double_railroad_station.plataform_length = plataform_length;
	double_railroad_station.n_plataforms = n_plataforms;
	double_railroad_station.station_type = station_type;
	double_railroad_station.land = land;

	double_railroad_station.DecideRailroadStationPosition(main_exit_direction ,
		secondary_exit_direction , target_tile);

	if(double_railroad_station.exit_direction == Direction.INVALID_DIRECTION ||
		!StationCoversIndustry(double_railroad_station.station_tile ,
		(double_railroad_station.exit_direction == Direction.WEST ||
		double_railroad_station.exit_direction == Direction.EAST)))
		return 0;
	if(double_railroad_station.exit_direction == main_exit_direction) return 1.0;
	else if(double_railroad_station.exit_direction == secondary_exit_direction) return 0.75;
	else if(double_railroad_station.exit_direction != Direction.GetOppositeDirection(main_exit_direction))
		return 0.25;
	else return 0.125;
}

function DoubleRailroadIndustryStationBuilder::BuildRailroadStation(){
	local w , h;
	local land;
	local coverage_radius = AIStation.GetCoverageRadius(AIStation.STATION_TRAIN);
	local ila;
	local double_railroad_station = DoubleRailroadStation();

	switch(station_type){
		case DoubleRailroadStation.PRE_SIGNALED:
			w = n_plataforms + 2;
			h = plataform_length + 7;
		break;
		case DoubleRailroadStation.TERMINUS:
			assert(n_plataforms >= 2);
			w = n_plataforms;
			h = plataform_length + 5;
		break;
	}

	double_railroad_station.plataform_length = plataform_length;
	double_railroad_station.n_plataforms = n_plataforms;
	double_railroad_station.station_type = station_type;

	ila = IndustryLandAllocator(w , h , DoubleRailroadIndustryStationBuilder.StationLandEvaluation ,
		this , terraforming_max_cost , true , 0.75 , coverage_radius , industry);

	for(local i = 0 ; true ; i++){
		land = ila.GetNextBestLand();

		if(land == null || i >= DoubleRailroadStationBuilder.MAX_TRIES) break;
		else{
			double_railroad_station.land = land;
			double_railroad_station.DecideRailroadStationPosition(main_exit_direction ,
				secondary_exit_direction , target_tile);
			assert(double_railroad_station.exit_direction != Direction.INVALID_DIRECTION);

			/* Build the station. */
			if(!double_railroad_station.BuildRailroadStation()){
				double_railroad_station.DemolishRailroadStation();
				continue;
			}

			return double_railroad_station;
		}
	}
	return null;
}

function DoubleRailroadTownStationBuilder::StationLandEvaluation(land , self){
	this = self;
	local double_railroad_station = DoubleRailroadStation();
	local aux;

	double_railroad_station.plataform_length = plataform_length;
	double_railroad_station.n_plataforms = n_plataforms;
	double_railroad_station.station_type = station_type;
	double_railroad_station.land = land;

	double_railroad_station.DecideRailroadStationPosition(main_exit_direction ,
		secondary_exit_direction , target_tile);

 	if(double_railroad_station.exit_direction == Direction.INVALID_DIRECTION) return 0;
	if(produces){
		aux = double_railroad_station.GetCargoProduction(cargo);
	}else{
		aux = double_railroad_station.GetCargoAcceptance(cargo);
	}
	return (aux > 8 ? aux : 0);
}

function DoubleRailroadTownStationBuilder::BuildRailroadStation(){
	local w , h;
	local land;
	local tla;
	local double_railroad_station = DoubleRailroadStation();

	switch(station_type){
		case DoubleRailroadStation.PRE_SIGNALED:
			w = n_plataforms + 2;
			h = plataform_length + 7;
		break;
		case DoubleRailroadStation.TERMINUS:
			assert(n_plataforms >= 2);
			w = n_plataforms;
			h = plataform_length + 5;
		break;
	}

	double_railroad_station.plataform_length = plataform_length;
	double_railroad_station.n_plataforms = n_plataforms;
	double_railroad_station.station_type = station_type;

	tla = TownLandAllocator(w , h , DoubleRailroadTownStationBuilder.StationLandEvaluation ,
		this , terraforming_max_cost , true , 0.25 , town);

	for(local i = 0 ; true ; i++){
		land = tla.GetNextBestLand();
		if(land == null || i >= DoubleRailroadStationBuilder.MAX_TRIES) break;
		else{
			double_railroad_station.land = land;
			double_railroad_station.DecideRailroadStationPosition(main_exit_direction ,
				secondary_exit_direction , target_tile);
			assert(double_railroad_station.exit_direction != Direction.INVALID_DIRECTION);

			/* Build the station. */
			if(!double_railroad_station.BuildRailroadStation()){
				double_railroad_station.DemolishRailroadStation();
				continue;
			}

			return double_railroad_station;
		}
	}
	return null;
}
