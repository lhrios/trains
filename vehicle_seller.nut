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


class VehicleSeller {
	/* Public: */
	constructor(){
		vehicle_lists_to_sell = array(0);
	}
	function Loop(self);
	function SellVehicles(vehicles , vehicles_sold_callback , vehicles_sold_callback_param);
	function TreatEventVehicleWaitingInDepot(vehicle_id);

	/* Private: */
	vehicle_lists_to_sell = null;
}

class VehicleListToSell {
	/* Public: */
	constructor(vehicles , vehicles_sold_callback , vehicles_sold_callback_param){
		this.vehicles = AIList();
		this.vehicles.AddList(vehicles);
		this.vehicles.Valuate(AIVehicle.GetEngineType);

		if(vehicles_sold_callback != null && typeof(vehicles_sold_callback) != "function")
			throw("'vehicles_sold_callback' has to be a function-pointer.");

		this.vehicles_sold_callback = vehicles_sold_callback;
		this.vehicles_sold_callback_param = vehicles_sold_callback_param;

		SendVehiclesToDepot(true);
		MoveVehiclesToDefaultGroup();
	}
	function HasVehicle(vehicle_id);
	function RemoveVehicle(vehicle_id);
	function SendVehiclesToDepot(force);

	/* Private: */
	vehicles = null;
	vehicles_sold_callback = null;
	vehicles_sold_callback_param = null;

	function MoveVehiclesToDefaultGroup();
}

function VehicleListToSell::HasVehicle(vehicle_id){
	return vehicles.HasItem(vehicle_id) &&
		AIVehicle.GetEngineType(vehicle_id) == vehicles.GetValue(vehicle_id);
}

function VehicleListToSell::RemoveVehicle(vehicle_id){
	AIVehicle.SellVehicle(vehicle_id);
	vehicles.RemoveItem(vehicle_id);
	return vehicles.Count() == 0;
}

function VehicleListToSell::SendVehiclesToDepot(force){
	foreach(vehicle_id , dummmy in vehicles){
		if(AIVehicle.GetState(vehicle_id) == AIVehicle.VS_STOPPED)
				AIVehicle.StartStopVehicle(vehicle_id);
		if(force ||
			!AIRail.IsRailDepotTile(AIOrder.GetOrderDestination(vehicle_id, AIOrder.ORDER_CURRENT)))
			AIVehicle.SendVehicleToDepot(vehicle_id);

	}
}

function VehicleListToSell::MoveVehiclesToDefaultGroup(){
	foreach(vehicle_id , dummmy in vehicles){
		AIGroup.MoveVehicle(AIGroup.GROUP_DEFAULT , vehicle_id);
	}
}

function VehicleSeller::SellVehicles(vehicles , vehicles_sold_callback , vehicles_sold_callback_param){
	if(vehicles.Count() == 0){
		if(vehicles_sold_callback != null)
			vehicles_sold_callback(vehicles_sold_callback_param);
	}else{
		vehicle_lists_to_sell.push(VehicleListToSell(vehicles , vehicles_sold_callback ,
			vehicles_sold_callback_param));
	}
}

function VehicleSeller::TreatEventVehicleWaitingInDepot(vehicle_id){
	for(local i = 0 ; i < vehicle_lists_to_sell.len() ; i++){
		local vehicle_list_to_sell = vehicle_lists_to_sell[i];
		if(vehicle_list_to_sell.HasVehicle(vehicle_id)){
			local has_not_more_vehicles;
			has_not_more_vehicles = vehicle_list_to_sell.RemoveVehicle(vehicle_id);
			if(has_not_more_vehicles){
				local length = vehicle_lists_to_sell.len();
				/* Remove the element from the array. */
				vehicle_lists_to_sell[i] = vehicle_lists_to_sell[length - 1];
				vehicle_lists_to_sell.pop();

				if(vehicle_list_to_sell.vehicles_sold_callback != null)
					vehicle_list_to_sell.vehicles_sold_callback(
						vehicle_list_to_sell.vehicles_sold_callback_param);
			}
			break;
		}
	}
}

function VehicleSeller::Loop(self){
	foreach(vehicle_list_to_sell in self.vehicle_lists_to_sell){
		vehicle_list_to_sell.SendVehiclesToDepot(false);
	}
	return false;
}
