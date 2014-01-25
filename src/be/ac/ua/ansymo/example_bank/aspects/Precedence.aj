/*******************************************************************************
 * Copyright (c) 2012-2014 Tim Molderez.
 * 
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the 3-Clause BSD License
 * which accompanies this distribution, and is available at
 * http://www.opensource.org/licenses/BSD-3-Clause
 ******************************************************************************/

package be.ac.ua.ansymo.example_bank.aspects;

/**
 * Defines the precedence order of all aspects in the application
 * @author Tim
 */
public aspect Precedence {
	declare precedence: Authentication, Authorization, TransactionLogger;
}
