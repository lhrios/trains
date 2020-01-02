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

class TrainManager {
	/* Public: */
	n_wagons = null;
	n_trains = null;
	wagon_engine = null;

	constructor(estimate_number_of_trains_callback , estimate_number_of_trains_callback_param ,
		get_locomotive_engine_callback , get_locomotive_engine_callback_param ,
		could_not_build_first_locomotive_callback ,  could_not_build_first_locomotive_callback_param ,
		set_train_orders_callback , set_train_orders_callback_param , wagon_engine , depot_tile , plataform_length , cargo){

		if(typeof(estimate_number_of_trains_callback) != "function")
			throw("'estimate_number_of_trains_callback' has to be a function-pointer.");
		if(typeof(get_locomotive_engine_callback) != "function")
			throw("'get_locomotive_engine_callback' has to be a function-pointer.");
		if(typeof(could_not_build_first_locomotive_callback) != "function")
			throw("'could_not_build_first_locomotive_callback' has to be a function-pointer.");
		if(typeof(set_train_orders_callback) != "function")
			throw("'set_train_orders_callback' has to be a function-pointer.");

		group = AIGroup.CreateGroup(AIVehicle.VT_RAIL);
		this.estimate_number_of_trains_callback = estimate_number_of_trains_callback;
		this.estimate_number_of_trains_callback_param = estimate_number_of_trains_callback_param;
		this.get_locomotive_engine_callback = get_locomotive_engine_callback;
		this.get_locomotive_engine_callback_param = get_locomotive_engine_callback_param;
		this.could_not_build_first_locomotive_callback = could_not_build_first_locomotive_callback;
		this.could_not_build_first_locomotive_callback_param = could_not_build_first_locomotive_callback_param;
		this.set_train_orders_callback = set_train_orders_callback;
		this.set_train_orders_callback_param = set_train_orders_callback_param;
		this.wagon_engine = wagon_engine;
		this.depot_tile = depot_tile;
		this.plataform_length = plataform_length;
		this.cargo = cargo;
	}

	function AdjustNumberOfTrains();
	function BuildTrain();
	function DeleteGroup();
	function DoesNumberOfTrainsNeedsToBeAdjusted();
	function GetCurrentNumberOfTrains();
	function GetTrainsList();

	/* Private: */
	cargo = null;
	plataform_length = null;
	depot_tile = null;
	group = null;
	n_vehicle_groups_being_selled = 0;

	estimate_number_of_trains_callback = null;
	estimate_number_of_trains_callback_param = null;
	get_locomotive_engine_callback = null;
	get_locomotive_engine_callback_param = null;
	could_not_build_first_locomotive_callback = null;
	could_not_build_first_locomotive_callback_param = null;
	set_train_orders_callback = null;
	set_train_orders_callback_param = null;
}

function TrainManager::DoesNumberOfTrainsNeedsToBeAdjusted(){
	return (n_trains == null || GetTrainsList().Count() < n_trains);
}

function TrainManager::BuildTrain(){
	local locomotive_cost , wagon_cost , total_cost;
	local locomotive , wagon;
	local locomotive_engine = get_locomotive_engine_callback(get_locomotive_engine_callback_param);
	local reservation_id;
	local source_trains;

	if(!AIEngine.IsBuildable(locomotive_engine) || !AIEngine.IsBuildable(wagon_engine)){
		::ai_instance.error_manager.SetLastError(ErrorManager.ERROR_VEHICLE_NOT_AVAILABLE);
		return false;
	}

	/* If it is the first train. */
	if(n_wagons == null){
		n_wagons = RailroadRoute.CalculateNumberOfWagons(depot_tile , locomotive_engine , wagon_engine , plataform_length);
		if(n_wagons == null) return false;
		assert(n_wagons > 0);
	}

	/* Get the locomotive cost. */
	locomotive_cost = AIEngine.GetPrice(locomotive_engine);
	/* Get the wagon cost. */
	wagon_cost = AIEngine.GetPrice(wagon_engine);

	total_cost = locomotive_cost + wagon_cost * n_wagons;
	assert(total_cost > 0);

	reservation_id = ::ai_instance.money_manager.ReserveMoney(total_cost , (1.25 * total_cost).tointeger());
	if(reservation_id == null){
		::ai_instance.error_manager.SetLastError(ErrorManager.ERROR_NOT_ENOUGH_CASH);
		return false;
	}

	/* Try to clone the train. */
	source_trains = GetTrainsList();
	if(source_trains.Count() > 0){
		locomotive = AIVehicle.CloneVehicle(depot_tile , source_trains.Begin() , true);
		if(!AIVehicle.IsValidVehicle(locomotive)){
			::ai_instance.money_manager.ReleaseReservation(reservation_id);
			::ai_instance.error_manager.SetLastError(ErrorManager.ERROR_NOT_ENOUGH_CASH);
			return false;
		}
	}else{
		locomotive = AIVehicle.BuildVehicle(depot_tile , locomotive_engine);
		if(!AIVehicle.IsValidVehicle(locomotive)){
			::ai_instance.money_manager.ReleaseReservation(reservation_id);
			::ai_instance.error_manager.SetLastError(ErrorManager.ERROR_NOT_ENOUGH_CASH);
			return false;
		}
		AIVehicle.RefitVehicle(locomotive , cargo);
		for(local i = 0 ; i < n_wagons ; i++){
			wagon = AIVehicle.BuildVehicle(depot_tile , wagon_engine);
			if(!AIVehicle.IsValidVehicle(wagon)){
				AIVehicle.SellVehicle(locomotive);
				::ai_instance.money_manager.ReleaseReservation(reservation_id);
				::ai_instance.error_manager.SetLastError(ErrorManager.ERROR_NOT_ENOUGH_CASH);
				return false;
			}
			AIVehicle.RefitVehicle(wagon , cargo);
			if(!AIVehicle.MoveWagon(wagon , 0 , locomotive , 0)){
				AIVehicle.SellVehicle(locomotive);
				AIVehicle.SellVehicle(wagon);
				::ai_instance.money_manager.ReleaseReservation(reservation_id);
				::ai_instance.error_manager.SetLastError(ErrorManager.ERROR_LOCOMOTIVE_CANNOT_PULL_WAGON);
				return false;
			}
		}

		AIGroup.MoveVehicle(group , locomotive);
		/* Deal with orders. */
		set_train_orders_callback(set_train_orders_callback_param , locomotive);
	}

	AIVehicle.StartStopVehicle(locomotive);
	::ai_instance.money_manager.ReleaseReservation(reservation_id);
	::ai_instance.error_manager.SetLastError(ErrorManager.ERROR_NONE);
	return true;
}

function TrainManager::AdjustNumberOfTrains(){
	if(n_trains == null){
		/* First it buy one train to compute the number of wagons. */
		if(!BuildTrain()){
			switch(::ai_instance.error_manager.GetLastError()){
				case ErrorManager.ERROR_NOT_ENOUGH_CASH:
				case ErrorManager.ERROR_LOCOMOTIVE_CANNOT_PULL_WAGON:
				case ErrorManager.ERROR_VEHICLE_NOT_AVAILABLE:
					if(could_not_build_first_locomotive_callback(could_not_build_first_locomotive_callback_param , cargo))
						n_wagons = null;
				break;
				case ErrorManager.ERROR_TOO_MANY_VEHICLES:
				case ErrorManager.ERROR_UNKNOWN:
				break;
				default:
					assert(0);
				break;
			}
			return;
		}
		n_trains = estimate_number_of_trains_callback(estimate_number_of_trains_callback_param);
	}

	local current_n_trains = GetCurrentNumberOfTrains();
	/* Does it need to build more trains? */
	while(current_n_trains < n_trains){
		if(BuildTrain()) current_n_trains++;
		else{
			if(::ai_instance.error_manager.GetLastError() == ErrorManager.ERROR_LOCOMOTIVE_CANNOT_PULL_WAGON &&
				could_not_build_first_locomotive_callback(could_not_build_first_locomotive_callback_param , cargo))
				n_wagons = null;
			break;
		}
	}
	/* Does it need to sell some trains? */
	if(current_n_trains > n_trains){
		local n_trains_to_sell = current_n_trains - n_trains;
		local trains = AIVehicleList_Group(group);

		trains.Valuate(AIVehicle.GetAge);
		trains.Sort(AIAbstractList.SORT_BY_VALUE , false);
		trains.KeepTop(n_trains_to_sell);

		foreach(vehicle_id , unused in trains){
			AIGroup.MoveVehicle(AIGroup.GROUP_DEFAULT , vehicle_id);
		}

		n_vehicle_groups_being_selled++;
		::ai_instance.vehicle_seller.SellVehicles(trains , TrainManager.TrainsSoldCallback , this);
	}
}

function TrainManager::TrainsSoldCallback(self){
	this = self;
	n_vehicle_groups_being_selled--;
}

function TrainManager::HasVehiclesBeingSelled(){
	return n_vehicle_groups_being_selled != 0;
}

function TrainManager::DeleteGroup(){
	local aux = AIGroup.DeleteGroup(group);
	assert(aux);
}

function TrainManager::GetTrainsList(){
	return AIVehicleList_Group(group);
}

function TrainManager::GetCurrentNumberOfTrains(){
	return GetTrainsList().Count();
}
