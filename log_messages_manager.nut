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


class LogMessagesManager {
	/* Public: */
	static function PrintMessage(message);

	/* Private: */
	static function PrintErrorMessage(message);
	static function PrintLogMessage(message);
	static function PrintWarningMessage(message);
}

function LogMessagesManager::PrintErrorMessage(message){
	AILog.Error(LogMessagesManager.GetCurrentDateString() + ": " + message);
}

function LogMessagesManager::PrintLogMessage(message){
	AILog.Info(LogMessagesManager.GetCurrentDateString() + ": " + message);
}

function LogMessagesManager::PrintWarningMessage(message){
	AILog.Warning(LogMessagesManager.GetCurrentDateString() + ": " + message);
}

function LogMessagesManager::GetCurrentDateString(){
	local now = AIDate.GetCurrentDate();
	local day = AIDate.GetDayOfMonth(now);
	local month = AIDate.GetMonth(now);

	day = day <= 9 ? "0" + day.tostring() : day.tostring();
	month = month <= 9 ? "0" + month.tostring() : month.tostring();

	return day + "/" + month + "/" + AIDate.GetYear(now).tostring();
}
