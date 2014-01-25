/*******************************************************************************
 * Copyright (c) 2012-2014 Tim Molderez.
 * 
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the 3-Clause BSD License
 * which accompanies this distribution, and is available at
 * http://www.opensource.org/licenses/BSD-3-Clause
 ******************************************************************************/

package be.ac.ua.ansymo.example_bank.aspects;

import java.util.HashSet;

import org.aspectj.lang.annotation.AdviceName;

import be.ac.ua.ansymo.adbc.annotations.ensures;
import be.ac.ua.ansymo.adbc.annotations.requires;
import be.ac.ua.ansymo.example_bank.Account;
import be.ac.ua.ansymo.example_bank.User;

/**
 * Checks whether users are authorized to access certain methods
 */
public aspect Authorization {
	private HashSet<String> User.rights = new HashSet<String>();

	public boolean User.isAuthorized(String key) {
		return rights.contains(key);
	}

	public static void addRights(User u, String key) {
		u.rights.add(key);
	}

	@requires("$proc")
	@ensures({"from.getOwner().isAuthorized(\"transfer\")?$proc:true"})
	@AdviceName("authorize")
	void around(Account from): call(void Account.transfer(double, Account)) && target(from) {
		if (from.getOwner().isAuthorized("transfer")) {
			System.out.println("Authorize: " + from.getOwner().getName() + " is authorized to access this method");
			proceed(from);
		} else {
			System.err.println(from.getOwner().getName() + " is not authorized to access this method!");
		}
	}
}
