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

class GameSettings {
	/* Public: */
	constructor(){
		assert(AIGameSettings.IsValid("vehicle.max_trains"));
		max_trains = AIGameSettings.GetValue("vehicle.max_trains");
		assert(AIGameSettings.IsValid("difficulty.vehicle_breakdowns"));
		vehicle_breakdowns = AIGameSettings.GetValue("difficulty.vehicle_breakdowns");
	}

	max_trains = null;
	vehicle_breakdowns = null;
}
