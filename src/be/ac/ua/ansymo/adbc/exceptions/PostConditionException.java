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
 * Thrown if a postcondition is broken
 * @author Tim Molderez
 */
public class PostConditionException extends ContractEnforcementException {

	/**
	 * Constructor
	 * @param postcondition	which postcondition is broken (if a contract consists of multiple parts; only pass the part that has been broken)
	 * @param where			what body does the postcondition belong to?
	 * @param blame			who is to blame for breaking the contract?
	 */
	public PostConditionException(String postcondition, String where, String blame) {
		super("Postcondition broken!", postcondition, where, blame);
	}

}
