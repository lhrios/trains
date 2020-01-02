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


class Tile {
	static function ToString(tile);
	static function GetFlatTile(tile , max_radius);
	static function EuclideanDistance(t1 , t2);
	static function GetFlatSlopeTileHeight(tile);
	static function SetTileCornerHeight(tile , corner , height);
	
	static function DistanceX(t1, t2);
	static function DistanceY(t1, t2);

	static neighbours_tiles_offset = [[0 , 0] , [0 , 1] , [1 , 0] , [1 , 1]];
}

function Tile::SetTileCornerHeight(tile , corner , height){
	local tile_height = AITile.GetCornerHeight(tile , corner);
	local difference = height - tile_height;
	local slope;

	switch(corner){
		case AITile.CORNER_W:
			slope = AITile.SLOPE_W;
		break;
		case AITile.CORNER_S:
			slope = AITile.SLOPE_S;
		break;
		case AITile.CORNER_E:
			slope = AITile.SLOPE_E;
		break;
		case AITile.CORNER_N:
			slope = AITile.SLOPE_N;
		break;
		default:
			assert(false);
		break;
	}

	while(difference > 0){
		if(!AITile.RaiseTile(tile , slope)) return false;
		difference--;
	}
	while(difference < 0){
		if(!AITile.LowerTile(tile , slope)) return false;
		difference++;
	}
	return true;
}

function Tile::GetFlatSlopeTileHeight(tile){
	local tile_height = 0;

	foreach(offset in Tile.neighbours_tiles_offset){
		local height = AITile.GetCornerHeight(tile + AIMap.GetTileIndex(offset[0] , offset[1]) ,
			AITile.CORNER_N);
		if(tile_height < height) tile_height = height;
	}
	return tile_height;
}

function Tile::ToString(tile){
	local s = "0x";
	local had_first_non_zero = false;

	for(local i = 7 ; i >= 0 ; i--){
		local aux = (tile & (0xF << (i * 4))) >>> (i * 4);
		if(aux >= 10) s += ('A' + (aux - 10)).tochar();
		else{
			if(aux != 0 || had_first_non_zero){
				s += ('0' + aux).tochar();
			}
		}

		if(aux != 0) had_first_non_zero = true;
	}
	if(s == "0x") s = "0x0";
	return s;
}

function Tile::GetFlatTile(tile , max_radius = 25){
	local radius = 0;

	/* Iterate over the tiles creating a disk around the "tile" using manhattan distance definition. */
	while(radius < max_radius){
		local x , y , t , tiles = array(0);

		x = radius;
		y = 0;
		while(x >= 0){
			if(x){
				if(y){
					t = tile + AIMap.GetTileIndex(x , y);
					tiles.push(t);
					t = tile + AIMap.GetTileIndex(-x , y);
					tiles.push(t);
					t = tile + AIMap.GetTileIndex(x , -y);
					tiles.push(t);
					t = tile + AIMap.GetTileIndex(-x , -y);
					tiles.push(t);
				}else{
					t = tile + AIMap.GetTileIndex(x , y);
					tiles.push(t);
					t = tile + AIMap.GetTileIndex(-x , y);
					tiles.push(t);
				}
			}else{
				if(y){
					t = tile + AIMap.GetTileIndex(x , y);
					tiles.push(t);
					t = tile + AIMap.GetTileIndex(x , -y);
					tiles.push(t);
				}else{
					t = tile + AIMap.GetTileIndex(x , y);
					tiles.push(t);
				}
			}
			x--;
			y++;
		}
		radius++;
		foreach(tile in tiles){
			if(AIMap.IsValidTile(tile) && AITile.IsBuildable(tile) &&
				AITile.GetSlope(tile) == AITile.SLOPE_FLAT) return tile;
		}
	}
	return null;
}

function Tile::DistanceX(t1, t2){
	return abs(AIMap.GetTileX(t1) - AIMap.GetTileX(t2));
}

function Tile::DistanceY(t1, t2){
	return abs(AIMap.GetTileY(t1) - AIMap.GetTileY(t2));	
}

function Tile::EuclideanDistance(t1 , t2){
	return sqrt(AIMap.DistanceSquare(t1 , t2));
}
