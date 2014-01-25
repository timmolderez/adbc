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
 * Thrown whenever a contract is broken
 * @author Tim Molderez
 */
public class ContractEnforcementException extends RuntimeException {

	/**
	 * Constructor
	 * @param description	short description of the type of contract violation
	 * @param contract		which contract is broken
	 * @param where			to which body does this contract belong
	 * @param blame			which body is to blame
	 */
	public ContractEnforcementException(String description, String contract, String where, String blame) {
		super("\n\t" + description +
				"\n\tContract:	" + contract +
				"\n\tWhere:		" + where +
				"\n\tBlame:		" + blame +
				"\n");
	}

}
