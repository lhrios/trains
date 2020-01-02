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

class IndustrySource {
	/* Public: */
	cargo = null;
	industry = null;
	source_double_railroad_station = null;
	railroad_route = null;
	double_railroad = null;
	train_manager = null;
	last_check = AIDate.GetCurrentDate();
	n_trains_at_station = 0;
	n_samples = 0;
	n_years_losing_money = 0

	constructor(cargo , industry , source_double_railroad_station , railroad_route , double_railroad , wagon_engine){
		this.cargo = cargo;
		this.industry = industry;
		this.source_double_railroad_station = source_double_railroad_station;
		this.railroad_route = railroad_route;
		this.double_railroad = double_railroad;
		train_manager = TrainManager(EstimateNumberOfTrains , this , GetLocomotiveEngine , this ,
			RailroadRoute.CouldNotBuildFirstLocomotive , railroad_route ,
			SetTrainOrders , this , wagon_engine , double_railroad.depots_tiles_near_start[1] ,
			source_double_railroad_station.plataform_length , cargo);
	}

	function ConvertIndustrySource(rail_type);
	function CorrectNumberOfTrains();
	function DemolishIndustrySource();
	function EstimateCostToConvertIndustrySource(rail_type);
	function EstimateNumberOfTrains(self);
	function GetLocomotiveEngine(self);
	function GetNumberOfUnprofitableTrains();
	function HasTrafficJam();
	function SetTrainOrders(self , locomotive);
}

function IndustrySource::EstimateCostToConvertIndustrySource(rail_type){
	local cost = source_double_railroad_station.EstimateCostToConvertRailroadStation(rail_type);
	cost += DoubleRailroadBuilder.EstimateCostToConvertTrack(double_railroad.path , rail_type);
	return cost;
}

function IndustrySource::ConvertIndustrySource(rail_type){
	source_double_railroad_station.ConvertRailroadStation(rail_type);
	DoubleRailroadBuilder.ConvertTrack(double_railroad.path , rail_type);
}

function IndustrySource::DemolishIndustrySource(){
	DoubleRailroadBuilder.DemolishDoubleRailroad(double_railroad.path);
	source_double_railroad_station.DemolishRailroadStation();
	train_manager.DeleteGroup();
	::ai_instance.industry_manager.MarkAsUnused(industry);
}

function IndustrySource::SetTrainOrders(self , locomotive){
	this = self;
	RailroadRoute.SetTrainOrders(locomotive , source_double_railroad_station.station_tile , double_railroad.depots_tiles_near_start[0] ,
		AIOrder. AIOF_FULL_LOAD_ANY , railroad_route.destination_double_railroad_station.station_tile ,
		railroad_route.industry_sources[0].double_railroad.depots_tiles_near_end[1] , AIOrder.AIOF_NO_LOAD | AIOrder.AIOF_UNLOAD);
}

function IndustrySource::EstimateNumberOfTrains(self){
	this = self;
	local load_time , transport_time;
	local n_trains;
	local n_wagons = train_manager.n_wagons;
	local tiles_per_day = (AIEngine.GetMaxSpeed(railroad_route.locomotive_engine) * 0.8 * 74.0) / 256.0 / 16.0;
	local wagon_engine = train_manager.wagon_engine;

	assert(n_wagons != null && n_wagons != 0 && tiles_per_day != 0);

	transport_time = (AIMap.DistanceManhattan(AIIndustry.GetLocation(industry) , AIIndustry.GetLocation(railroad_route.d_industry)) * 2.0) / tiles_per_day;
	load_time = (AIEngine.GetCapacity(wagon_engine) * n_wagons) / (AIIndustry.GetLastMonthProduction(industry , cargo) * 0.7 / 30.0) +
		(source_double_railroad_station.plataform_length / tiles_per_day);

	n_trains = ((transport_time + load_time)/load_time).tointeger();
	if(n_trains <= 1) n_trains = 2;
	else if(n_trains > 8) n_trains = 8;

	return n_trains;
}

function IndustrySource::HasTrafficJam(){
	return false;
}

function IndustrySource::GetLocomotiveEngine(self){
	this = self;
	return railroad_route.locomotive_engine;
}

function IndustrySource::GetNumberOfUnprofitableTrains(){
	local unprofitable_trains = train_manager.GetTrainsList();
	unprofitable_trains.Valuate(AIVehicle.GetAge);
	unprofitable_trains.RemoveBelowValue(365 * 2);
	unprofitable_trains.Valuate(AIVehicle.GetProfitLastYear);
	unprofitable_trains.RemoveAboveValue(-1);
	unprofitable_trains.Valuate(AIVehicle.GetProfitThisYear);
	unprofitable_trains.RemoveAboveValue(-1);
	return unprofitable_trains.Count();
}

function IndustrySource::CorrectNumberOfTrains(){
	local source_trains = train_manager.GetTrainsList();
	source_trains.Valuate(AIVehicle.GetState);
	source_trains.KeepValue(AIVehicle.VS_AT_STATION);
	source_trains.Valuate(AIVehicle.GetLocation);
	foreach(vehicle_id , location in source_trains){
		if(AITile.IsStationTile(location) &&
			AIStation.GetStationID(location) == AIStation.GetStationID(source_double_railroad_station.station_tile))
			n_trains_at_station++;
	}
	n_samples++;

	if(last_check + 365 < AIDate.GetCurrentDate()){
		local unprofitable_trains = GetNumberOfUnprofitableTrains();
		local n_trains = train_manager.n_trains;

		/* If it is necessary increase the number of trains. */
		if(n_samples >= RailroadRoute.MIN_NUMBER_OF_SAMPLES && n_trains != null && n_trains != 0 &&
			n_trains == train_manager.GetCurrentNumberOfTrains() && unprofitable_trains == 0){

			local ratio = n_trains_at_station.tofloat()/n_samples.tofloat();
			if(!railroad_route.HasTrafficJam()){
				if(ratio < 0.5) n_trains++;
				else if(ratio < 1) n_trains+=2;
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
		n_trains_at_station = n_samples = 0;
	}
}
