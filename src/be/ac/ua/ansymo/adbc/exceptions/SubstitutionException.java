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
 * Thrown if a substitution error occurs 
 * (either the precondition is too strong, the postcondition too weak, or invariants not preserved)
 * @author Tim Molderez
 */
public class SubstitutionException extends ContractEnforcementException {
	
	/**
	 * Constructor
	 * @param contract		which contract is broken (if a contract consists of multiple parts; only pass the part that has been broken)
	 * @param blame			who is to blame for breaking the contract?
	 */
	public SubstitutionException(String contract, String where, String blame, String reason) {
		super("Substitution principle broken! (" + reason + ")", contract, where, blame);
	}
}
