/*******************************************************************************
 * Copyright (c) 2012-2013 Tim Molderez.
 * 
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the 3-Clause BSD License
 * which accompanies this distribution, and is available at
 * http://www.opensource.org/licenses/BSD-3-Clause
 ******************************************************************************/

package be.ac.ua.ansymo.adbc.exceptions;

/**
 * Thrown if the Liskov/advice substitution principle doesn't hold
 * @author Tim Molderez
 */
public class SubstitutionException extends ContractEnforcementException {
	
	/**
	 * Constructor
	 * @param postcondition	which postcondition is broken (if a contract consists of multiple parts; only pass the part that has been broken)
	 * @param blame			who is to blame for breaking the contract?
	 */
	public SubstitutionException(String contract, String where, String blame, String reason) {
		super("Substitution principle broken! (" + reason + ")", contract, where, blame);
	}
}
