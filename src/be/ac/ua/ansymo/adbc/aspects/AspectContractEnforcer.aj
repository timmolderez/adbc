/**
 * Copyright (c) 2012 Tim Molderez.
 * 
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the 3-Clause BSD License
 * which accompanies this distribution, and is available at
 * http://www.opensource.org/licenses/BSD-3-Clause
 */

package be.ac.ua.ansymo.adbc.aspects;

import java.lang.reflect.Method;

import javax.script.ScriptException;

import org.aspectj.lang.JoinPoint;
import org.aspectj.lang.reflect.AdviceSignature;
import org.aspectj.lang.reflect.MethodSignature;

import be.ac.ua.ansymo.adbc.AdbcConfig;
import be.ac.ua.ansymo.adbc.annotations.ensures;
import be.ac.ua.ansymo.adbc.annotations.invariant;
import be.ac.ua.ansymo.adbc.annotations.requires;
import be.ac.ua.ansymo.adbc.exceptions.InvariantException;
import be.ac.ua.ansymo.adbc.exceptions.PostConditionException;
import be.ac.ua.ansymo.adbc.exceptions.PreConditionException;
import be.ac.ua.ansymo.adbc.exceptions.SubstitutionException;
import be.ac.ua.ansymo.adbc.utilities.ContractInterpreter;

/**
 * This aspects enforces the contracts of all aspects. 
 * If a contract is broken, a ContractEnforcementException is thrown.
 * 
 * @author Tim Molderez
 */
public aspect AspectContractEnforcer extends AbstractContractEnforcer {
	private JoinPoint tjp = null;	// The thisjoinpoint object of the user-advice
	private String advKind;			// User-advice kind (before, after around)
	
	// Contracts of the user-advice
	protected String[] advPre;
	protected String[] advPost;
	protected String[] advInv;

	/**
	 * Contract enforcer for advice
	 */
	Object around(Object dyn): adviceexecution() && this(dyn) 
	&& !within(be.ac.ua.ansymo.adbc.aspects.*) && excludeContractEnforcers() {
		/* Very sensitive pointcut! Do not perform any method calls here besides preCheck() and postCheck() 
		 * or you'll trigger infinite pointcut matching! */
		
		try {
			preCheck(thisJoinPoint, dyn);
			Object result = proceed(dyn);
			if (AdbcConfig.checkPostconditions) {
				postCheck(thisJoinPoint,dyn, result);
			}
			return result;
		} catch (ScriptException e) {
			throw new RuntimeException("Failed to evaluate contract: " + e.getMessage());
		}
	}

	/*
	 * Do the necessary preparation and
	 * check all contracts before advice execution (preconditions, invariants, substitution principle)
	 */
	private void preCheck(JoinPoint jp, Object dyn) throws ScriptException {
		// Reset bindings
		ceval = new ContractInterpreter();
		
		// Retrieve the thisJoinPoint object of the user-advice 
		/* Note that we're peeking into CallStack, not popping! Other contract enforcement
		 * still need this top entry! */
		tjp = CallStack.peek();
		
		
		// Get the contracts of the user advice's advised joinpoint
		// TODO: This currently does not work yet for  higher-order advice!
		pre = new String[]{"true"};
		post = new String[]{"true"};
		inv = new String[]{"true"};
		
		String m = tjp.getSignature().toString();
		int lastdot = m.lastIndexOf('.');
		m = m.substring(lastdot + 1, m.length());
		Method mBody = ((MethodSignature) tjp.getSignature()).getMethod();
		if (mBody.isAnnotationPresent(requires.class)) {
			pre = mBody.getAnnotation(requires.class).value();
		}
		if (mBody.isAnnotationPresent(ensures.class)) {
			post = mBody.getAnnotation(ensures.class).value();
		}
		if (tjp.getTarget().getClass().isAnnotationPresent(invariant.class)) {
			inv = tjp.getTarget().getClass().getAnnotation(invariant.class).value();
		}
		
		// Get the contracts of the user-advice itself
		AdviceSignature aSig = (AdviceSignature) (jp.getSignature());
		Method aBody = aSig.getAdvice();
		
		advPre = new String[]{"true"};
		advPost = new String[]{"true"};
		advInv = new String[]{"true"};
		
		if (AdbcConfig.checkSubstitutionPrinciple) {
			if (aBody.isAnnotationPresent(requires.class)) {
				advPre = aBody.getAnnotation(requires.class).value();
			}
			if (aBody.isAnnotationPresent(ensures.class)) {
				advPost = aBody.getAnnotation(ensures.class).value();
			}
			if (dyn.getClass().isAnnotationPresent(invariant.class)) {
				advInv = dyn.getClass().getAnnotation(invariant.class).value();
			}
		}
		
		// Determine user-advice kind (relying on its internal method name)
		advKind = "around";
		if (aSig.getName().contains("$before$")) {
			advKind = "before";
		} else if (aSig.getName().contains("$after$")) {
			advKind = "after";
		}
		
		// Bind parameter values of advised join point
		MethodSignature mSig = (MethodSignature) (tjp.getSignature());
		ceval.setParameterBindings(mSig.getParameterNames(),tjp.getArgs());
		
		// Bind the "this" object
		ceval.setThisBinding(tjp.getTarget());
		
		// Evaluate calls to the $old() function in postconditions
		try {
			if (AdbcConfig.checkPostconditions) {
				post = ceval.evalOldFunction(post);
				
				ceval.setThisBinding(jp.getThis());
				ceval.setParameterBindings(aSig.getParameterNames(),jp.getArgs());
				advPost = ceval.evalOldFunction(advPost);
			}
		} catch (ScriptException e) {
			System.out.println(e.getMessage());
			throw new RuntimeException("Failed to evaluate old() call: " + e.getMessage());
		}
		
		// Test preconditions
		if (!advKind.equals("after")) {
			String stPreFailed = ceval.evalContract(pre);
			if (stPreFailed != null) {
				throw new PreConditionException(stPreFailed, getCaller());
			}
		}
		
		// Test invariants
		String invFailed = ceval.evalContract(inv);
		if (invFailed != null) {
			throw new InvariantException(invFailed, getCaller(), "precondition");
		}

		// Test advice substitution
		if (AdbcConfig.checkSubstitutionPrinciple) {
			ceval.setThisBinding(jp.getThis());
			ceval.setParameterBindings(aSig.getParameterNames(),jp.getArgs());
			
			String jpPreFailed = ceval.evalContract(advPre);
			if (jpPreFailed != null) {
				throw new SubstitutionException(jpPreFailed, jp.getSignature().toString(), "precondition too strong");
			}

			invFailed = ceval.evalContract(advInv);
			if (invFailed != null) {
				throw new InvariantException(invFailed, tjp.getTarget()
						.toString(), "invariant not preserved");
			}
		}
	}

	/*
	 * Check contracts after advice execution (postconditions, invariants, substitution principle)
	 */
	private void postCheck(JoinPoint jp, Object dyn, Object result) throws ScriptException {
		// Bind the return value
		ceval.setReturnValueBinding(result);
		
		// Bind the this object of the advised join point
		ceval.setThisBinding(tjp.getTarget());
		
		// Test postconditions
		if (!advKind.equals("before")) {
			String stPostFailed = ceval.evalContract(post);
			if (stPostFailed != null) {
				throw new PostConditionException(stPostFailed, dyn.getClass()
						.toString());
			}
		}
		
		// Test invariants
		String invFailed = ceval.evalContract(inv);
		if (invFailed != null) {
			throw new InvariantException(invFailed, dyn.getClass().toString(), "postcondition");
		}

		// Test advice substitution
		if (AdbcConfig.checkSubstitutionPrinciple) {
			ceval.setThisBinding(jp.getThis());
			
			String jpPostFailed = ceval.evalContract(advPost);
			if (jpPostFailed != null) {
				throw new SubstitutionException(jpPostFailed, jp.getSignature()
						.toString(), "postcondition too weak");
			}

			invFailed = ceval.evalContract(advInv);
			if (invFailed != null) {
				throw new InvariantException(invFailed, tjp.getTarget().toString(), "invariant not preserved");
			}
		}
	}

	/*
	 * Retrieve the caller of the user-advice
	 */
	private String getCaller() {
		/* Runtime stack at this point:
		 * 0: getStackTrace()
		 * 1: getCaller()
		 * 2: preCheck()
		 * 3: preCheck()
		 * 4: around (contract enforcer)
		 * 5: user-advice
		 * 6: tjp
		 * 7: caller <== This is what we're interested in..	*/
		StackTraceElement elem = Thread.currentThread().getStackTrace()[7];
		return elem.toString();
	}
}
