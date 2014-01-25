/*******************************************************************************
 * Copyright (c) 2012-2014 Tim Molderez.
 * 
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the 3-Clause BSD License
 * which accompanies this distribution, and is available at
 * http://www.opensource.org/licenses/BSD-3-Clause
 ******************************************************************************/

package be.ac.ua.ansymo.example_bank;

import be.ac.ua.ansymo.adbc.annotations.advisedBy;
import be.ac.ua.ansymo.adbc.annotations.ensures;
import be.ac.ua.ansymo.adbc.annotations.invariant;
import be.ac.ua.ansymo.adbc.annotations.requires;

/**
 * A bank account
 * @author Tim Molderez
 */
@invariant("true")
public class Account {
	double amount;
	User owner;
	
	@requires({"amount>0",
			"owner!=null"})
	@ensures({
			"$this.amount==amount",
			"$this.owner==owner"
		})
	public Account(double amount, User owner) {
		this.amount = amount;
		this.owner = owner;
	}
	
	@requires("amount>0")
	@ensures("$this.getAmount()==$old($this.getAmount())+amount")
	public void deposit(double amount) {
		this.amount+=amount;
	}
	
	@requires("amount>0")
	@ensures("$this.getAmount()==$old($this.getAmount())-amount")
	public void withdraw(double amount) {
		this.amount-=amount;
	}
	
	@requires({
		"amount>0",
		"to!=null"})
	@ensures({
		"$this.getAmount()==$old($this.getAmount())-amount",
		"to.getAmount()==$old(to.getAmount())+amount"
		})
	@advisedBy({"be.ac.ua.ansymo.example_bank.aspects.Authentication.authenticate",
		"be.ac.ua.ansymo.example_bank.aspects.Authorization.authorize"})
	public void transfer(double amount, Account to) {
		withdraw(amount);
		to.deposit(amount);
	}
	
	public double getAmount() {
		return amount;
	}
	
	@requires("true")
	@ensures("$result!=null")
	public User getOwner() {
		return owner;
	}
}
