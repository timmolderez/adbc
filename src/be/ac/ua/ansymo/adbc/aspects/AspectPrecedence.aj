/*******************************************************************************
 * Copyright (c) 2012-2014 Tim Molderez.
 * 
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the 3-Clause BSD License
 * which accompanies this distribution, and is available at
 * http://www.opensource.org/licenses/BSD-3-Clause
 ******************************************************************************/

package be.ac.ua.ansymo.adbc.aspects;

/**
 * Defines the precedence of all adbc aspects
 * @author Tim Molderez
 */
public aspect AspectPrecedence {
	/* Contract enforcement aspects must be the very last execution advice at shared join points!
	 * Do contract enforcement any earlier, and other aspects may intervene. 
	 * 
	 * On the other hand, the CallStack helper advice, which stores all call join points in a stack, 
	 * must be the very first advice to run! Otherwise a user-advice and its contract-advice could
	 * run before we stored the call join point, and the contract-advice would use incorrect information.
	 *  
	 * (The order of Aspect/ClassContractEnforcer doesn't matter; their join points are mutually exclusive.)*/
	declare precedence: CallStack, *, AspectContractEnforcer, ClassContractEnforcer;
}
