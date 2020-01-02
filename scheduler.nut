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

class Task {
	/* Public. */
	constructor(task_callback , task_callback_param , interval_between_executions){
		if(typeof(task_callback) != "function")
			throw("'task_callback' has to be a function-pointer.");

		this.task_callback = task_callback;
		this.task_callback_param = task_callback_param;
		this.interval_between_executions = interval_between_executions;
		last_execution = 0;
	}
	function Loop(now){
		if(now - last_execution >= interval_between_executions){
			local finished = task_callback(task_callback_param);
			last_execution = now;
			return finished;
		}
	}

	/* Private. */
	task_callback = null;
	task_callback_param = null;
	last_execution = null;
	interval_between_executions = null; /* In days. */
}

class Scheduler {
	/* Public. */
	/* Constants: */
	static NO_INTERVAL = 0;
	static WEEKLY_INTERVAL = 7;
	static BIWEEKLY_INTERVAL = 15;
	static TRIWEEKLY_INTERVAL = 21;
	static MONTHLY_INTERVAL = 30;
	static BIMONTHLY_INTERVAL = 60;
	static TRIMONTLY_INTERVAL = 90;
	static BIANNUAL_INTERVAL = 180;
	static ANUAL_INTERVAL = 365;

	constructor(){
		tasks = array(0);
		n_tasks_with_no_interval = 0;
	}
	function CreateTask(task_callback , task_callback_param , interval_between_executions);
	function Loop();

	/* Private. */
	tasks = null;
	n_tasks_with_no_interval = null;
}

function Scheduler::CreateTask(task_callback , task_callback_param , interval_between_executions){
	tasks.push(Task(task_callback , task_callback_param , interval_between_executions));
	if(interval_between_executions == NO_INTERVAL) n_tasks_with_no_interval++;
}

function Scheduler::Loop(){
	local now = AIDate.GetCurrentDate();
	local finished_tasks_index = array(0);

	foreach(task_index , task in tasks){
		if(task.Loop(now))
			finished_tasks_index.push(task_index);
	}

	finished_tasks_index.sort();
	while(finished_tasks_index.len() > 0){
		local length = tasks.len();
		local task_index = finished_tasks_index.pop();
		local task = tasks[task_index];

		if(task.interval_between_executions == NO_INTERVAL) n_tasks_with_no_interval--;

		/* Remove the element from the array. */
		tasks[task_index] = tasks[length - 1];
		tasks.pop();
	}

	if(n_tasks_with_no_interval == 0)
		::ai_instance.Sleep(25);
}
