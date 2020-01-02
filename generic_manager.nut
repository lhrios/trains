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


class GenericManager {
	/* Public: */
	constructor(){
		list = AIList();
		list.AddList(AIList());
	}

	function Block(id);
	function IsBlocked(id);
	function IsUsed(id);
	function MarkAsUsed(id);
	function MarkAsUnused(id);

	/* Private: */
	static BLOCKAGE_DURATION = 365 * 2;/* days. */

	list = null;
}

function GenericManager::IsUsed(id){
	if(!list.HasItem(id)){
		list.AddItem(id , 0);
		return false;
	}else{
		return (0x80000000 & list.GetValue(id)) != 0;
	}
}

function GenericManager::MarkAsUsed(id){
	if(!list.HasItem(id)){
		list.AddItem(id , 0x80000000);
	}else{
		local value = list.GetValue(id);
		list.SetValue(id , 0x80000000 | value);
	}
}

function GenericManager::MarkAsUnused(id){
	if(!list.HasItem(id)){
		list.AddItem(id , 0);
	}else{
		local value = list.GetValue(id);
		list.SetValue(id , 0x7FFFFFFF & value);
	}
}

function GenericManager::IsBlocked(id){
	if(!list.HasItem(id)){
		list.AddItem(id , 0);
		return false;
	}else{
		local value = list.GetValue(id);
		local blockage_time = value & 0x7FFFFFFF;
		if(AIDate.GetCurrentDate() - blockage_time > BLOCKAGE_DURATION){
			list.SetValue(id , value & 0x80000000);
			return false;
		}
	}
	return true;
}

function GenericManager::Block(id){
	if(!list.HasItem(id)){
		list.AddItem(id , AIDate.GetCurrentDate());
	}else{
		local value = list.GetValue(id);
		list.SetValue(id , (value & 0x80000000) | AIDate.GetCurrentDate());
	}
}

