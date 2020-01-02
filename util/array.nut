/*
 * trAIns - An AI for OpenTTD
 * Copyright (C) 2009, 2014  Luis Henrique O. Rios
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

class Array{
	/* Public. */
	/* Removes the null elements without changing the order of non-null elements. */
	static function removeNull(array);
}

/* TODO: Is there no better implementation? */
function Array::removeNull(array){
	local new_array = [];
	for (local i = 0; i < array.len(); i++) {
		if (array[i] != null) {
			new_array.push(array[i]);
		}
	}
	for (local i = 0; i < new_array.len(); i++) {
		array[i] = new_array[i];
	}
	array.resize(new_array.len())
}

function Array::appendArray(array, array_to_be_appended){
	foreach (e in array_to_be_appended) {
		array.append(e);
	}
}
