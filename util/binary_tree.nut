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


class BinaryTreeNode {
	left = null;
	right = null;
	item = null;

	constructor(item){
		this.item = item;
	}
}

class BinaryTree{
	/* Public. */
	function Insert(item);
	function Remove();
	function Count();
	function Exists(item);

	/* Private. */
	root = null;
	count = 0;

	function InorderTransversal(node);
}

function BinaryTree::Insert(item){
	count++;

	if(root == null) {
		root = BinaryTreeNode(item);
		return;
	}

	local node = root;
	while(true){
		if(node.item < item){
			if(node.left == null){
				node.left = BinaryTreeNode(item);
				break;
			}else
				node = node.left;
		}else{
			if(node.right == null){
				node.right = BinaryTreeNode(item);
				break;
			}else
				node = node.right;
		}
	}
}

function BinaryTree::Exists(item){
	local node = root;
	while(node != null){
		if(node.item < item)
			node = node.left;
		else if(node.item > item)
			node = node.right;
		else
			return true;
	}

	return false;
}

function BinaryTree::Count(){
	return count;
}

function InorderTransversal(node){
	local s = "";

	if (node == null) return s;

	s = InorderTransversal(node.left);
	s = (node.item.tostring() + ",") + s;
	s = InorderTransversal(node.right) + s;

	return s;
}

function BinaryTree::_tostring(){
	return InorderTransversal(root);
}
