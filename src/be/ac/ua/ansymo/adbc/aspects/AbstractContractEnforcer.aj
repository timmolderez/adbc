/**
 * Copyright (c) 2012 Tim Molderez.
 * 
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the 3-Clause BSD License
 * which accompanies this distribution, and is available at
 * http://www.opensource.org/licenses/BSD-3-Clause
 */

package be.ac.ua.ansymo.adbc.aspects;

import be.ac.ua.ansymo.adbc.AdbcConfig;


/**
 * Abstract contract enforcer; contains shared pointcuts
 * @author Tim Molderez
 */
public abstract aspect AbstractContractEnforcer {
	/* This partial pointcut excludes any join point coming from the contract enforcement aspects.
	 * Everything produced in the cflow of proceed calls still is included.	*/
	protected pointcut excludeContractEnforcers(): 
	!cflow(call(* ClassContractEnforcer.*Check(..)))			// Ignore methods in the class contract enforcer
	&& !cflow(call(* AspectContractEnforcer.*Check(..)))		// Ignore methods in the aspect contract enforcer
	&& !cflow(call(* CallStack.p*(..)))
	&& !execution(be.ac.ua.ansymo.adbc.aspects.*.new(..))		// Ignore any internal constructors of our contract enforcement aspects
	&& if(AdbcConfig.enforceContracts);							// No pointcuts will match if contract enforcement is disabled
}
