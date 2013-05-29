/*******************************************************************************
 * Copyright (c) 2012-2013 Tim Molderez.
 * 
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the 3-Clause BSD License
 * which accompanies this distribution, and is available at
 * http://www.opensource.org/licenses/BSD-3-Clause
 ******************************************************************************/

package be.ac.ua.ansymo.adbc.utilities;

/**
 * Debugging helper methods..
 * @author Tim Molderez
 */
public class Debug {
	static public void print(Object[] arr) {
		for (Object obj : arr) {
			System.out.println(obj.toString());
		}
	}
}
