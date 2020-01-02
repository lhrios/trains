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

require("include.nut");

/* Global: */
ai_instance <- null;

class trAIns extends AIController {
	/* Public: */
	dtp = null;
	error_manager = null;
	game_settings = null;
	money_manager = null;
	industry_manager = null;
	scheduler = null;
	vehicle_seller = null;
	town_manager = null;

	constructor(){
		ai_instance = this;

		dtp = DoubleTrackParts();
		error_manager = ErrorManager();
		money_manager = MoneyManager();
		industry_manager = IndustryManager();
		scheduler = Scheduler();
		railroad_manager = RailroadManager();
		vehicle_seller = VehicleSeller();
		game_settings = GameSettings();
		town_manager = TownManager();

		scheduler.CreateTask(Looping , null , Scheduler.ANUAL_INTERVAL);
		scheduler.CreateTask(VehicleSeller.Loop , vehicle_seller , Scheduler.MONTHLY_INTERVAL);
	}
	function Start();
	function Looping();

	/* Private: */
	railroad_manager = null;
}

function trAIns::Looping(unused){
	LogMessagesManager.PrintLogMessage("Looping...");
	return false;
}

function trAIns::Start(){
	/* Check some options. */
	if(AIGameSettings.IsDisabledVehicleType(AIVehicle.VT_RAIL) || game_settings.max_trains == 0){
		LogMessagesManager.PrintErrorMessage("I can only play with trains and they are disabled.");
		return;
	}

	/* Change the company name. */
	{
		local i = 0 , company_name = "trAIns AI";
		while(!AICompany.SetName(company_name)){
			company_name = "trAIns AI #" + ++i;
		}
	}

	while(true){
		/* Handle the events. */
		while(AIEventController.IsEventWaiting()) {
			local e = AIEventController.GetNextEvent();
			switch(e.GetEventType()){
				case AIEvent.AI_ET_VEHICLE_WAITING_IN_DEPOT:
					local vehicle_id = AIEventVehicleWaitingInDepot.Convert(e).GetVehicleID();
					vehicle_seller.TreatEventVehicleWaitingInDepot(vehicle_id);
				break;
				case AIEvent.AI_ET_INDUSTRY_OPEN:
					local industry_id = AIEventIndustryOpen.Convert(e).GetIndustryID();
					industry_manager.IndustryOpen(industry_id);
				break;
				case AIEvent.AI_ET_INDUSTRY_CLOSE:
					local industry_id = AIEventIndustryClose.Convert(e).GetIndustryID();
					industry_manager.IndustryClose(industry_id);
					railroad_manager.InformIndustryClosure(industry_id);
				break;
				case AIEvent.AI_ET_ENGINE_PREVIEW:
					AIEventEnginePreview.Convert(e).AcceptPreview();
				break;
			}
		}

		scheduler.Loop();
	}
}
