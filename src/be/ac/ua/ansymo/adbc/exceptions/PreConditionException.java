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
 * Thrown if a precondition is broken
 * @author Tim Molderez
 */
public class PreConditionException extends ContractEnforcementException {

	public PreConditionException(String precondition, String blame) {
		super("\n\tPrecondition broken!" +
				"\n\tContract:	" + precondition +
				"\n\tBlame:		" + blame +
				"\n");
	}
}
