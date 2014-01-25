/*******************************************************************************
 * Copyright (c) 2012-2014 Tim Molderez.
 * 
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the 3-Clause BSD License
 * which accompanies this distribution, and is available at
 * http://www.opensource.org/licenses/BSD-3-Clause
 ******************************************************************************/

package be.ac.ua.ansymo.adbc;

/**
 * Adbc configuration - Simply change the fields exposed by this class to alter Adbc's settings at any time
 * @author Tim Molderez
 */
public class AdbcConfig {
	/**
	 * If true, contract enforcement is enabled. (Default value: true)
	 * If false, adbc is disabled.
	 */
	public static boolean enforceContracts = true;
	
	/**
	 * If true, we test whether the substitution principle holds. (Default value: true)
	 * (In case of methods/constructors, we test strong behavioural subtyping rules;
	 * in case of advice, we test the rules of the advice substitution principle.)
	 */
	public static boolean checkSubstitutionPrinciple = true;
	
	/**
	 * If true, both pre- and postconditions are checked. (Default value: true)
	 * If false, only preconditions are checked, but you'll take a smaller performance hit.
	 */
	public static boolean checkPostconditions = true;
	
	/**
	 * This scripting engine is used to execute contracts.
	 * "JavaScript" refers to the default Mozilla Rhino engine that comes with the JRE.
	 * 
	 * If you want to use another engine: It must implement the JSR-223 specification (javax.script) 
	 * and should use the service provider mechanism to be discoverable by name.
	 * Have a look at http://java.net/projects/scripting/sources/svn/show/trunk to find JSR-223 support
	 * for a variety of languages.
	 */
	public static String engine = "JavaScript";
	
	/**
	 * The prefix to be used for the special constructs that can occur in contracts (e.g. $this, $old, $result, ..)
	 * You may want to change the prefix if you're using a scripting engine that does not allow the default $ character in identifiers
	 */
	public static String keywordPrefix = "$";
}
