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


/* Based on OpenTTD AStar library. */
class AStarNode {
	tile = null;
	part_index = null;
	reference_part_index = 0;
	parent_node = null;
	user_data = null;/* TODO: Choose a better name. */
	f = null;
	g = null;
	h = null;

	constructor(tile , part_index , reference_part_index , user_data , parent_node , g , h){
		this.tile = tile;
		this.part_index = part_index;
		this.reference_part_index = reference_part_index;
		this.user_data = user_data;
		this.parent_node = parent_node;
		this.g = g;
		this.h = h;
		f = g + h;
	}

	static function CompareForSearch(n1 , n2){
		if(n1.tile == n2.tile){
			if(n1.part_index == n2.part_index){
				return n1.reference_part_index - n2.reference_part_index;
			}else return n1.part_index - n2.part_index;
		}else return n1.tile - n2.tile;
	}

	static function FindNode(tile , part_index , reference_part_index , nodes){
		local left , right , middle;
		local node = AStarNode(tile , part_index , reference_part_index , null , null , 0 , 0);

		left = 0;
		right = nodes.len() - 1;
		while(left <= right){
			local aux;

			middle = (left + right)/2;
			aux = AStarNode.CompareForSearch(nodes[middle] ,  node);
			if(aux > 0)
				right = middle - 1;
			else if(aux < 0)
				left = middle + 1;
			else
				return nodes[middle];
		}
		return null;
	}

	/* Compare for Heap. */
	function _cmp(other) {
		if(this.f == other.f){
			if(this.h == other.h){
				local this_changes_direction = 0;
				local other_changes_direction = 0;
				local dtp = ::ai_instance.dtp;

				if(this.parent_node != null){
					if(dtp.ChangedDirection(this.parent_node.part_index , part_index)) this_changes_direction = 1;
					if(dtp.ChangedDirection(other.parent_node.part_index , other.part_index))
						other_changes_direction = 1;
				}

				if(this_changes_direction == other_changes_direction){
					if(dtp.IsLine(part_index)) return -1;
					else if(dtp.IsLine(other.part_index)) return 1;
					else return CompareForSearch(this , other);
				}else return this_changes_direction - other_changes_direction;
			}else return h - other.h;
		}else return f - other.f;
	}

	function _tostring(){
		return "<" + Tile.ToString(tile) + " , " + ::ai_instance.dtp.ToString(part_index) + ">";
	}

	function tointeger(){
		return f;
	}
};

class Path {
	parent_path = null;
	child_path = null;

	tile = null;
	part_index = null;
	user_data = null;
	depot_information = null;
	junction_information = null;

	constructor(node){
		tile = node.tile;
		part_index = node.part_index;
		user_data = node.user_data;
	}

	function Count() {
		local count = 1;
		local path = this;

		while(path != null){
			count++;
			path = path.child_path;
		}
		return count;
	}

	function Append(path_to_append){
		local path = this;
		while(path.child_path != null) path = path.child_path;
		path.child_path = path_to_append;
		path_to_append.parent_path = path;
	}
}

class AStar {
	/* Public: */
	constructor(cost_callback , estimate_callback , neighbours_callback , end_node_callback ,
		cost_callback_param = null , estimate_callback_param = null , neighbours_callback_param = null ,
		end_node_callback_param = null){

		if(typeof(cost_callback) != "function")
			throw("'cost_callback' has to be a function-pointer.");
		if(typeof(estimate_callback) != "function")
			throw("'estimate_callback' has to be a function-pointer.");
		if(typeof(neighbours_callback) != "function")
			throw("'neighbours_callback' has to be a function-pointer.");
		if(typeof(end_node_callback) != "function")
			throw("'end_node_callback' has to be a function-pointer.");

		this.cost_callback = cost_callback;
		this.estimate_callback = estimate_callback;
		this.neighbours_callback = neighbours_callback;
		this.end_node_callback = end_node_callback;

		this.cost_callback_param = cost_callback_param;
		this.estimate_callback_param = estimate_callback_param;
		this.neighbours_callback_param = neighbours_callback_param;
		this.end_node_callback_param = end_node_callback_param;
		dtp = ::ai_instance.dtp;
	}
	function InitializePath(sources);
	function FindPath(iterations);
	function CreateNode(tile , part_index , user_data , parent_node);

	/* Private: */
	static offsets = [[0 , 1] , [1 , 0] , [0 , -1] , [-1 , 0] , [-1 , -1] , [1 , -1] , [-1 , 1] , [1 , 1]];

	cost_callback = null;
	cost_callback_param = null;

	estimate_callback = null;
	estimate_callback_param = null;

	neighbours_callback = null;
	neighbours_callback_param = null;

	end_node_callback = null;
	end_node_callback_param = null;

	open = null;
	closed = null;
	nodes = null;
	dtp = null;

	function CreateFinalPath(node);
	function ExpandNodeNeighbours(parent_node);
	function ExpandNodeNeighboursWithFastExpansion(parent_node);
	function InsertInClosedList(tile , part_index , reference_part_index);
	function IsInClosedList(tile , part_index , reference_part_index);
	function InsertNode(node);
}

function AStar::CreateNode(tile , part_index , user_data , parent_node){
	local reference_part_index = dtp.IsBridgeOrTunnel(part_index) ? user_data.part_index : 0;
	return AStarNode(tile , part_index , reference_part_index , user_data , parent_node ,
		cost_callback(parent_node , tile , part_index , user_data , cost_callback_param) ,
		estimate_callback(parent_node , tile , part_index , user_data , estimate_callback_param));
}

/**
* Bitmap organization:
*
*	[0 ... 21]   [22 .. 25]   [26 .. 29]   [30]   [31]
*	Part Index     Tunnel       Bridge     Part  Unused
*/

function AStar::InsertInClosedList(tile , part_index , reference_part_index){
	switch(part_index){
		case DoubleTrackParts.BRIDGE:
			assert(reference_part_index != null && dtp.IsLine(reference_part_index));
			part_index = (1 << part_index) | (1 << (DoubleTrackParts.BRIDGE + 1 + 4 + reference_part_index));
		break;
		case DoubleTrackParts.TUNNEL:
			assert(reference_part_index != null && dtp.IsLine(reference_part_index));
			part_index = (1 << part_index) | (1 << (DoubleTrackParts.BRIDGE + 1 + reference_part_index));
		break;
		default:
			part_index = (1 << part_index) | (1 << (DoubleTrackParts.BRIDGE + 1 + 4 + 4));
		break;
	}
	if(closed.HasItem(tile)){
		local v = closed.GetValue(tile);
		v = v | part_index;
		closed.ChangeItem(tile , v);
	}else{
		closed.AddItem(tile , part_index);
	}
}

function AStar::IsInClosedList(tile , part_index , reference_part_index){
	if(closed.HasItem(tile)){
		local v;
		switch(part_index){
			case DoubleTrackParts.BRIDGE:
				assert(reference_part_index != null && dtp.IsLine(reference_part_index));
				part_index = (1 << part_index) | (1 << (DoubleTrackParts.BRIDGE + 1 + 4 + reference_part_index));
			break;
			case DoubleTrackParts.TUNNEL:
				assert(reference_part_index != null && dtp.IsLine(reference_part_index));
				part_index = (1 << part_index) | (1 << (DoubleTrackParts.BRIDGE + 1 + reference_part_index));
			break;
			default:
				part_index = (1 << part_index) | (1 << (DoubleTrackParts.BRIDGE + 1 + 4 + 4));
			break;
		}

		v = closed.GetValue(tile);
		if((v & part_index) == part_index) return true;
	}
	return false;
}

function AStar::InsertNode(node){
	nodes.push(node);
}

function AStar::ExpandNodeNeighboursWithFastExpansion(parent_node){
	local neighbour_nodes = neighbours_callback(parent_node , neighbours_callback_param);
	local fast_expansion_done = false;

	foreach(node in neighbour_nodes){
		if(node.g != 0){
			/* Expand fast. */
			InsertNode(node);
			InsertInClosedList((dtp.IsBridgeOrTunnel(node.part_index) ? node.user_data.start_tile : node.tile) ,
				node.part_index , node.reference_part_index);
			if(!fast_expansion_done && (node <= parent_node) && !end_node_callback(node , end_node_callback_param)){
				ExpandNodeNeighbours(node);
				fast_expansion_done = true;
			}else{
				open.Insert(node);
			}
		}
	}
}

function AStar::ExpandNodeNeighbours(parent_node){
	local neighbour_nodes = neighbours_callback(parent_node , neighbours_callback_param);

	foreach(node in neighbour_nodes){
		if(node.g != 0){
			open.Insert(node);
			InsertNode(node);
			InsertInClosedList((node.part_index == DoubleTrackParts.BRIDGE ? node.user_data.start_tile : node.tile) ,
				node.part_index , node.reference_part_index);
		}
	}
}

function AStar::InitializePath(source_nodes , ignored_nodes){
	if(typeof(source_nodes) != "array" || source_nodes.len() == 0)
		throw("'source_nodes' has to be a non-empty array.");
	if(typeof(ignored_nodes) != "array") throw("'ignored_nodes' has to be an array.");

	open = TwoLevelHashHeap();
	closed = AIList();
	nodes = array(0);/* TODO: Maybe use a hash here. */

	/* TODO: Replace ignored_nodes and source_nodes by an array of Nodes. */
	foreach(ignored_node in ignored_nodes)
		if(ignored_node[1] == DoubleTrackParts.BRIDGE){
			InsertInClosedList(ignored_node[2].user_data.start_tile , ignored_node[1] ,
				ignored_node[2].user_data.part_index);
		}else{
			InsertInClosedList(ignored_node[0] , ignored_node[1] , null);
		}

	foreach(source_node in source_nodes){
		local node = CreateNode(source_node[0] , source_node[1] , source_node[2] , null);

		assert(!end_node_callback(node , end_node_callback_param));
		InsertNode(node);
		InsertInClosedList(source_node[1] == DoubleTrackParts.BRIDGE ? source_node[2].start_tile : source_node[0] ,
			source_node[1] , node.reference_part_index);
		ExpandNodeNeighbours(node);
	}
}

function AStar::CreateFinalPath(node){
	local lowest_cost_node , parent_tile , tile , part_index , path = Path(node) , parent_path;

	nodes.sort(AStarNode.CompareForSearch);

	/* Debug: */
	/*{
		local h = AIList();
		foreach(node in nodes){
			if(h.HasItem(node.tile)){
				if(h.GetValue(node.tile) > node.g){
					h.ChangeItem(node.tile , node.g);
				}
			}else h.AddItem(node.tile , node.g);
		}
		foreach(tile , h_value in h){
			local old_h;
			{
				local t_x , t_y , g_x , g_y;
				t_x = AIMap.GetTileX(tile);
				t_y = AIMap.GetTileY(tile);
				g_x = AIMap.GetTileX(end_node_callback_param.tile_from);
				g_y = AIMap.GetTileY(end_node_callback_param.tile_from);
				old_h = max(abs(t_x - g_x) , abs(t_y - g_y)) * end_node_callback_param.PART_COST;
			}
			AISign.BuildSign(tile , h_value.tostring() + "," + old_h);
		}
	}*/


	while(true){
		lowest_cost_node = null;
		foreach(offset in offsets){
			part_index = path.part_index;

			if(part_index == DoubleTrackParts.BRIDGE){
				local user_data = path.user_data;

				tile = user_data.start_tile
				part_index = user_data.part_index;
				switch(part_index){
					case dtp.EW_LINE:
						tile += AIMap.GetTileIndex(1 , 0);
					break;
					case DoubleTrackParts.NS_LINE:
						tile += AIMap.GetTileIndex(0 , 1);
					break;
				}
			}else
				tile = path.tile;
			parent_tile = tile + AIMap.GetTileIndex(offset[0] , offset[1]);

			/* Iterate over the previous parts. */
			foreach(parent_part_index in dtp.parts[part_index].previous_parts){
				if(parent_tile + dtp.parts[parent_part_index].next_tile != tile) continue;

				node = AStarNode.FindNode(parent_tile , parent_part_index , 0 , nodes);
				if(node != null && (lowest_cost_node == null || lowest_cost_node.g > node.g))
					lowest_cost_node = node;

				/* Try to find a bridge. */
				if(dtp.IsLine(parent_part_index)){
					node = AStarNode.FindNode(parent_tile , DoubleTrackParts.BRIDGE , parent_part_index , nodes);
					if(node != null && (lowest_cost_node == null || lowest_cost_node.g > node.g))
						lowest_cost_node = node;
				}
			}
		}
		assert(lowest_cost_node != null);
		parent_path = Path(lowest_cost_node);
		path.parent_path = parent_path;
		parent_path.child_path = path;
		path = parent_path;
		if(lowest_cost_node.parent_node.parent_node == null)
			break;
	}

	return path;
}

function AStar::FindPath(max_time = -1){
	local start_date = AIDate.GetCurrentDate();

	if(open == null) throw("can't execute over an uninitialized path");

	while(open.Count() > 0 && (max_time == -1 || (AIDate.GetCurrentDate() - start_date < max_time))){
		/* Get the node with the best score so far. */
		local node = open.Pop();

		/* Debug: */
		//AISign.BuildSign(node.tile , node.g + "," + node.h + "," + node.f);

		/* Check if we found the goal. */
		if(end_node_callback(node , end_node_callback_param)){
			LogMessagesManager.PrintLogMessage("Visited nodes: " + nodes.len() + ".");
			open.PrintStatistics();
			return CreateFinalPath(node);
		/* Scan all neighbours */
		}else
			ExpandNodeNeighboursWithFastExpansion(node);
	}

	if(open.Count() > 0) return false;
	CleanPath();
	return null;
}

function AStar::CleanPath(){
	closed = null;
	open = null;
	nodes = null;
}
