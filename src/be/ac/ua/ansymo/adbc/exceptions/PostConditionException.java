/**
 * Copyright (c) 2012 Tim Molderez.
 * 
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the 3-Clause BSD License
 * which accompanies this distribution, and is available at
 * http://www.opensource.org/licenses/BSD-3-Clause
 */

package be.ac.ua.ansymo.adbc.exceptions;

/**
 * Thrown if a postcondition is broken
 * @author Tim Molderez
 */
public class PostConditionException extends ContractEnforcementException {

	/**
	 * Constructor
	 * @param postcondition	which postcondition is broken (if a contract consists of multiple parts; only pass the part that has been broken)
	 * @param where			which body does the contract belong to?
	 * @param blame			who is to blame for breaking the contract?
	 */
	public PostConditionException(String postcondition, String blame) {
		super("\n\tPostcondition broken!" +
				"\n\tContract:	" + postcondition +
				"\n\tWhere:		" + blame +
				"\n\tBlame:		" + blame +
				"\n");
	}

}
