/**
 * Copyright (c) 2012 Tim Molderez.
 * 
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the 3-Clause BSD License
 * which accompanies this distribution, and is available at
 * http://www.opensource.org/licenses/BSD-3-Clause
 */

package be.ac.ua.ansymo.adbc;

/**
 * Adbc configuration - Use it to access and change Adbc's settings at any time
 * @author Tim Molderez
 */
public class AdbcConfig {
	/**
	 * If true, contracts enforcing is enabled. (Default value: true)
	 * If false, adbc is disabled.
	 */
	public static boolean enforceContracts = true;
	
	/**
	 * If true, advice and Liskov substitution are checked. (Default value: true)
	 * You may want to set it to false for better performance, or if there are occurences 
	 * where you can't help but to break the substitution principle.
	 */
	public static boolean checkSubstitutionPrinciple = true;
	
	/**
	 * If true, both pre- and postconditions are checked. (Default value: true)
	 * If false, only preconditions are checked, but you'll take less of a performance hit.
	 */
	public static boolean checkPostconditions = true;
}
