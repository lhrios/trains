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

class RailroadRoute {
	/* Public: */

	/* Constants: */
	static MIN_NUMBER_OF_SAMPLES = 10;

	static MIN_RELIABILITY_BEFORE_GOTO_DEPOT_WITH_NORMAL_BREAKDOWNS = 80;
	static MIN_RELIABILITY_BEFORE_GOTO_DEPOT_WITH_REDUCED_BREAKDOWNS = 70;

	static TOWN_TO_TOWN = 0;
	static INDUSTRY_TO_TOWN = 1;
	static INDUSTRY_TO_INDUSTRY = 2;

	locomotive_engine = null;
	rail_type = null;
	last_locomotive_update = null;
	is_blocked = false;

	static function CalculateNumberOfWagons(depot_tile , locomotive_engine , wagon_engine , plataform_length);
	static function ChooseWagon(cargo , rail_type);
	static function ChooseLocomotive(cargo , rail_type , locomotive_max_price);
	static function Compare(a , b){
		if(a == null && b == null) return 0;
		else if(a == null) return 1;
		return -1;
	}
	static function GetEvaluatedLocomotiveEnginesList(cargo , rail_type , locomotive_max_price);
	static function GetTotalNumberOfTrains();
	static function SetTrainOrders(locomotive , station1_tile , depot1_tile , order_flags1 ,
		station2_tile , depot2_tile , order_flags2);

	function AdjustNumberOfTrains();
	function CouldNotBuildFirstLocomotive(self , cargo);
	function ConvertRailroadRoute(rail_type);
	function CorrectNumberOfTrains();
	function DemolishRailroadRoute();
	function DoesNumberOfTrainsNeedsToBeAdjusted();
	function EstimateCostToConvertRailroadRoute(rail_type);
	function GetActionSellRailroadRouteTrains(next_action);
	function GetActionDemolishRailroadRoute(next_action);
	function GetType();
	function GetTrainsList();
	function HasVehiclesBeingSelled();
	function HasTrafficJam();
	function InformLocomotiveChange(new_rail_type , new_locomotive_engine);
	function IsUnprofitable();
	function MarkToBeDemolished();
	function MustBeDemolished();
	function TryToChangeLocomotiveOrRailType();

	/* Private: */
	static engines_length = AIList();
	static blocked_locomotive_engines = AIList();

	must_be_demolished = false;
}

function RailroadRoute::SetTrainOrders(locomotive , station1_tile , depot1_tile , order_flags1 , station2_tile , depot2_tile ,
	order_flags2){

	local vehicle_breakdowns = ::ai_instance.game_settings.vehicle_breakdowns;

	AIOrder.AppendOrder(locomotive , station1_tile , order_flags1);
	if(vehicle_breakdowns > 0){
		AIOrder.AppendOrder(locomotive , depot1_tile , AIOrder.AIOF_NONE);
	}
	AIOrder.AppendOrder(locomotive , station2_tile , order_flags2);

	if(vehicle_breakdowns > 0){
		local min_reliabilty = vehicle_breakdowns == 1 ?
			RailroadRoute.MIN_RELIABILITY_BEFORE_GOTO_DEPOT_WITH_REDUCED_BREAKDOWNS :
			RailroadRoute.MIN_RELIABILITY_BEFORE_GOTO_DEPOT_WITH_NORMAL_BREAKDOWNS;

		AIOrder.InsertConditionalOrder(locomotive , 1 , 2);
		AIOrder.SetOrderCondition(locomotive , 1 , AIOrder.OC_RELIABILITY);
		AIOrder.SetOrderCompareFunction(locomotive , 1 , AIOrder.CF_MORE_EQUALS);
		AIOrder.SetOrderCompareValue(locomotive , 1 , min_reliabilty);

		AIOrder.InsertConditionalOrder(locomotive , 4 , 0);
		AIOrder.SetOrderCondition(locomotive , 4 , AIOrder.OC_RELIABILITY);
		AIOrder.SetOrderCompareFunction(locomotive , 4 , AIOrder.CF_MORE_EQUALS);
		AIOrder.SetOrderCompareValue(locomotive , 4 , min_reliabilty);
		AIOrder.AppendOrder(locomotive , depot2_tile , AIOrder.AIOF_NONE);
	}
}

function RailroadRoute::CalculateNumberOfWagons(depot_tile , locomotive_engine , wagon_engine , plataform_length){
	local locomotive_length = null , wagon_length = null;
	local locomotive_cost , wagon_cost , total_cost;
	local reservation_id;

	/* Get the locomotive cost. */
	locomotive_cost = AIEngine.GetPrice(locomotive_engine);
	/* Get the wagon cost. */
	wagon_cost = AIEngine.GetPrice(wagon_engine);
	total_cost = locomotive_cost + wagon_cost;

	reservation_id = ::ai_instance.money_manager.ReserveMoney(total_cost , (1.25 * total_cost).tointeger());

	if(reservation_id == null){
		::ai_instance.error_manager.SetLastError(ErrorManager.ERROR_NOT_ENOUGH_CASH);
		return null;
	}

	if(RailroadRoute.engines_length.HasItem(locomotive_engine)){
		locomotive_length = RailroadRoute.engines_length.GetValue(locomotive_engine);
	}else{
		local locomotive = AIVehicle.BuildVehicle(depot_tile , locomotive_engine);
		if(!AIVehicle.IsValidVehicle(locomotive)){
			::ai_instance.money_manager.ReleaseReservation(reservation_id);
			switch(AIError.GetLastError()){
				case AIError.ERR_NOT_ENOUGH_CASH:
					::ai_instance.error_manager.SetLastError(ErrorManager.ERROR_NOT_ENOUGH_CASH);
				break;
				case AIVehicle.ERR_VEHICLE_TOO_MANY:
					::ai_instance.error_manager.SetLastError(ErrorManager.ERROR_TOO_MANY_VEHICLES);
				break;
				case AIError.ERR_UNKNOWN:
					::ai_instance.error_manager.SetLastError(ErrorManager.ERROR_UNKNOWN);
				break;
				default:
					throw("I could not build the locomotive: " + AIError.GetLastErrorString() + ".");
				break;
			}
			return null;
		}
		locomotive_length = AIVehicle.GetLength(locomotive);
		RailroadRoute.engines_length.AddItem(locomotive_engine , locomotive_length);
		AIVehicle.SellVehicle(locomotive);
	}

	if(RailroadRoute.engines_length.HasItem(wagon_engine)){
		wagon_length = RailroadRoute.engines_length.GetValue(wagon_engine);
	}else{
		local wagon = AIVehicle.BuildVehicle(depot_tile , wagon_engine);
		if(!AIVehicle.IsValidVehicle(wagon)){
			::ai_instance.money_manager.ReleaseReservation(reservation_id);
			switch(AIError.GetLastError()){
				case AIError.ERR_NOT_ENOUGH_CASH:
					::ai_instance.error_manager.SetLastError(ErrorManager.ERROR_NOT_ENOUGH_CASH);
				break;
				case AIVehicle.ERR_VEHICLE_TOO_MANY:
					::ai_instance.error_manager.SetLastError(ErrorManager.ERROR_TOO_MANY_VEHICLES);
				break;
				case AIError.ERR_UNKNOWN:
					::ai_instance.error_manager.SetLastError(ErrorManager.ERROR_UNKNOWN);
				break;
				default:
				throw("I could not build the wagon: " + AIError.GetLastErrorString() + ".");
				break;
			}
			return null;
		}
		wagon_length = AIVehicle.GetLength(wagon);
		RailroadRoute.engines_length.AddItem(wagon_engine , wagon_length);
		AIVehicle.SellVehicle(wagon);
	}
	::ai_instance.money_manager.ReleaseReservation(reservation_id);

	/* Calculate the number of wagons. */
	return (plataform_length * 16 - locomotive_length) / wagon_length;
}

function RailroadRoute::ChooseLocomotive(cargo , rail_type , locomotive_max_price){
	local engines = RailroadRoute.GetEvaluatedLocomotiveEnginesList(cargo , rail_type , locomotive_max_price);
	engines.Sort(AIAbstractList.SORT_BY_VALUE , false);
	return engines.Count() == 0 ? null : engines.Begin();
}

function RailroadRoute::ChooseWagon(cargo , rail_type){
	local engines = AIEngineList(AIVehicle.VT_RAIL);
	engines.Valuate(AIEngine.IsValidEngine);
	engines.KeepValue(1);
	engines.Valuate(AIEngine.IsWagon);
	engines.KeepValue(1);
	engines.Valuate(AIEngine.CanRunOnRail , rail_type);
	engines.KeepValue(1);
	engines.Valuate(AIEngine.CanRefitCargo , cargo);
	engines.KeepValue(1);
	engines.Valuate(AIEngine.GetPrice);
	engines.Sort(AIAbstractList.SORT_BY_VALUE , true);
	return engines.Count() == 0 ? null : engines.Begin();
}

function RailroadRoute::GetEvaluatedLocomotiveEnginesList(cargo , rail_type , locomotive_max_price){
	local engines = AIEngineList(AIVehicle.VT_RAIL);
	engines.Valuate(AIEngine.IsValidEngine);
	engines.KeepValue(1);
	engines.Valuate(AIEngine.IsWagon);
	engines.KeepValue(0);
	if(rail_type != null){
		engines.Valuate(AIEngine.CanRunOnRail , rail_type);
		engines.KeepValue(1);
		engines.Valuate(AIEngine.HasPowerOnRail , rail_type);
		engines.KeepValue(1);
		engines.Valuate(AIEngine.GetRailType);
		engines.KeepValue(rail_type);
	}
	if(cargo != null){
		engines.Valuate(AIEngine.CanPullCargo , cargo);
		engines.KeepValue(1);
	}
	if(locomotive_max_price != null){
		engines.Valuate(AIEngine.GetPrice);
		engines.KeepBelowValue(locomotive_max_price.tointeger());
	}

	engines.RemoveList(RailroadRoute.blocked_locomotive_engines);

	local lv = LocomotiveValuator(engines);
	engines.Valuate(LocomotiveValuator.ValuateLocomotive , lv);
	return engines;
}

function RailroadRoute::GetTotalNumberOfTrains(){
	local trains = AIVehicleList();
	trains.Valuate(AIVehicle.GetVehicleType);
	trains.KeepValue(AIVehicle.VT_RAIL);
	trains.Valuate(AIVehicle.GetGroupID);
	trains.RemoveValue(AIGroup.GROUP_DEFAULT);
	return trains.Count();
}

function RailroadRoute::MarkToBeDemolished(){
	must_be_demolished = true;
}

function RailroadRoute::MustBeDemolished(){
	return must_be_demolished;
}

function RailroadRoute::CouldNotBuildFirstLocomotive(self , cargo){
	this = self;
	local money_manager = ::ai_instance.money_manager;

	switch(::ai_instance.error_manager.GetLastError()){
		case ErrorManager.ERROR_VEHICLE_NOT_AVAILABLE:
			/* TODO Treat the error. */
			LogMessagesManager.PrintLogMessage("The locomotive \"" + AIEngine.GetName(locomotive_engine) + "\" is not available anymore.");
			return false;
		case ErrorManager.ERROR_LOCOMOTIVE_CANNOT_PULL_WAGON:
			LogMessagesManager.PrintLogMessage("The locomotive \"" + AIEngine.GetName(locomotive_engine) + "\" will be blocked." +
					" I will select a new one.");
			RailroadRoute.blocked_locomotive_engines.AddItem(locomotive_engine , 0);
		break;

		case ErrorManager.ERROR_NOT_ENOUGH_CASH:
			if(RailroadRoute.GetTotalNumberOfTrains() != 0) return false;
			LogMessagesManager.PrintLogMessage("The locomotive model selected (\"" + AIEngine.GetName(locomotive_engine) +
				")\" is too expensive. I will select a new one.");
		break;
		default:
			assert(0);
		break;
	}

	local reservation_id = money_manager.ReserveMoney(0);
	if(reservation_id != null){
		locomotive_engine = RailroadRoute.ChooseLocomotive(cargo , rail_type ,
			(money_manager.GetAmountReserved(reservation_id) * 0.75).tointeger());
		if(locomotive_engine == null){
			MarkToBeDemolished();
			LogMessagesManager.PrintLogMessage("There is no locomotive. The route will be demolished.");
			money_manager.ReleaseReservation(reservation_id);
		}else{
			LogMessagesManager.PrintLogMessage("The new locomotive model selected is \"" +
				AIEngine.GetName(locomotive_engine) + "\".");
			money_manager.ReleaseReservation(reservation_id);
			return true;
		}
	}else{
		MarkToBeDemolished();
		LogMessagesManager.PrintLogMessage("There is no locomotive. The route will be demolished.");
	}
	return false;
}

function RailroadRoute::TryToChangeLocomotiveOrRailType(){
	local engines = RailroadRoute.GetEvaluatedLocomotiveEnginesList(null , null , null);
	local message;
	local new_locomotive_engine = engines.Begin() , old_locomotive_engine;

	if(engines.GetValue(locomotive_engine) < engines.GetValue(new_locomotive_engine)){
		local action_crrrt = null;
		local new_rail_type;

		if(AIEngine.CanRunOnRail(new_locomotive_engine , rail_type) && AIEngine.HasPowerOnRail(new_locomotive_engine , rail_type)){
			message = "I am going to change the route locomotive to " + AIEngine.GetName(new_locomotive_engine) + ".";
			new_rail_type = rail_type;
		}else{
			if(HasVehiclesBeingSelled()) return null;
			message = "I am going to change the route rail type to use the locomotive " + AIEngine.GetName(new_locomotive_engine) + ".";
			new_rail_type = AIEngine.GetRailType(new_locomotive_engine);
			action_crrrt = ActionConvertRailroadRouteRailType();
			action_crrrt.new_rail_type = new_rail_type;
			action_crrrt.railroad_route = this;
		}

		/* Check now if there is sufficient money. */
		{
			local cost = 0;
			if(rail_type != new_rail_type) cost += EstimateCostToConvertRailroadRoute(new_rail_type);
			cost += (AIEngine.GetPrice(new_locomotive_engine) * 1.10).tointeger();
			if(cost > ::ai_instance.money_manager.GetAvailableMoney()) return null;
		}

		old_locomotive_engine = locomotive_engine;
		if(!InformLocomotiveChange(new_rail_type , new_locomotive_engine)){
			LogMessagesManager.PrintLogMessage("The locomotive \"" + AIEngine.GetName(new_locomotive_engine) + "\" will be blocked.");
			RailroadRoute.blocked_locomotive_engines.AddItem(new_locomotive_engine , 0);
			return null;
		}
		LogMessagesManager.PrintLogMessage(message);
		LogMessagesManager.PrintLogMessage(AIEngine.GetName(old_locomotive_engine) + ": " + engines.GetValue(old_locomotive_engine) + ".");
		LogMessagesManager.PrintLogMessage(AIEngine.GetName(new_locomotive_engine) + ": " + engines.GetValue(new_locomotive_engine) + ".");
		last_locomotive_update = AIDate.GetCurrentDate();

		/* If it change just the locomotive. */
		if(rail_type == new_rail_type) AdjustNumberOfTrains();
		return GetActionSellRailroadRouteTrains(action_crrrt);
	}
	return null;
}

function RailroadRoute::GetActionSellRailroadRouteTrains(next_action){
	local action_srrt = ActionSellRailroadRouteTrains();
	local vehicle_seller = ::ai_instance.vehicle_seller;

	action_srrt.railroad_route = this;
	action_srrt.next_action = next_action;
	action_srrt.must_block = next_action != null;
	action_srrt.finished = false;

	/* Now sell the old trains. */
	vehicle_seller.SellVehicles(GetTrainsList() , ActionSellRailroadRouteTrains.TrainsSoldCallback ,
		action_srrt);
	return action_srrt;
}

function RailroadRoute::GetActionDemolishRailroadRoute(next_action){
	local action_drr = ActionDemolishRailroadRoute();
	local action_srrt = GetActionSellRailroadRouteTrains(action_drr);

	action_drr.railroad_route = this;
	action_drr.next_action = next_action;

	return action_srrt;
}
