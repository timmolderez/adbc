/*******************************************************************************
 * Copyright (c) 2012-2014 Tim Molderez.
 * 
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the 3-Clause BSD License
 * which accompanies this distribution, and is available at
 * http://www.opensource.org/licenses/BSD-3-Clause
 ******************************************************************************/

package be.ac.ua.ansymo.adbc.exceptions;

/**
 * Thrown if an invariant is broken
 * @author Tim Molderez
 */
public class InvariantException extends ContractEnforcementException {

	/**
	 * Constructor
	 * @param invariant		which postcondition is broken (if a contract consists of multiple parts; only pass the part that has been broken)
	 * @param blame			who is to blame for breaking the contract?
	 */
	public InvariantException(String invariant, String where, String blame, String message) {
		super("Invariant broken! (" + message + ")", invariant, where, blame);
	}
}
