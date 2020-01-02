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


class ErrorManager {
	/* Public: */
	/* Constants: */
	static ERROR_NONE = 0;
	static ERROR_NOT_ENOUGH_CASH = 1;
	static ERROR_UNKNOWN = 2;
	static ERROR_TOO_MANY_VEHICLES = 3;
	static ERROR_LOCOMOTIVE_CANNOT_PULL_WAGON = 4;
	static ERROR_VEHICLE_NOT_AVAILABLE = 5;

	constructor(){
		last_error = ERROR_NONE;
	}

	function SetLastError(error){
		last_error = error;
	}

	function GetLastError(){
		return last_error;
	}

	/* Private: */
	last_error = null;
}
