/*******************************************************************************
 * Copyright (c) 2012-2014 Tim Molderez.
 * 
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the 3-Clause BSD License
 * which accompanies this distribution, and is available at
 * http://www.opensource.org/licenses/BSD-3-Clause
 ******************************************************************************/

package be.ac.ua.ansymo.adbc.annotations;

import java.lang.annotation.ElementType;
import java.lang.annotation.Retention;
import java.lang.annotation.RetentionPolicy;
import java.lang.annotation.Target;

/**
 * Annotation indicating that this method/constructor expects to be advised 
 * by the listed advice, in the specified precedence order.
 * For example: @advisedBy("com.myapp.Security.authentication, com.myapp.Persistence.store")
 * 
 * Note that an advice must have a name if you want to mention it in an @advisedBy clause.
 * In other words, the listed advice should have an @AdviceName annotation.
 * @author Tim Molderez
 */
@Retention(RetentionPolicy.RUNTIME)
@Target(value={ElementType.METHOD,ElementType.CONSTRUCTOR})
public @interface advisedBy {
	String[] value();
}
