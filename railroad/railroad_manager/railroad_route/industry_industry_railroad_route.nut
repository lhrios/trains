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

class IndustryToIndustryRailroadRoute extends RailroadRoute {
	/* Public: */
	d_industry = null;
	destination_double_railroad_station = null;
	industry_sources = null;
}

function IndustryToIndustryRailroadRoute::EstimateCostToConvertRailroadRoute(rail_type){
	local cost = destination_double_railroad_station.EstimateCostToConvertRailroadStation(rail_type);
	foreach(industry_source in industry_sources){
		cost += industry_source.EstimateCostToConvertIndustrySource(rail_type);
	}
	return cost;
}

function IndustryToIndustryRailroadRoute::DoesNumberOfTrainsNeedsToBeAdjusted(){
	foreach(industry_source in industry_sources){
		if(industry_source.train_manager.DoesNumberOfTrainsNeedsToBeAdjusted()) return true;
	}
	return false;
}

function IndustryToIndustryRailroadRoute::AdjustNumberOfTrains(){
	foreach(industry_source in industry_sources){
		industry_source.train_manager.AdjustNumberOfTrains();
	}
}

function IndustryToIndustryRailroadRoute::CorrectNumberOfTrains(){
	foreach(industry_source in industry_sources){
		industry_source.CorrectNumberOfTrains();
	}
}

function IndustryToIndustryRailroadRoute::HasVehiclesBeingSelled(){
	foreach(industry_source in industry_sources){
		if(industry_source.train_manager.HasVehiclesBeingSelled()) return true;
	}
	return false;
}

function IndustryToIndustryRailroadRoute::InformLocomotiveChange(new_rail_type , new_locomotive_engine){
	local old_locomotive_engine = locomotive_engine;
	locomotive_engine = new_locomotive_engine;

	foreach(industry_source in industry_sources){
		if(ChooseWagon(industry_source.cargo , new_rail_type) == null) return false;
	}

	foreach(industry_source in industry_sources){
		local n_trains = industry_source.train_manager.n_trains;

		industry_source.train_manager.n_wagons = null;
		if(n_trains != null && n_trains != 0){
			n_trains = (n_trains.tofloat() *
				AIEngine.GetMaxSpeed(old_locomotive_engine).tofloat() /
				AIEngine.GetMaxSpeed(locomotive_engine).tofloat()).tointeger();
			n_trains = n_trains < 2 ? 2 : n_trains;
			industry_source.train_manager.n_trains = n_trains;
		}

		industry_source.n_trains_at_station = industry_source.n_samples = 0;
		industry_source.train_manager.wagon_engine = RailroadRoute.ChooseWagon(industry_source.cargo , new_rail_type);
	}
	return true;
}

function IndustryToIndustryRailroadRoute::GetTrainsList(){
	local trains = AIList();
	foreach(industry_source in industry_sources){
		trains.AddList(industry_source.train_manager.GetTrainsList());
	}
	return trains;
}

function IndustryToIndustryRailroadRoute::HasTrafficJam(){
	foreach(industry_source in industry_sources)
		if(industry_source.HasTrafficJam()) return true;
	return false;
}

function IndustryToIndustryRailroadRoute::IsUnprofitable(){
	foreach(industry_source in industry_sources){
		local n_trains = industry_source.train_manager.n_trains;
		if(n_trains == null || n_trains > 0) return false;
	}
	return true;
}

function IndustryToIndustryRailroadRoute::GetType(){
	return RailroadRoute.INDUSTRY_TO_INDUSTRY;
}

function IndustryToIndustryRailroadRoute::DemolishRailroadRoute(){
	foreach(industry_source in industry_sources)
		industry_source.DemolishIndustrySource();
	destination_double_railroad_station.DemolishRailroadStation();
}

function IndustryToIndustryRailroadRoute::ConvertRailroadRoute(rail_type){
	this.rail_type = rail_type;
	foreach(industry_source in industry_sources)
		industry_source.ConvertIndustrySource(rail_type);
	destination_double_railroad_station.ConvertRailroadStation(rail_type);
	AdjustNumberOfTrains();
}
