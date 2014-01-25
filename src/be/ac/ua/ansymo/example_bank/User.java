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
import be.ac.ua.ansymo.adbc.annotations.invariant;
import be.ac.ua.ansymo.adbc.annotations.requires;

/**
 * A user of the bank
 * @author Tim Molderez
 */
@invariant("$this.name!=null")
public class User {
	private String name;
	
	@requires("name!=null")
	@ensures("$this.name.equals(name)")
	public User(String name) {
		this.name = name;
	}
	
	@ensures("$result!=null")
	public String getName() {
		return name;
	}
}
