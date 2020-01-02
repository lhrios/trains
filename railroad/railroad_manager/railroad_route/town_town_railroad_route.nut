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

class TownToTownRailroadRoute extends RailroadRoute {
	/* Public: */
	town1 = null;
	town2 = null;
	town1_double_railroad_station = null;
	town2_double_railroad_station = null;
	last_check = AIDate.GetCurrentDate();
	n_trains_at_station1 = 0;
	n_trains_at_station2 = 0;
	n_samples = 0;
	n_years_losing_money = 0;
	double_railroad = 0;
	train_manager = null;

	function EstimateNumberOfTrains(self);
	function GetLocomotiveEngine(self);
	function GetNumberOfUnprofitableTrains();
	function SetTrainOrdersCallBack(self , locomotive);
}

function TownToTownRailroadRoute::HasVehiclesBeingSelled(){
	return train_manager.HasVehiclesBeingSelled();
}

function TownToTownRailroadRoute::EstimateCostToConvertRailroadRoute(rail_type){
	local cost = town1_double_railroad_station.EstimateCostToConvertRailroadStation(rail_type);
	cost += town2_double_railroad_station.EstimateCostToConvertRailroadStation(rail_type);
	cost += DoubleRailroadBuilder.EstimateCostToConvertTrack(double_railroad.path , rail_type);
	return cost;
}

function TownToTownRailroadRoute::IsUnprofitable(){
	local n_trains = train_manager.n_trains;
	return (n_trains != null && n_trains <= 0);
}

function TownToTownRailroadRoute::ConvertRailroadRoute(rail_type){
	this.rail_type = rail_type;
	town1_double_railroad_station.ConvertRailroadStation(rail_type);
	town2_double_railroad_station.ConvertRailroadStation(rail_type);
	DoubleRailroadBuilder.ConvertTrack(double_railroad.path , rail_type);
	AdjustNumberOfTrains();
}

function TownToTownRailroadRoute::HasTrafficJam(){
	return false;
}

function TownToTownRailroadRoute::SetTrainOrdersCallBack(self , locomotive){
	this = self;
	RailroadRoute.SetTrainOrders(locomotive , town1_double_railroad_station.station_tile , double_railroad.depots_tiles_near_start[0] ,
		AIOrder.AIOF_FULL_LOAD_ANY | AIOrder.AIOF_UNLOAD , town2_double_railroad_station.station_tile , double_railroad.depots_tiles_near_end[1] ,
		AIOrder.AIOF_FULL_LOAD_ANY | AIOrder.AIOF_UNLOAD);
}

function TownToTownRailroadRoute::GetLocomotiveEngine(self){
	this = self;
	return locomotive_engine;
}

function TownToTownRailroadRoute::EstimateNumberOfTrains(self){
	this = self;

	local aux;
	local cargo = ::ai_instance.railroad_manager.passenger_cargo;
	local load_time , transport_time;
	local n_trains;
	local n_wagons = train_manager.n_wagons;
	local tiles_per_day = (AIEngine.GetMaxSpeed(locomotive_engine) * 0.8 * 74.0) / 256.0 / 16.0;
	local wagon_capacity = AIEngine.GetCapacity(train_manager.wagon_engine);
	local town1_production = AITown.GetLastMonthProduction(town1 , cargo) - AITown.GetLastMonthTransported(town1 , cargo);
	local town2_production = AITown.GetLastMonthProduction(town2 , cargo) - AITown.GetLastMonthTransported(town2 , cargo);

	town1_production = town1_production <= 8 ? 8.0 : town1_production.tofloat();
	town2_production = town2_production <= 8 ? 8.0 : town2_production.tofloat();
	assert(n_wagons != null && n_wagons != 0 && tiles_per_day != 0);

	transport_time = (AIMap.DistanceManhattan(AIIndustry.GetLocation(town1) , AIIndustry.GetLocation(town2)) * 2.0) / tiles_per_day;
	load_time = (wagon_capacity * n_wagons) / (town1_production * 0.25 / 30.0) +
		(town1_double_railroad_station.plataform_length  / tiles_per_day);
	aux = (wagon_capacity * n_wagons) / (town2_production * 0.25 / 30.0) +
		(town2_double_railroad_station.plataform_length  / tiles_per_day);
	load_time = load_time <= aux ? aux : load_time;

	n_trains = ((transport_time + load_time)/load_time).tointeger();
	if(n_trains <= 1) n_trains = 2;
	else if(n_trains > 8) n_trains = 8;

	return n_trains;
}

function TownToTownRailroadRoute::GetType(){
	return RailroadRoute.TOWN_TO_TOWN;
}

function TownToTownRailroadRoute::AdjustNumberOfTrains(){
	train_manager.AdjustNumberOfTrains();
}

function TownToTownRailroadRoute::GetTrainsList(){
	return train_manager.GetTrainsList();
}

function TownToTownRailroadRoute::GetNumberOfUnprofitableTrains(){
	local unprofitable_trains = GetTrainsList();
	unprofitable_trains.Valuate(AIVehicle.GetAge);
	unprofitable_trains.RemoveBelowValue(365 * 2);
	unprofitable_trains.Valuate(AIVehicle.GetProfitLastYear);
	unprofitable_trains.RemoveAboveValue(-1);
	unprofitable_trains.Valuate(AIVehicle.GetProfitThisYear);
	unprofitable_trains.RemoveAboveValue(-1);
	return unprofitable_trains.Count();
}

function TownToTownRailroadRoute::InformLocomotiveChange(new_rail_type , new_locomotive_engine){
	local cargo = ::ai_instance.railroad_manager.passenger_cargo;
	local old_locomotive_engine = locomotive_engine;
	local n_trains = train_manager.n_trains;

	if(ChooseWagon(cargo , new_rail_type) == null) return false;

	locomotive_engine = new_locomotive_engine;
	train_manager.n_wagons = null;
	if(n_trains != null && n_trains != 0){
		n_trains = (n_trains.tofloat() *
			AIEngine.GetMaxSpeed(old_locomotive_engine).tofloat() /
			AIEngine.GetMaxSpeed(locomotive_engine).tofloat()).tointeger();
		n_trains = n_trains < 2 ? 2 : n_trains;
		train_manager.n_trains = n_trains;
	}

	n_trains_at_station1 = n_trains_at_station2 = n_samples = 0;
	train_manager.wagon_engine = RailroadRoute.ChooseWagon(cargo , new_rail_type);
	return true;
}

function TownToTownRailroadRoute::CorrectNumberOfTrains(){
	local trains = GetTrainsList();
	trains.Valuate(AIVehicle.GetState);
	trains.KeepValue(AIVehicle.VS_AT_STATION);
	trains.Valuate(AIVehicle.GetLocation);
	foreach(vehicle_id , location in trains){
		if(AITile.IsStationTile(location)){
			local station_id = AIStation.GetStationID(location);
			if(station_id == AIStation.GetStationID(town1_double_railroad_station.station_tile)) n_trains_at_station1++;
			else if(station_id == AIStation.GetStationID(town2_double_railroad_station.station_tile)) n_trains_at_station2++;
		}
	}
	n_samples++;

	if(last_check + 365 < AIDate.GetCurrentDate()){
		local unprofitable_trains = GetNumberOfUnprofitableTrains();
		local n_trains = train_manager.n_trains;

		/* If it is necessary increase the number of trains. */
		if(n_samples >= RailroadRoute.MIN_NUMBER_OF_SAMPLES && n_trains != null && n_trains != 0 &&
			n_trains == train_manager.GetCurrentNumberOfTrains() && unprofitable_trains == 0){

			local ratio_station1 = n_trains_at_station1.tofloat()/n_samples.tofloat();
			local ratio_station2 = n_trains_at_station2.tofloat()/n_samples.tofloat();
			local ratio = ratio_station1 > ratio_station2 ? ratio_station1 : ratio_station2;
			if(!HasTrafficJam()){
				if(ratio < 0.5) n_trains += 2;
				else if(ratio < 0.8) n_trains++;
				else if(ratio > 1.5) n_trains--;
			}
		}

		/* If there is some unprofitable train adjust the number of trains. */
		if(unprofitable_trains > 0){
			assert(n_trains != null);
			n_trains -= unprofitable_trains;
			if(n_trains < 1){
				if(++n_years_losing_money >= 2) n_trains = 0;
				else n_trains = 1;
			}else n_years_losing_money = 0;
		}

		train_manager.n_trains = n_trains;
		last_check = AIDate.GetCurrentDate();
		n_trains_at_station1 = n_trains_at_station2 = n_samples = 0;
	}
}

function TownToTownRailroadRoute::DemolishRailroadRoute(){
	local town_manager = ::ai_instance.town_manager;

	DoubleRailroadBuilder.DemolishDoubleRailroad(double_railroad.path);
	train_manager.DeleteGroup();
	town1_double_railroad_station.DemolishRailroadStation();
	town2_double_railroad_station.DemolishRailroadStation();
	town_manager.MarkAsUnused(town1);
	town_manager.MarkAsUnused(town2);
}

function TownToTownRailroadRoute::DoesNumberOfTrainsNeedsToBeAdjusted(){
	return train_manager.DoesNumberOfTrainsNeedsToBeAdjusted();
}
