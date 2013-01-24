/**
 * Copyright (c) 2012 Tim Molderez.
 * 
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the 3-Clause BSD License
 * which accompanies this distribution, and is available at
 * http://www.opensource.org/licenses/BSD-3-Clause
 */

package be.ac.ua.ansymo.adbc.aspects;

/**
 * Defines the precedence of all adbc aspects
 * @author Tim Molderez
 */
public aspect AspectPrecedence {
	/* Contract enforcement aspects must be the very last execution advice at shared join points!
	 * Do contract enforcement any earlier, and other aspects may intervene and alter
	 * some values that influence the evaluation of a contract, which is of course undesired. 
	 *  
	 * (The order of Aspect/ClassContractEnforcer doesn't matter; their join points are mutually exclusive.)*/
	declare precedence: *, AspectContractEnforcer, ClassContractEnforcer;
}
