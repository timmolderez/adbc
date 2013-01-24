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
 * Thrown whenever a contract is broken
 * @author Tim Molderez
 */
public class ContractEnforcementException extends RuntimeException {

	public ContractEnforcementException(String blame) {
		super(blame);
	}

}
