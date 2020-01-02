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

class MoneyManager {
	/* Public: */
	constructor(){
		first_reservation_id = total_money_reserved = 0;
		reservations = AIList();
	}

	function GetAvailableMoney();
	function GetAmountReserved(reservation_id);
	function ReleaseReservation(reservation_id);
	function ReserveMoney(amount_to_reserve = 0);

	/* Private: */
	total_money_reserved = null;
	reservations = null;
	first_reservation_id = null;

	function RepayLoan();
}

function MoneyManager::ReserveMoney(min_amount_to_reserve = 0 , max_amount_to_reserve = 0){
	local amount_to_reserve;
	local bank_balance = AICompany.GetBankBalance(AICompany.COMPANY_SELF);
	local loan_amount = AICompany.GetLoanAmount();
	local max_loan_amount = AICompany.GetMaxLoanAmount();
	local total_money_available = bank_balance + max_loan_amount - loan_amount - total_money_reserved;
	assert(min_amount_to_reserve <= max_amount_to_reserve && min_amount_to_reserve >= 0);

	if(min_amount_to_reserve == 0){
		if(total_money_available <= 0){
			RepayLoan();
			return null;
		}
		AICompany.SetMinimumLoanAmount(max_loan_amount);
		amount_to_reserve = total_money_available;
	}else{
		if(total_money_available < min_amount_to_reserve){
			RepayLoan();
			return null;
		}
		amount_to_reserve = min(max_amount_to_reserve , total_money_available);
		/* Check if it is necessary to loan some money. */
		if(bank_balance - total_money_reserved < amount_to_reserve){
			AICompany.SetMinimumLoanAmount(loan_amount + (total_money_reserved + amount_to_reserve - bank_balance));
		}
	}
	reservations.AddItem(first_reservation_id , amount_to_reserve);
	total_money_reserved += amount_to_reserve;
	return first_reservation_id++;
}

function MoneyManager::ReleaseReservation(reservation_id){
	local amount_reserved;
	assert(reservation_id != null && reservations.HasItem(reservation_id));
	amount_reserved = reservations.GetValue(reservation_id);
	reservations.RemoveItem(reservation_id);
	total_money_reserved -= amount_reserved;
	if(reservations.Count() == 0) first_reservation_id = 0;
	RepayLoan();
}

function MoneyManager::RepayLoan(){
	local bank_balance = AICompany.GetBankBalance(AICompany.COMPANY_SELF);
	local available_money = bank_balance - (1.5 * total_money_reserved).tointeger();
	local loan_amount = AICompany.GetLoanAmount();
	local loan_interval = AICompany.GetLoanInterval();

	if(loan_amount > 0 && available_money > 0){
		local amount_to_pay = min(available_money , loan_amount);
		amount_to_pay -= (amount_to_pay % loan_interval);
		if(amount_to_pay > 0){
			amount_to_pay = loan_amount - amount_to_pay;
			AICompany.SetLoanAmount(amount_to_pay);
		}
	}else if(available_money <= 0){
		local amount_to_loan = (-available_money) + (loan_interval - ((-available_money) % loan_interval));
		assert(amount_to_loan % loan_interval == 0);
		if(loan_amount + amount_to_loan <= AICompany.GetMaxLoanAmount())
			AICompany.SetLoanAmount(loan_amount + amount_to_loan);
	}
}

function MoneyManager::GetAmountReserved(reservation_id){
	assert(reservation_id != null && reservations.HasItem(reservation_id));
	return reservations.GetValue(reservation_id);
}

function MoneyManager::GetAvailableMoney(){
	local aux = AICompany.GetBankBalance(AICompany.COMPANY_SELF) - total_money_reserved;
	return aux >= 0 ? aux : 0;
}

