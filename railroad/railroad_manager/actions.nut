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

class Action {
	/* Public: */
	function Block();
	function Unblock();
	function Finished();

	/* Private: */
	railroad_route = null;
	next_action = null;
}

class ActionSellRailroadRouteTrains extends Action {
	/* Public: */
	function Block(){
		if(must_block)
			railroad_route.is_blocked = true;
		return must_block;
	}
	function Unblock(){
		return false;
	}
	function Finished(){
		return finished || !must_block;
	}

	/* Private: */
	function TrainsSoldCallback(self){
		self.finished = true;
	}
	must_block = null;
	finished = null;
}

class ActionConvertRailroadRouteRailType extends Action {
	/* Public: */
	function Finished(){
		railroad_route.ConvertRailroadRoute(new_rail_type);
		return true;
	}

	function Unblock(){
		railroad_route.is_blocked = false;
		return true;
	}
	/* Private: */
	new_rail_type = null;
}

class ActionDemolishRailroadRoute extends Action {
	/* Public: */
	function Finished(){
		if(railroad_route.HasVehiclesBeingSelled()) return false;

		railroad_route.DemolishRailroadRoute();
		return true;
	}
	function Unblock(){
		railroad_route.is_blocked = false;
		return true;
	}
}

class ActionBuildTownToTownRouteDoubleRailroad extends Action {
	/* Public: */
	function Block(){
		return true;
	}
	function Unblock(){
		return true;
	}
	function Finished(){
		if(drrb == null){
			local dtp = ::ai_instance.dtp;
			drrb = DoubleRailroadBuilder(railroad_route.town1_double_railroad_station.exit_part_tile ,
				dtp.GetOppositePartTile(railroad_route.town2_double_railroad_station.exit_part_tile ,
				railroad_route.town2_double_railroad_station.exit_part) ,
				railroad_route.town1_double_railroad_station.exit_part ,
				dtp.GetOppositePart(railroad_route.town2_double_railroad_station.exit_part));
			LogMessagesManager.PrintLogMessage(drrb.tostring());
		}

		railroad_route.double_railroad = drrb.BuildTrack();
		if(railroad_route.double_railroad == null){
			railroad_route.town1_double_railroad_station.DemolishRailroadStation();
			railroad_route.town2_double_railroad_station.DemolishRailroadStation();
			/* TODO: The problem can be at destination station. */
			::ai_instance.town_manager.Block(railroad_route.town1);
			::ai_instance.money_manager.ReleaseReservation(reservation_id);
			return true;
		}else if(railroad_route.double_railroad == false) return false;

		local town_manager = ::ai_instance.town_manager;
		assert(railroad_route != null);
		railroad_route.last_locomotive_update = AIDate.GetCurrentDate();
		town_manager.MarkAsUsed(railroad_route.town1);
		town_manager.MarkAsUsed(railroad_route.town2);

		railroad_route.train_manager = TrainManager(TownToTownRailroadRoute.EstimateNumberOfTrains , railroad_route ,
			TownToTownRailroadRoute.GetLocomotiveEngine , railroad_route , RailroadRoute.CouldNotBuildFirstLocomotive , railroad_route ,
			TownToTownRailroadRoute.SetTrainOrdersCallBack , railroad_route , wagon_engine ,
			railroad_route.double_railroad.depots_tiles_near_start[1] , railroad_route.town1_double_railroad_station.plataform_length ,
			railroad_manager.passenger_cargo);

		railroad_manager.railroad_routes.push(railroad_route);
		::ai_instance.money_manager.ReleaseReservation(reservation_id);
		railroad_route.AdjustNumberOfTrains();
		return true;
	}

	/* Private: */
	drrb = null;
	railroad_manager = null;
	reservation_id = null;
	wagon_engine = null;
}

class ActionBuildIndustryRouteDoubleRailroad extends Action {
	/* Public: */
	function Block(){
		return true;
	}
	function Unblock(){
		return true;
	}
	function Finished(){
		local double_railroad;
		if(drrb == null){
			local dtp = ::ai_instance.dtp;
			drrb = DoubleRailroadBuilder(source_double_railroad_station.exit_part_tile ,
				dtp.GetOppositePartTile(railroad_route.destination_double_railroad_station.exit_part_tile ,
				railroad_route.destination_double_railroad_station.exit_part) ,
				source_double_railroad_station.exit_part ,
				dtp.GetOppositePart(railroad_route.destination_double_railroad_station.exit_part));
			LogMessagesManager.PrintLogMessage(drrb.tostring());
		}

		double_railroad = drrb.BuildTrack();
		if(double_railroad == null){
			local industry_manager = ::ai_instance.industry_manager;
			source_double_railroad_station.DemolishRailroadStation();
			railroad_route.destination_double_railroad_station.DemolishRailroadStation();
			/* TODO: The problem can be at destination station. */
			industry_manager.Block(industry_id);
			::ai_instance.money_manager.ReleaseReservation(reservation_id);
			return true;
		}else if(double_railroad == false) return false;

		local industry_source;
		industry_source = IndustrySource(cargo , industry_id , source_double_railroad_station , railroad_route ,
			double_railroad , wagon_engine);
		railroad_route.industry_sources = [industry_source];

		railroad_route.last_locomotive_update = AIDate.GetCurrentDate();
		::ai_instance.industry_manager.MarkAsUsed(industry_id);
		assert(railroad_route != null);
		railroad_manager.railroad_routes.push(railroad_route);
		::ai_instance.money_manager.ReleaseReservation(reservation_id);
		industry_source.train_manager.AdjustNumberOfTrains();
		return true;
	}

	/* Private: */
	cargo = null;
	drrb = null;
	industry_id = null;
	railroad_manager = null;
	reservation_id = null;
	source_double_railroad_station = null;
	wagon_engine = null;
}

class ActionBuildRouteExpasionDoubleRailroad extends Action {
	/* Public: */
	function Block(){
		railroad_route.is_blocked = true;
		return true;
	}
	function Unblock(){
		railroad_route.is_blocked = false;
		return true;
	}
	function Finished(){
		local double_railroad;
		if(drrb == null){
			local dtp = ::ai_instance.dtp;
			drrb = DoubleRailroadBuilder(source_double_railroad_station.exit_part_tile ,
				dtp.parts[junction_information.junction_part_index].previous_part_offset +
				junction_information.tile , source_double_railroad_station.exit_part ,
				dtp.parts[junction_information.junction_part_index].previous_part);
			LogMessagesManager.PrintLogMessage(drrb.tostring());
		}
		double_railroad = drrb.BuildTrack();

		if(double_railroad == null){
			local industry_manager = ::ai_instance.industry_manager;
			source_double_railroad_station.DemolishRailroadStation();
			DoubleJunctionBuilder.DemolishJunction(junction_information);
			industry_manager.Block(industry_id);
			::ai_instance.money_manager.ReleaseReservation(reservation_id);
			return true;
		}else if(double_railroad == false) return false;

		local industry_source;
		industry_source = IndustrySource(cargo , industry_id , source_double_railroad_station , railroad_route ,
			double_railroad , wagon_engine);
		railroad_route.industry_sources.push(industry_source);
		::ai_instance.industry_manager.MarkAsUsed(industry_id);
		::ai_instance.money_manager.ReleaseReservation(reservation_id);
		industry_source.train_manager.AdjustNumberOfTrains();
		return true;
	}

	/* Private: */
	junction_information = null;
	cargo = null;
	drrb = null;
	industry_id = null;
	railroad_manager = null;
	reservation_id = null;
	source_double_railroad_station = null;
	wagon_engine = null;
}
