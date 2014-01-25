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
 * Thrown if a precondition is broken
 * @author Tim Molderez
 */
public class PreConditionException extends ContractEnforcementException {

	/**
	 * Constructor
	 * @param precondition	which precondition is broken (if a contract consists of multiple parts; only pass the part that has been broken)
	 * @param where			which body does the contract belong to?
	 * @param blame			who is to blame for breaking the contract?
	 */
	public PreConditionException(String precondition, String where, String blame) {
		super("Precondition broken!", precondition, where, blame);
	}
}
