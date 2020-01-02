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


class trAIns extends AIInfo {
   function GetAuthor(){
		return "Luis Henrique O. Rios";
	}
   function GetName(){
		return "trAIns";
	}
   function GetShortName(){
		return "TRAI";
	}
   function GetDescription(){
		return "trAIns is a competitive AI that plays only with trains. It creates and manages railroad routes that connects industries and railroad routes that connects two towns. The last can transport passengers. It is also partially compatible with NARS and 2CC.";
	}
   function GetVersion(){
		return 2;
	}
   function CanLoadFromVersion(version){
      return false;
   }
   function GetDate(){
		return "2010-07-02";
	}
   function CreateInstance(){
		return "trAIns";
	}
   function GetSettings(){
   }
	function MinVersionToLoad(){
		return 2;
	}
	function GetAPIVersion(){
		return "1.0";
	}
	function UseAsRandomAI(){
		return true;
	}
	function GetURL(){
		return "http://www.dcc.ufmg.br/~lhrios/trains/";
	}
};

RegisterAI(trAIns());
