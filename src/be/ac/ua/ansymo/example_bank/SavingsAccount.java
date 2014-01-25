/*******************************************************************************
 * Copyright (c) 2012-2014 Tim Molderez.
 * 
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the 3-Clause BSD License
 * which accompanies this distribution, and is available at
 * http://www.opensource.org/licenses/BSD-3-Clause
 ******************************************************************************/

package be.ac.ua.ansymo.example_bank;

import be.ac.ua.ansymo.adbc.annotations.ensures;
import be.ac.ua.ansymo.adbc.annotations.requires;

/**
 * A savings account; the money on a savings account can only be transferred to accounts with the same owner
 * (This means a savings account is *not* a behavioural subtype, as the precondition of the transfer() method is too strong.)
 * @author Tim Molderez
 */
public class SavingsAccount extends Account {
	public SavingsAccount(double amount, User owner) {
		super(amount, owner);
	}
	
	@requires({
		"$super && $this.getOwner()==to.getOwner()"})
	@ensures({
		"$super"
		})
	public void transfer(double amount, Account to) {
		withdraw(amount);
		to.deposit(amount);
		
	}
}
