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

class Land {
	t = null;
	swaped_w_h = null;

	constructor(){
		t = array(4);
	}

	function _cmp(other){
		if(this.t[0] == other.t[0]){
			if(this.swaped_w_h == other.swaped_w_h) return 0;
			else if(this.swaped_w_h) return 1;
			else return -1;
		}else if(this.t[0] > other.t[0]) return 1;
		else return -1;
	}

	function _tostring(){
		return Tile.ToString(t[0]) + " " + Tile.ToString(t[1]) + " " + Tile.ToString(t[2]) +
			" " + Tile.ToString(t[3]);
	}
}

class LandAllocation {
	cost = null;
	benefit = null;
	land = null;
	diagonal = null;

	static function compare(a , b){
		if(a.cost == b.cost) return 0;
		else if(a.cost >= b.cost) return 1;
		else return -1;
	}

	function _cmp(other){
		return compare(this , other);
	}
}

class LandAllocator {
	/* Public: */

	constructor(w , h , land_validator , land_validator_param , max_cost , can_swap_w_h , cost_priority){
		this.w = w;
		this.h = h;
		this.land_validator = land_validator;
		this.land_validator_param = land_validator_param;
		this.max_cost = max_cost;
		this.can_swap_w_h = can_swap_w_h && w != h;
		this.cost_priority = cost_priority;
		checked_lands = BinaryTree();
		land_allocations = array(0);
		GenerateLandOffsets();
	}

	function GenerateTilesLands(tile);
	function GetNextBestLand();

	/* Private: */
	/* Constants: */
	static LAND_ALLOCATIONS_MAX_SIZE = 250;
	static diagonals = [[0 , 3] , [1 , 2] , [3 , 0] , [2 , 1]];

	checked_lands = null;
	land_allocations = null;
	land_offsets = null;
	w = null;
	h = null;
	land_validator = null;
	land_validator_param = null;
	max_cost = null;
	can_swap_w_h = null;
	cost_priority = null;

	static function MyLevelLand(start_tile , end_tile);
	static function IsBuildableArea(initial_tile , area_w , area_h);

	function ComputeBestLand();
	function Evaluate(c , b);
	function GenerateLandOffsets();
}

class IndustryLandAllocator {
	/* Public: */
	constructor(w , h , land_validator , land_validator_param , terraforming_max_cost , can_swap_w_h ,
		cost_priority , coverage_radius , industry){

		land_allocator = LandAllocator(w , h , land_validator , land_validator_param ,
			terraforming_max_cost , can_swap_w_h , cost_priority);

		this.industry = industry;
		this.coverage_radius = coverage_radius;
		AllocateLand();
	}
	function GetNextBestLand();

	/* Private: */
	land_allocator = null;
	industry = null;
	coverage_radius = null;

	function AllocateLand();
}

function IndustryLandAllocator::GetNextBestLand(){
	return land_allocator.GetNextBestLand();
}

function IndustryLandAllocator::AllocateLand(){
	local initial_tile = AIIndustry.GetLocation(industry) +
		AIMap.GetTileIndex(-coverage_radius , -coverage_radius);
	local area_w = 4 + coverage_radius * 2;
	local area_h = 4 + coverage_radius * 2;
	local exit = false;

 	for(local w = 0 ; w < area_w && !exit ; w++){
		for(local h = 0 ; h < area_h && !exit ; h++){
			local tile = initial_tile + AIMap.GetTileIndex(w , h);
			exit = land_allocator.GenerateTilesLands(tile);
		}
	}
	land_allocator.ComputeBestLand();
}

function LandAllocator::IsBuildableArea(initial_tile , area_w , area_h){
 	for(local w = 0 ; w < area_w ; w++){
		for(local h = 0 ; h < area_h ; h++){
			local tile = initial_tile + AIMap.GetTileIndex(w , h);
			if(!AIMap.IsValidTile(tile) || !AITile.IsBuildable(tile)) return false;
		}
	}
	return true;
}

function LandAllocator::MyLevelLand(start_tile , end_tile){
	local start_tile_height;

	assert(AIMap.IsValidTile(start_tile) && AIMap.IsValidTile(end_tile));

	if(AIMap.GetTileX(start_tile) <= AIMap.GetTileX(end_tile)){
		if(AIMap.GetTileY(start_tile) <= AIMap.GetTileY(end_tile)){
			start_tile_height = AITile.GetCornerHeight(start_tile , AITile.CORNER_N);
		}else{
			start_tile_height = AITile.GetCornerHeight(start_tile , AITile.CORNER_E);
		}
	}else{
		if(AIMap.GetTileY(start_tile) <= AIMap.GetTileY(end_tile)){
			start_tile_height = AITile.GetCornerHeight(start_tile , AITile.CORNER_W);
		}else{
			start_tile_height = AITile.GetCornerHeight(start_tile , AITile.CORNER_S);
		}
	}

	if(start_tile_height == 0) return false;

	{
		local e_x = AIMap.GetTileX(end_tile);
		local e_y = AIMap.GetTileY(end_tile);
		local s_x = AIMap.GetTileX(start_tile);
		local s_y = AIMap.GetTileY(start_tile);
		local initial_tile , area_w , area_h;


		if(s_x > e_x){
			local aux = s_x;
			s_x = e_x;
			e_x = aux;
		}

		if(s_y > e_y){
			local aux = s_y;
			s_y = e_y;
			e_y = aux;
		}

		initial_tile = AIMap.GetTileIndex(s_x , s_y);
		area_w = e_x - s_x + 1;
		area_h = e_y - s_y + 1;

		for(local w = 0 ; w < area_w ; w++){
			for(local h = 0 ; h < area_h ; h++){
				local tile = initial_tile + AIMap.GetTileIndex(w , h);
				if(!Tile.SetTileCornerHeight(tile , AITile.CORNER_N , start_tile_height)) return false;
			}
		}
		for(local w = 0 , h = area_h - 1 ; w < area_w ; w++){
			local tile = initial_tile + AIMap.GetTileIndex(w , h);
			if(!Tile.SetTileCornerHeight(tile , AITile.CORNER_E , start_tile_height)) return false;
		}
		for(local h = 0 , w = area_w - 1 ; h < area_h ; h++){
			local tile = initial_tile + AIMap.GetTileIndex(w , h);
			if(!Tile.SetTileCornerHeight(tile , AITile.CORNER_W , start_tile_height)) return false;
		}
		{
			local tile = initial_tile + AIMap.GetTileIndex(area_w - 1 , area_h - 1);
			if(!Tile.SetTileCornerHeight(tile , AITile.CORNER_S , start_tile_height)) return false;
		}
	}
	return true;
}

function LandAllocator::GenerateLandOffsets(){
	local w_less_1 = w - 1;
	local h_less_1 = h - 1;

	if(can_swap_w_h){
		land_offsets = array(8);
	}else{
		land_offsets = array(4);
	}

	land_offsets[0] = array(4);
	land_offsets[0][0] = AIMap.GetTileIndex(-w_less_1 , -h_less_1);
	land_offsets[0][1] = AIMap.GetTileIndex(0 , -h_less_1);
	land_offsets[0][2] = AIMap.GetTileIndex(-w_less_1 , 0);
	land_offsets[0][3] = AIMap.GetTileIndex(0 , 0);

	land_offsets[1] = array(4);
	land_offsets[1][0] = AIMap.GetTileIndex(0 , -h_less_1);
	land_offsets[1][1] = AIMap.GetTileIndex(w_less_1 , -h_less_1);
	land_offsets[1][2] = AIMap.GetTileIndex(0 , 0);
	land_offsets[1][3] = AIMap.GetTileIndex(w_less_1 , 0);

	land_offsets[2] = array(4);
	land_offsets[2][0] = AIMap.GetTileIndex(0 , 0);
	land_offsets[2][1] = AIMap.GetTileIndex(w_less_1 , 0);
	land_offsets[2][2] = AIMap.GetTileIndex(0 , h_less_1);
	land_offsets[2][3] = AIMap.GetTileIndex(w_less_1 , h_less_1);

	land_offsets[3] = array(4);
	land_offsets[3][0] = AIMap.GetTileIndex(-w_less_1 , 0);
	land_offsets[3][1] = AIMap.GetTileIndex(0 , 0);
	land_offsets[3][2] = AIMap.GetTileIndex(-w_less_1 , h_less_1);
	land_offsets[3][3] = AIMap.GetTileIndex(0 , h_less_1);

	if(!can_swap_w_h) return;

	land_offsets[4] = array(4);
	land_offsets[4][0] = AIMap.GetTileIndex(-h_less_1 , -w_less_1);
	land_offsets[4][1] = AIMap.GetTileIndex(0 , -w_less_1);
	land_offsets[4][2] = AIMap.GetTileIndex(-h_less_1 , 0);
	land_offsets[4][3] = AIMap.GetTileIndex(0 , 0);

	land_offsets[5] = array(4);
	land_offsets[5][0] = AIMap.GetTileIndex(0 , -w_less_1);
	land_offsets[5][1] = AIMap.GetTileIndex(h_less_1 , -w_less_1);
	land_offsets[5][2] = AIMap.GetTileIndex(0 , 0);
	land_offsets[5][3] = AIMap.GetTileIndex(h_less_1 , 0);

	land_offsets[6] = array(4);
	land_offsets[6][0] = AIMap.GetTileIndex(0 , 0);
	land_offsets[6][1] = AIMap.GetTileIndex(h_less_1 , 0);
	land_offsets[6][2] = AIMap.GetTileIndex(0 , w_less_1);
	land_offsets[6][3] = AIMap.GetTileIndex(h_less_1 , w_less_1);

	land_offsets[7] = array(4);
	land_offsets[7][0] = AIMap.GetTileIndex(-h_less_1 , 0);
	land_offsets[7][1] = AIMap.GetTileIndex(0 , 0);
	land_offsets[7][2] = AIMap.GetTileIndex(-h_less_1 , w_less_1);
	land_offsets[7][3] = AIMap.GetTileIndex(0 , w_less_1);
}

function LandAllocator::GenerateTilesLands(tile){
	local ai_test_mode = AITestMode();

	for(local i = 0 ; i < land_offsets.len() ; i++){
		local land = Land();
		local buildable_area;
		local w , h;

		land.t[0] = tile + land_offsets[i][0];
		land.t[1] = tile + land_offsets[i][1];
		land.t[2] = tile + land_offsets[i][2];
		land.t[3] = tile + land_offsets[i][3];
		land.swaped_w_h = (i >= 4);

		if(!AIMap.IsValidTile(land.t[0]) || checked_lands.Exists(land)) continue;

		if(land.swaped_w_h){
			w = this.h;
			h = this.w;
		}else{
			w = this.w;
			h = this.h;
		}
		if(IsBuildableArea(land.t[0] , w , h)){
			local user_evaluation = land_validator(land , land_validator_param);

			if(user_evaluation == 0) continue;
			for(local j = 0 ; j < 4 ; j++){
				local cost = AIAccounting();

				if(MyLevelLand(land.t[diagonals[j][0]] , land.t[diagonals[j][1]]) &&
					cost.GetCosts() <= max_cost){

					local land_allocation = LandAllocation();

					land_allocation.cost = cost.GetCosts().tofloat();
					land_allocation.benefit = user_evaluation;
					land_allocation.land = land;
					land_allocation.diagonal = j;

					land_allocations.push(land_allocation);

					if(land_allocations.len() >= LAND_ALLOCATIONS_MAX_SIZE) return true;
				}
			}
		}

		checked_lands.Insert(land);
	}
	return false;
}

function LandAllocator::Evaluate(c , b){
	return cost_priority * c + (1.0 - cost_priority) * b;
}

function LandAllocator::GetNextBestLand(){
	if(land_allocations.len() > 0){
		local land_allocation = land_allocations.pop();
		local diagonal = land_allocation.diagonal;

		if(LandAllocator.MyLevelLand(land_allocation.land.t[diagonals[diagonal][0]] ,
			land_allocation.land.t[diagonals[diagonal][1]])){
			return land_allocation.land;
		}
	}
	return null;
}

function LandAllocator::ComputeBestLand(){
	local biggest_cost = 0 , biggest_benefit = 0;

	if(land_allocations.len() <= 0) return;
	foreach(land_allocation in land_allocations){
		if(land_allocation.cost > biggest_cost) biggest_cost = land_allocation.cost;
		if(land_allocation.benefit > biggest_benefit) biggest_benefit = land_allocation.benefit;
	}

	biggest_cost = biggest_cost == 0 ? 1 : biggest_cost;
	assert(biggest_benefit > 0);

	foreach(land_allocation in land_allocations){
		land_allocation.cost = Evaluate(1.0 - (land_allocation.cost/biggest_cost) ,
			(land_allocation.benefit/biggest_benefit));
	}

	land_allocations.sort(LandAllocation.compare);
}

class TownLandAllocator {
	/* Public: */
	constructor(w , h , land_validator , land_validator_param , terraforming_max_cost , can_swap_w_h ,
		cost_priority , town){

		land_allocator = LandAllocator(w , h , land_validator , land_validator_param ,
			terraforming_max_cost , can_swap_w_h , cost_priority);

		this.town = town;
		AllocateLand();
	}
	function GetNextBestLand();

	/* Private: */
	land_allocator = null;
	town = null;

	function AllocateLand();
}

function TownLandAllocator::AllocateLand(){
	local town_tile = AITown.GetLocation(town);
	local tile_east , tile_west , tile_north , tile_south;
	local town_tiles = AITileList();

	tile_east = tile_west = tile_north = tile_south = town_tile;

	/* Try to find the smallest rectangle that limits the town area. */
	while(AITile.IsWithinTownInfluence(tile_east , town)){
		if(AIMap.IsValidTile(tile_east + AIMap.GetTileIndex(1 , 0)))
			tile_east += AIMap.GetTileIndex(1 , 0);
		else break;
	}
	while(AITile.IsWithinTownInfluence(tile_west , town)){
		if(AIMap.IsValidTile(tile_west + AIMap.GetTileIndex(-1 , 0)))
			tile_west += AIMap.GetTileIndex(-1 , 0);
		else break;
	}

	while(AITile.IsWithinTownInfluence(tile_north , town)){
		if(AIMap.IsValidTile(tile_north + AIMap.GetTileIndex(0 , 1)))
			tile_north += AIMap.GetTileIndex(0 , 1);
		else break;
	}
	while(AITile.IsWithinTownInfluence(tile_south , town)){
		if(AIMap.IsValidTile(tile_south + AIMap.GetTileIndex(0 , -1)))
			tile_south += AIMap.GetTileIndex(0 , -1);
		else break;
	}

	/* Get all tiles in this rectangle. */
	{
		local start , end;
		start = AIMap.GetTileIndex(AIMap.GetTileX(tile_east) , AIMap.GetTileY(tile_south));
		end = AIMap.GetTileIndex(AIMap.GetTileX(tile_west) , AIMap.GetTileY(tile_north));
		assert(AIMap.IsValidTile(start) && AIMap.IsValidTile(end));
		town_tiles.AddRectangle(start , end);
	}

	town_tiles.Valuate(AITile.IsBuildable);
	town_tiles.KeepAboveValue(0);
	town_tiles.Valuate(AITile.IsWithinTownInfluence, town);
	town_tiles.KeepAboveValue(0);

	foreach(tile , unused in town_tiles){
		if(land_allocator.GenerateTilesLands(tile)) break;
	}
	land_allocator.ComputeBestLand();
}

function TownLandAllocator::GetNextBestLand(){
	return land_allocator.GetNextBestLand();
}
