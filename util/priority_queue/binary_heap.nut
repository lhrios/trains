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

class BinaryHeap extends PriorityQueue {
	/* Public: */
	constructor(){
		items = array(0);
	}

	function Peek(){
		return items[0];
	}

	function Count(){
		return count;
	}

	/* Private: */
	items = null;
	count = 0;

	function RedoHeap();
};

function BinaryHeap::Insert(new_item){
	local i = items.len() , j , item;

	items.push(new_item);

	j = (i - 1) / 2;
	while(i > 0 && items[j] > items[i]){
		item = items[i];
		items[i] = items[j];
		items[j] = item;
		i = j;
		j = (i - 1) / 2;
	}
	count++;
}

function BinaryHeap::Pop(){
	local item = items[0];
	items[0] = items[items.len() - 1];
	items.pop();
	RedoHeap();
	count--;
	return item;
}

function BinaryHeap::RedoHeap(){
	local i , j , item  , length = items.len();

	if(length == 0) return;

	i = 0;
	j = i * 2 + 1;
	item = items[0];
	while(j < length){
		if(j + 1 < length && items[j] > items[j + 1]) j++;
		if(item <= items[j]) break;
		items[i] = items[j];
		i = j;
		j = i * 2 + 1;
	}
	items[i] = item;
}
