/*******************************************************************************
 * Copyright (c) 2012-2014 Tim Molderez.
 * 
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the 3-Clause BSD License
 * which accompanies this distribution, and is available at
 * http://www.opensource.org/licenses/BSD-3-Clause
 ******************************************************************************/

package be.ac.ua.ansymo.adbc.aspects;

import java.util.Stack;

import org.aspectj.lang.JoinPoint;


public aspect CallStack extends AbstractContractEnforcer {
	private static Stack<JoinPoint> stack = new Stack<JoinPoint>();
	
	/**
	 * Capture any method call join point and store it on a stack.
	 * 
	 * We're doing this because contract enforcement needs to happen at the very last moment.
	 * That is, contract enforcement has to be the last advice at the execution join point.
	 * We want to check the contracts of the original piece of code only, nothing more.
	 * 
	 * Problem with that is, an execution join point doesn't have access to the static type of the corresponding 
	 * call join point. This is why we need this CallStack aspect. It captures the call join point, and makes it available 
	 * for contract enforcement advice at the execution join point. 
	 */
	before(): call(* *.*(..)) 
	&& !call(* java.*.*.*(..)) // Exclude JRE libs; these don't generate corresponding execution join points..
	&& excludeContractEnforcers() {
		push(thisJoinPoint);
	}
	
	static public void push(JoinPoint jp) {
		jp.getTarget(); // The thisjoinpoint object is created lazily; this (seemingly useless) statement forces it to be created..
		stack.push(jp);
	}
	
	static public JoinPoint pop() {
		return stack.pop();
	}
	
	static public JoinPoint peek() {
		return stack.peek();
	}
}
