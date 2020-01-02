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

class IndustryManager extends GenericManager {
	/* Public: */
	function IndustryOpen(industry_id);
	function IndustryClose(industry_id);
}

function IndustryManager::IndustryOpen(industry_id){
	if(list.HasItem(industry_id)) list.RemoveItem(industry_id);
	list.AddItem(industry_id , 0);
}

function IndustryManager::IndustryClose(industry_id){
	if(list.HasItem(industry_id)) list.RemoveItem(industry_id);
}
