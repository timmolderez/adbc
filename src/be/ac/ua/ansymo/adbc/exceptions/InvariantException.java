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
 * Thrown if an invariant is broken
 * @author Tim Molderez
 */
public class InvariantException extends ContractEnforcementException {

	public InvariantException(String invariant, String blame, String preOrPost) {
		super("\n\tInvariant broken! (at " + preOrPost + ")"+
				"\n\tContract:	" + invariant +
				"\n\tBlame:		" + blame +
				"\n");
	}
}
