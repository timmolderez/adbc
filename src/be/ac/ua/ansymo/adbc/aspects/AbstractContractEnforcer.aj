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
import be.ac.ua.ansymo.adbc.utilities.ContractInterpreter;


/**
 * Abstract contract enforcer; contains all stuff shared between Class -and AspectContractEnforcer
 * @author Tim Molderez
 */
public abstract aspect AbstractContractEnforcer {
	// Interpreter engine evaluating all contracts
	protected ContractInterpreter ceval;
	
	// Contracts of the static type of a join point
	protected String[] pre;
	protected String[] post;
	protected String[] inv;
	
	/* This partial pointcut excludes any join point coming from the contract enforcement aspects.
	 * Everything produced in the cflow of proceed calls still is included.	*/
	protected pointcut excludeContractEnforcers(): 
	!cflow(call(void ClassContractEnforcer.*Check(..)))
	&& !cflow(call(void AspectContractEnforcer.*Check(..)))
	&& !within(be.ac.ua.ansymo.adbc.aspects.CallStack)
	&& if(AdbcConfig.enforceContracts);
}
