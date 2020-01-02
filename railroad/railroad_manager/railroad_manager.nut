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

class RailroadManager {
	/* Public: */
	constructor(){
		::ai_instance.scheduler.CreateTask(CorrectNumberOfTrainsInRailroadRoutes , this , Scheduler.WEEKLY_INTERVAL);
		::ai_instance.scheduler.CreateTask(InvestMoneyOnRailroads , this , Scheduler.TRIWEEKLY_INTERVAL);
		::ai_instance.scheduler.CreateTask(MaintainRailroadRoutes , this , Scheduler.BIWEEKLY_INTERVAL);

		passenger_cargo = GetPassengerCargo();
	}
	function InformIndustryClosure(industry_id);

	/* Private: */
	/* Constants: */
	static PLATFORM_LENGTH = 5;
	static DESTINATION_NUM_PLATFORMS = 2;
	static SOURCE_NUM_PLATFORMS = 2;

	static INDUSTRY_MIN_PRODUCTION = 88;
	static TOWN_MIN_PRODUCTION = 120;

	static RAILROAD_ROUTE_LENGTH = 250;
	static RAILROAD_ROUTE_LENGTH_TOLERANCE = 80;

	static JUNCTION_GAP_SIZE = 20;
	static MAX_DISTANCE_JUNCTION_POINT = 150;

	static MIN_INDUSTRY_INDUSTRY_ROUTES_BEFORE_TOWN_TOWN_ROUTE = 3;

	static STATION_TERRAFORMING_MAX_COST = 30000;

	static MIN_MONEY_TO_INVEST = 275000;

	static INTERVAL_CHANGE_LOCOMOTIVE = 5 * 365; /* days. */

	static MAX_NUM_ROUTE_SOURCES = 5;

	static MIN_POPULATION = 1500;

	n_railroad_routes_blocked = 0;
	passenger_cargo = null;
	railroad_routes = array(0);
	pending_actions = array(0);

	static function GetOrdedCargos();
	static function GetValuatedRailTypes();
	static function GetPassengerCargo();
	static function EstimateCostToBuildRailroadRoute(rail_type , length);

	function BuildNewIndustryRailroadRoute(industry , cargo , rail_type , reservation_id);
	function CanBuildNewRoute();
	function CanInvestMoneyOnTown();
	function CorrectNumberOfTrainsInRailroadRoutes(self);
	function DemolishIndustryRailroadRoute(railroad_route);
	function ExpandIndustryRailroadRoute(industry , cargo , railroad_route , reservation_id);
	function ExecuteActions(self);
	function GetEvaluatedLocomotiveModelsList(cargo , rail_type , locomotive_max_price);
	function InvestMoneyOnIndustry(just_primary , reservation_id);
	function InvestMoneyOnRailroads(self);
	function InvestMoneyOnTown(reservation_id);
	function InsertAction(action);
}

function RailroadManager::CanInvestMoneyOnTown(){
	local rail_types = GetValuatedRailTypes();
	if(rail_types.Count() == 0) return false;
	local locomotive_engine = RailroadRoute.ChooseLocomotive(passenger_cargo , rail_types.Begin() , null);
	return locomotive_engine != null && AIEngine.GetMaxSpeed(locomotive_engine) >= 96;
}

function RailroadManager::EstimateCostToBuildRailroadRoute(rail_type , length){
	local rail_cost = AIRail.GetBuildCost(rail_type , AIRail.BT_TRACK);
	return (rail_cost * 4 * RAILROAD_ROUTE_LENGTH * 1.10).tointeger();
}

function RailroadManager::GetPassengerCargo(){
	local cargo_list = AICargoList();

	cargo_list.Valuate(AICargo.HasCargoClass , AICargo.CC_PASSENGERS);
	cargo_list.KeepValue(1);
	cargo_list.Valuate(AICargo.GetTownEffect);
	cargo_list.KeepValue(AICargo.TE_PASSENGERS);
	if(cargo_list.Count() == 0) throw("There is no passenger cargo.");

	return cargo_list.Begin();
}

function RailroadManager::GetValuatedRailTypes(){
	local rail_types = AIRailTypeList();
	local rtv = RailTypeValuator();

	rail_types.Valuate(AIRail.IsRailTypeAvailable);
	rail_types.KeepValue(1);
	rail_types.Valuate(RailTypeValuator.ValuateRailType , rtv);
	rail_types.KeepAboveValue(0);
	rail_types.Sort(AIAbstractList.SORT_BY_VALUE , false);

	return rail_types;
}

function RailroadManager::CanBuildNewRoute(){
	/* Check if we can build more trains. */
	if(::ai_instance.game_settings.max_trains <= RailroadRoute.GetTotalNumberOfTrains()) return false;

	foreach(railroad_route in railroad_routes){
		if(railroad_route.DoesNumberOfTrainsNeedsToBeAdjusted()) return false;
	}
	return true;
}

function RailroadManager::DemolishIndustryRailroadRoute(railroad_route){
	InsertAction(railroad_route.GetActionDemolishRailroadRoute(null));
}

function RailroadManager::GetOrdedCargos(){
	local cargos = AICargoList();
	cargos.Valuate(AICargo.IsValidCargo);
	cargos.KeepValue(1);
	cargos.Valuate(AICargo.HasCargoClass , AICargo.CC_PASSENGERS);
	cargos.KeepValue(0);
	cargos.Valuate(AICargo.HasCargoClass , AICargo.CC_MAIL);
	cargos.KeepValue(0);
	cargos.Valuate(AICargo.GetCargoIncome , 20 , 10);
	cargos.Sort(AIAbstractList.SORT_BY_VALUE , false);
	if(cargos.Count() == 0) throw("There is no cargos I can deal with.");
	return cargos;
}

/* TODO: Use parameters to configure this function: terraforming. */
/* TODO: Deal with secondary industries. */
function RailroadManager::InvestMoneyOnIndustry(just_primary , reservation_id){
	local aux;
	local cargo_rail_type = AIList();
	local cargos = GetOrdedCargos();
	local rail_types = GetValuatedRailTypes();
	local industry_manager = ::ai_instance.industry_manager;
	local selected_industries = array(0);
	local total_available_money = ::ai_instance.money_manager.GetAmountReserved(reservation_id) +
		::ai_instance.money_manager.GetAvailableMoney();

	foreach(cargo , unused in cargos){
		/* Select a railtype. */
		foreach(rail_type , unused in rail_types){
			/* First check if there is money to build the track. */
			if(total_available_money < EstimateCostToBuildRailroadRoute(rail_type , RAILROAD_ROUTE_LENGTH)) continue;
			/* Try to find a locomotive. */
			aux = RailroadRoute.ChooseLocomotive(cargo , rail_type , null);
			if(aux == null) continue;
			/* Try to find a wagon. */
			aux = RailroadRoute.ChooseWagon(cargo , rail_type);
			if(aux == null) continue;
			/* The rail type has a train able to transport the cargo. So, the rail type will be stored. */
			cargo_rail_type.AddItem(cargo , rail_type);

			/* Try to find the industries. */
			local s_industries = AIIndustryList_CargoProducing(cargo);
			local d_industries = AIIndustryList_CargoAccepting(cargo);
			if(d_industries.Count() == 0) break; /* TODO: Destination may be a city. */

			s_industries.Valuate(AIIndustry.IsValidIndustry);
			s_industries.KeepValue(1);
			s_industries.Valuate(AIIndustry.IsBuiltOnWater);
			s_industries.KeepValue(0);
			if(s_industries.Count() == 0) break;

			foreach(industry , unused in s_industries){
				if(industry_manager.IsBlocked(industry) || industry_manager.IsUsed(industry) ||
					(just_primary && !AIIndustryType.IsRawIndustry(AIIndustry.GetIndustryType(industry))) ||
					(railroad_routes.len() != 0 && (AIIndustry.GetLastMonthProduction(industry , cargo) -
						AIIndustry.GetLastMonthTransported(industry , cargo)) <
						INDUSTRY_MIN_PRODUCTION)) continue;
				selected_industries.push(IndustryUsage(industry , cargo));
			}
			break;
		}
	}

 	IndustryValuator.ValuateIndustries(selected_industries);
	foreach(industry in selected_industries){
		/* First, try to connect the industry using an existent route. */
		local industry_tile = AIIndustry.GetLocation(industry.industry_id);
		if(railroad_routes.len() != 0){
			local expasions_distance = AIList();
			for(local i = 0 ; i < railroad_routes.len() ; i++){
				local railroad_route = railroad_routes[i];
				local possible_junction , djb;
				local distance;
				local paths = array(0);

				if(railroad_route.GetType() != RailroadRoute.INDUSTRY_TO_INDUSTRY) continue;

				/* Limit the number of industry_sources to avoid traffic jams. */
				if(railroad_route.industry_sources.len() >= MAX_NUM_ROUTE_SOURCES) continue;
				/* Does the industry accept the production? */
				if(!AIIndustry.IsCargoAccepted(railroad_route.d_industry , industry.cargo)) continue;
				/* There is a wagon that can deal with the cargo? */
				if(RailroadRoute.ChooseWagon(industry.cargo , railroad_route.rail_type) == null) continue;

				distance = AITile.GetDistanceManhattanToTile(industry_tile ,
					AIIndustry.GetLocation(railroad_route.d_industry));
				if((distance - RAILROAD_ROUTE_LENGTH_TOLERANCE) <= RAILROAD_ROUTE_LENGTH &&
					RAILROAD_ROUTE_LENGTH <= (distance + RAILROAD_ROUTE_LENGTH_TOLERANCE)){
					foreach(industry_source in railroad_route.industry_sources){
						paths.push(industry_source.double_railroad.path);
					}
					djb = DoubleJunctionBuilder(paths , industry_tile , JUNCTION_GAP_SIZE ,
						MAX_DISTANCE_JUNCTION_POINT);
					possible_junction = djb.GetBestPossibleJunction();
					if(possible_junction != null){
						local distance = possible_junction.distance;
						expasions_distance.AddItem(i , distance.tointeger());
					}
				}
			}
			if(expasions_distance.Count() != 0){
				expasions_distance.Sort(AIAbstractList.SORT_BY_VALUE , true);
				foreach(route_index , unused in expasions_distance){
					local railroad_route = railroad_routes[route_index];
					if(ExpandIndustryRailroadRoute(industry.industry_id , industry.cargo ,
						railroad_route , reservation_id))
						return true;
				}
			}
		}
		assert(cargo_rail_type.HasItem(industry.cargo));
		if(BuildNewIndustryRailroadRoute(industry.industry_id , industry.cargo , cargo_rail_type.GetValue(industry.cargo) , reservation_id))
			return true;
	}
	return false;
}

function RailroadManager::InvestMoneyOnTown(reservation_id){
	local selected_towns = array(0);
	local rail_types = GetValuatedRailTypes();
	local selected_rail_type = null;
	local towns;
	local town_manager = ::ai_instance.town_manager;
	local total_available_money = ::ai_instance.money_manager.GetAmountReserved(reservation_id) +
		::ai_instance.money_manager.GetAvailableMoney();

	/* Select a railtype that has a compatible locomotive and wagon. */
	foreach(rail_type , unused in rail_types){
		/* First check if there is money to build the track. */
		if(total_available_money < EstimateCostToBuildRailroadRoute(rail_type , RAILROAD_ROUTE_LENGTH)) continue;
		/* Try to find a locomotive. */
		local aux = RailroadRoute.ChooseLocomotive(passenger_cargo , rail_type , null);
		if(aux == null) continue;
		/* Try to find a wagon. */
		aux = RailroadRoute.ChooseWagon(passenger_cargo , rail_type);
		if(aux == null) continue;
		selected_rail_type = rail_type;
		break;
	}
	if(selected_rail_type == null) return false;

	/* Now select the towns. */
	towns = AITownList();
	towns.Valuate(AITown.GetPopulation);
	towns.KeepAboveValue(MIN_POPULATION);
	towns.Valuate(AITown.GetLocation);

	foreach(town , town_tile in towns){
		if(((AITile.IsSnowTile(town_tile) || AITile.IsDesertTile(town_tile)) && AITown.GetPopulation(town) < 2.5 * MIN_POPULATION) ||
			(AITown.GetLastMonthProduction(town , passenger_cargo) - AITown.GetLastMonthTransported(town , passenger_cargo)) <
			TOWN_MIN_PRODUCTION) continue;
		selected_towns.push(TownUsage(town));
	}

 	TownValuator.ValuateTowns(selected_towns);
	for(local i = 0 ; i < (selected_towns.len() - 1) ; i++){
		local town1_id = selected_towns[i].town_id;
		local town1_tile = AITown.GetLocation(town1_id);
		if(town_manager.IsBlocked(town1_id) || town_manager.IsUsed(town1_id)) continue;
		for(local j = i + 1 ; j < selected_towns.len() ; j++){
			local town2_id = selected_towns[j].town_id;
			local distance = AITile.GetDistanceManhattanToTile(town1_tile , AITown.GetLocation(town2_id));
			if(!town_manager.IsBlocked(town2_id) && !town_manager.IsUsed(town2_id) &&
				(distance - RAILROAD_ROUTE_LENGTH_TOLERANCE) <= RAILROAD_ROUTE_LENGTH &&
				RAILROAD_ROUTE_LENGTH <= (distance + RAILROAD_ROUTE_LENGTH_TOLERANCE)){
				if(BuildNewTownRailroadRoute(town1_id , town2_id , selected_rail_type , reservation_id)) return true;
			}
		}
	}
	return false;
}

/* TODO: Use parameters to configure this function: terraforming. */
function RailroadManager::BuildNewTownRailroadRoute(town1 , town2 , rail_type , reservation_id){
	local rail_types = GetValuatedRailTypes();
	local locomotive_engine , wagon_engine;
	local railroad_route = TownToTownRailroadRoute();
	local town_manager = ::ai_instance.town_manager;

	wagon_engine = RailroadRoute.ChooseWagon(passenger_cargo , rail_type);
	assert(wagon_engine != null);
	locomotive_engine = RailroadRoute.ChooseLocomotive(passenger_cargo , rail_type , null);
	assert(locomotive_engine != null);
	railroad_route.rail_type = rail_type;
	AIRail.SetCurrentRailType(rail_type);

	/* Build the stations. */
	{
		local s_m_exit_direction , d_m_exit_direction , s_s_exit_direction ,
			d_s_exit_direction , directions;

		directions = Direction.GetDirectionsToTile(AITown.GetLocation(town1) , AITown.GetLocation(town2));
		s_m_exit_direction = directions.first;
		s_s_exit_direction = directions.second;
		d_m_exit_direction = Direction.GetOppositeDirection(s_m_exit_direction);
		d_s_exit_direction = Direction.GetOppositeDirection(s_s_exit_direction);

		local town1_drtsb = DoubleRailroadTownStationBuilder(SOURCE_NUM_PLATFORMS , PLATFORM_LENGTH ,
			s_m_exit_direction , s_s_exit_direction , STATION_TERRAFORMING_MAX_COST ,
			DoubleRailroadStation.TERMINUS , town1 , true , passenger_cargo);
		railroad_route.town1_double_railroad_station = town1_drtsb.BuildRailroadStation();

		if(railroad_route.town1_double_railroad_station != null){
			local town2_drtsb = DoubleRailroadTownStationBuilder(SOURCE_NUM_PLATFORMS , PLATFORM_LENGTH ,
			d_m_exit_direction , d_s_exit_direction , STATION_TERRAFORMING_MAX_COST ,
			DoubleRailroadStation.TERMINUS , town2 , true , passenger_cargo);
			railroad_route.town2_double_railroad_station = town2_drtsb.BuildRailroadStation();
			if(railroad_route.town2_double_railroad_station == null){
				railroad_route.town1_double_railroad_station.DemolishRailroadStation();
				town_manager.Block(town2);
			}
		}else{
			town_manager.Block(town1);
			/* FIXME: need to check what was the problem. */
		}
	}

	if(railroad_route.town1_double_railroad_station == null || railroad_route.town2_double_railroad_station == null) return false;

	railroad_route.locomotive_engine = locomotive_engine;
	railroad_route.town1 = town1;
	railroad_route.town2 = town2;
	wagon_engine = RailroadRoute.ChooseWagon(passenger_cargo , railroad_route.rail_type);

	/* Create the action to build the railroad. */
	{
		local action_btttrdrr = ActionBuildTownToTownRouteDoubleRailroad();
		action_btttrdrr.railroad_route = railroad_route;
		action_btttrdrr.railroad_manager = this;
		action_btttrdrr.reservation_id = reservation_id;
		action_btttrdrr.wagon_engine = wagon_engine;
		InsertAction(action_btttrdrr);
	}
	return true;
}

/* TODO: Use parameters to configure this function: terraforming. */
/* TODO: Deal with secondary industries. */
function RailroadManager::BuildNewIndustryRailroadRoute(industry_id , cargo , rail_type , reservation_id){
	local industry_manager = ::ai_instance.industry_manager;
	local railroad_route = IndustryToIndustryRailroadRoute();
	local rail_types = GetValuatedRailTypes();
	local source_double_railroad_station;
	local wagon_engine;

	wagon_engine = RailroadRoute.ChooseWagon(cargo , rail_type);
	assert(wagon_engine != null);
	railroad_route.locomotive_engine = RailroadRoute.ChooseLocomotive(cargo , rail_type , null);
	assert(railroad_route.locomotive_engine != null);
	railroad_route.rail_type = rail_type;
	AIRail.SetCurrentRailType(rail_type);

	/* Try to find the destination industry. */
	local d_industries = AIIndustryList_CargoAccepting(cargo);
	if(d_industries.Count() == 0) return false;

	foreach(d_industry , unused in d_industries){
		if(industry_manager.IsBlocked(d_industry)) continue;
		local distance = AITile.GetDistanceManhattanToTile(AIIndustry.GetLocation(industry_id) ,
			AIIndustry.GetLocation(d_industry));
		if((distance - RAILROAD_ROUTE_LENGTH_TOLERANCE) <= RAILROAD_ROUTE_LENGTH &&
			RAILROAD_ROUTE_LENGTH <= (distance + RAILROAD_ROUTE_LENGTH_TOLERANCE)){
			railroad_route.d_industry = d_industry;
			/* Now try to construct the route. */
			local destination_double_railroad_station;
			/* Build the stations. */
			{
				local s_m_exit_direction , d_m_exit_direction , s_s_exit_direction ,
					d_s_exit_direction , directions;

				directions = Direction.GetDirectionsToTile(AIIndustry.GetLocation(industry_id) ,
					AIIndustry.GetLocation(railroad_route.d_industry));
				s_m_exit_direction = directions.first;
				s_s_exit_direction = directions.second;
				d_m_exit_direction = Direction.GetOppositeDirection(s_m_exit_direction);
				d_s_exit_direction = Direction.GetOppositeDirection(s_s_exit_direction);

				local s = DoubleRailroadIndustryStationBuilder(SOURCE_NUM_PLATFORMS , PLATFORM_LENGTH ,
					s_m_exit_direction , s_s_exit_direction , STATION_TERRAFORMING_MAX_COST ,
					DoubleRailroadStation.TERMINUS , industry_id , true);
				source_double_railroad_station = s.BuildRailroadStation();

				if(source_double_railroad_station != null){
					local d = DoubleRailroadIndustryStationBuilder(DESTINATION_NUM_PLATFORMS , PLATFORM_LENGTH ,
						d_m_exit_direction , d_s_exit_direction , STATION_TERRAFORMING_MAX_COST ,
						DoubleRailroadStation.PRE_SIGNALED , railroad_route.d_industry , false);
					destination_double_railroad_station = d.BuildRailroadStation();
					if(destination_double_railroad_station == null){
						source_double_railroad_station.DemolishRailroadStation();
						industry_manager.Block(railroad_route.d_industry);
					}
				}else{
					industry_manager.Block(industry_id);
					/* FIXME: need to check what was the problem. */
				}
			}

			if(source_double_railroad_station == null) return false;
			if(destination_double_railroad_station == null) continue;
			LogMessagesManager.PrintLogMessage("Distance between stations: " +
				AIMap.DistanceManhattan(source_double_railroad_station.station_tile ,
					destination_double_railroad_station.station_tile) + ".");

			railroad_route.destination_double_railroad_station = destination_double_railroad_station;

			/* Create the action to build the railroad. */
			{
				local action_birdrr = ActionBuildIndustryRouteDoubleRailroad();
				action_birdrr.cargo = cargo;
				action_birdrr.industry_id = industry_id;
				action_birdrr.railroad_route = railroad_route;
				action_birdrr.railroad_manager = this;
				action_birdrr.reservation_id = reservation_id;
				action_birdrr.source_double_railroad_station = source_double_railroad_station;
				action_birdrr.wagon_engine = wagon_engine;
				InsertAction(action_birdrr);
			}
			return true;
		}
	}
	return false;
}

function RailroadManager::ExpandIndustryRailroadRoute(industry_id , cargo , railroad_route , reservation_id){
	local industry_manager = ::ai_instance.industry_manager;
	local industry_tile = AIIndustry.GetLocation(industry_id);
	local industry_type = AIIndustry.GetIndustryType(industry_id);
	local junction_information , djb , source_double_railroad_station , directions , dsb , drrb;
	local possible_junction;
	local paths = array(0);
	local wagon_engine;

	foreach(industry_source in railroad_route.industry_sources){
		paths.push(industry_source.double_railroad.path);
	}
	AIRail.SetCurrentRailType(railroad_route.rail_type);
	wagon_engine = RailroadRoute.ChooseWagon(cargo , railroad_route.rail_type);
	if(wagon_engine == null) return false;

	/* Try to build the junction, the new station and the tracks. */
	djb = DoubleJunctionBuilder(paths , industry_tile , JUNCTION_GAP_SIZE , MAX_DISTANCE_JUNCTION_POINT);
	possible_junction = djb.GetBestPossibleJunction();
	if(possible_junction == null) return false;
	junction_information = possible_junction.junction_information;
	directions = Direction.GetDirectionsToTile(industry_tile , junction_information.path.tile);
	dsb = DoubleRailroadIndustryStationBuilder(SOURCE_NUM_PLATFORMS , PLATFORM_LENGTH , directions.first ,
		directions.second , STATION_TERRAFORMING_MAX_COST , DoubleRailroadStation.TERMINUS ,
		industry_id , true);
	source_double_railroad_station = dsb.BuildRailroadStation();
	if(source_double_railroad_station == null){
		industry_manager.Block(industry_id);
		return false;
	}

	djb = DoubleJunctionBuilder(paths , source_double_railroad_station.exit_part_tile , JUNCTION_GAP_SIZE ,
		MAX_DISTANCE_JUNCTION_POINT);
	/* FIXME: Junction error is here: */
	junction_information = djb.BuildJunction(source_double_railroad_station.exit_direction);
	if(junction_information == null){
		source_double_railroad_station.DemolishRailroadStation();
		industry_manager.Block(industry_id);
		return false;
	}

	/* Create the action to build the railroad. */
	{
		local action_bredrr = ActionBuildRouteExpasionDoubleRailroad();
		action_bredrr.cargo = cargo;
		action_bredrr.industry_id = industry_id;
		action_bredrr.junction_information = junction_information;
		action_bredrr.railroad_route = railroad_route;
		action_bredrr.reservation_id = reservation_id;
		action_bredrr.source_double_railroad_station = source_double_railroad_station;
		action_bredrr.wagon_engine = wagon_engine;
		InsertAction(action_bredrr);
	}
	return true;
}

function RailroadManager::InformIndustryClosure(industry_id){
	/* Check to see if some route must be demolished. */
	foreach(railroad_route in railroad_routes){
		/* TODO: Check if the station can receive the cargo. */
		if(railroad_route.GetType() == RailroadRoute.INDUSTRY_TO_INDUSTRY && railroad_route.d_industry == industry_id){
			railroad_route.MarkToBeDemolished();
		}
	}
}

function RailroadManager::CorrectNumberOfTrainsInRailroadRoutes(self){
	this = self;
	foreach(railroad_route in railroad_routes){
		assert(railroad_route != null);
		railroad_route.CorrectNumberOfTrains();
	}
	return false;
}

function RailroadManager::InsertAction(action){
	if(pending_actions.len() == 0){
		::ai_instance.scheduler.CreateTask(ExecuteActions , this , Scheduler.NO_INTERVAL);
	}
	pending_actions.push(action);
	if(action.Block()) n_railroad_routes_blocked++;
}

function RailroadManager::ExecuteActions(self){
	this = self;
	local finished_pending_actions = array(0);

	/* Execute the pending actions. */
	for(local i = 0 ; i < pending_actions.len() ; i++){
		local pending_action = pending_actions[i];
		if(pending_action.Finished()){
			if(pending_action.next_action == null){
				if(pending_action.Unblock()) n_railroad_routes_blocked--;
				finished_pending_actions.push(i);
			}else	pending_actions[i] = pending_action.next_action;
		}
	}

	/* Remove the finished pending actions. */
	finished_pending_actions.sort();
	while(finished_pending_actions.len() != 0){
		local pending_action_index = finished_pending_actions.pop();
		local length = pending_actions.len();

		/* Remove the element from the array. */
		pending_actions[pending_action_index] = pending_actions[length - 1];
		pending_actions.pop();
	}
	return pending_actions.len() == 0;
}

function RailroadManager::MaintainRailroadRoutes(self){
	local demolished_some_railroad_route = false;
	this = self;
	foreach(railroad_route_index , railroad_route in railroad_routes){
		if(railroad_route.is_blocked) continue;
		else if(railroad_route.MustBeDemolished()){
			DemolishIndustryRailroadRoute(railroad_route);
			railroad_routes[railroad_route_index] = null;
			demolished_some_railroad_route = true;
			continue;
		}else if(railroad_route.IsUnprofitable()){
			railroad_route.MarkToBeDemolished();
			continue;
		}
		/* Check if the route need more trains. */
		railroad_route.AdjustNumberOfTrains();

		/* Check if we need to change the locomotive and the rail type. */
		if(AIDate.GetCurrentDate() - railroad_route.last_locomotive_update > INTERVAL_CHANGE_LOCOMOTIVE){
			local action = railroad_route.TryToChangeLocomotiveOrRailType();
			if(action != null) InsertAction(action);
		}
	}

	/* Remove the demolished railroad routes from the array of routes.*/
	if(demolished_some_railroad_route){
		railroad_routes.sort(RailroadRoute.Compare);
		while(railroad_routes.len() > 0 && railroad_routes[railroad_routes.len() - 1] == null)
			railroad_routes.pop();
		/* Debug: */
		foreach(railroad_route in railroad_routes){
			assert(railroad_route != null);
		}
	}

	return false;
}

function RailroadManager::InvestMoneyOnRailroads(self){
	local reservation_id = null , aux = false;
	this = self;

	if(n_railroad_routes_blocked != 0) return false;

	/* We are going to create our first route. */
	/* TODO Check if it done well and diminish the distance if not. */
	if(railroad_routes.len() == 0)
		reservation_id = ::ai_instance.money_manager.ReserveMoney(0);
	else if(CanBuildNewRoute())
		reservation_id = ::ai_instance.money_manager.ReserveMoney(MIN_MONEY_TO_INVEST , (2.5 * MIN_MONEY_TO_INVEST).tointeger());

	/* If we have sufficient money we must invest it. */
	if(reservation_id != null){
		local r = AIBase.RandRange(4);

	//passar para o CanInvestMoneyOnTown
		if(r != 0 || railroad_routes.len() < MIN_INDUSTRY_INDUSTRY_ROUTES_BEFORE_TOWN_TOWN_ROUTE){
			aux = InvestMoneyOnIndustry(true , reservation_id);
		}
		if(aux == false){
			if(CanInvestMoneyOnTown())
				aux = InvestMoneyOnTown(reservation_id);
			else
				aux = InvestMoneyOnIndustry(true , reservation_id);
		}

	}
	if(aux == false && reservation_id != null)
		::ai_instance.money_manager.ReleaseReservation(reservation_id);

	return false;
}
