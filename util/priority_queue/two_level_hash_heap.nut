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

class TwoLevelHashHeap extends PriorityQueue {
	/* Public. */
	constructor(){
		bucket_hash = AIList();
		buckets_holes = AIList();
		buckets = array(0);
	}

	function Count(){
		return count;
	}

	/* Private. */
	buckets = null;
	buckets_holes = null;
	bucket_hash = null;
	count = 0;
}

function TwoLevelHashHeap::Insert(item){
	local key = item.tointeger();
	local bucket_index;

	if(bucket_hash.HasItem(key)){
		bucket_index = bucket_hash.GetValue(key);
	}else{
		if(buckets_holes.Count() > 0){
			bucket_index = buckets_holes.Begin();
			buckets_holes.RemoveTop(1);
		}else{
			bucket_index = buckets.len();
			buckets.push(null);
		}

		buckets[bucket_index] = HashHeap();
		bucket_hash.AddItem(key , bucket_index);
	}
	buckets[bucket_index].GenericInsert(item , item.h);
	count++;
}

function TwoLevelHashHeap::Pop(){
	local item , bucket_index;

	bucket_hash.Sort(AIAbstractList.SORT_BY_ITEM , true);
	bucket_index = bucket_hash.GetValue(bucket_hash.Begin());
	item = buckets[bucket_index].Pop();

	if(buckets[bucket_index].Count() == 0){
		buckets_holes.AddItem(bucket_index , 0);
		buckets[bucket_index] = null;
		bucket_hash.RemoveTop(1);
	}
	count--;
	return item;
}
