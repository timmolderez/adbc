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
 * Thrown if the Liskov/advice substitution principle doesn't hold
 * @author Tim Molderez
 */
public class SubstitutionException extends ContractEnforcementException {
	public SubstitutionException(String contract, String blame, String reason) {
		super("\n\tSubstitution principle broken! (" + reason + ")" +
				"\n\tContract:	" + contract +
				"\n\tBlame:		" + blame +
				"\n");
	}
}