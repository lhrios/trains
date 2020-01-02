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


class Direction {
	static NORTH = 0;
	static SOUTH = 1;
	static WEST = 2;
	static EAST = 3;
	static INVALID_DIRECTION = 4;

	static direction_names = ["NORTH" , "SOUTH" , "WEST" , "EAST" , "INVALID_DIRECTION"];

	static function GetOppositeDirection(direction){
		switch(direction){
			case Direction.NORTH: return Direction.SOUTH;
			case Direction.SOUTH: return Direction.NORTH;
			case Direction.WEST: return Direction.EAST;
			case Direction.EAST: return Direction.WEST;
		}
	}

	static function ToString(direction){
		if(Direction.NORTH <= direction && direction <= Direction.INVALID_DIRECTION){
			return Direction.direction_names[direction];
		}else throw("Invalid direction index.");
	}

	static function GetDirectionsToTile(from_tile , to_tile){
		local f_x = AIMap.GetTileX(from_tile);
		local f_y = AIMap.GetTileY(from_tile);
		local t_x = AIMap.GetTileX(to_tile);
		local t_y = AIMap.GetTileY(to_tile);
		local main_direction , secondary_direction;

		if(abs(f_x - t_x) > abs(f_y - t_y)){
			if(f_x > t_x)
				main_direction = Direction.WEST;
			else
				main_direction = Direction.EAST;

			if(f_y > t_y)
				secondary_direction = Direction.SOUTH;
			else
				secondary_direction = Direction.NORTH;
		}else{
			if(f_y > t_y)
				main_direction = Direction.SOUTH;
			else
				main_direction = Direction.NORTH;

			if(f_x > t_x)
				secondary_direction = Direction.WEST;
			else
				secondary_direction = Direction.EAST;
		}
		return Pair(main_direction , secondary_direction);
	}
}
