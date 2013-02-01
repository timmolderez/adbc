/**
 * Copyright (c) 2012 Tim Molderez.
 * 
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the 3-Clause BSD License
 * which accompanies this distribution, and is available at
 * http://www.opensource.org/licenses/BSD-3-Clause
 */

package be.ac.ua.ansymo.adbc.aspects;

import java.lang.reflect.Constructor;
import java.lang.reflect.Method;
import java.util.Vector;

import javax.script.ScriptException;

import org.aspectj.lang.JoinPoint;
import org.aspectj.lang.reflect.ConstructorSignature;
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
 * This aspects enforces the contracts of all your classes.
 * If a contract is broken, a ContractEnforcementException is thrown.
 * @author Tim Molderez
 */
public aspect ClassContractEnforcer extends AbstractContractEnforcer {
	private JoinPoint callJp;				// The call join point corresponding to the execution join point captured by the contract enforcement advice
	private Vector<String[]> postContracts;	// Postconditions of ancestors, with their $old() calls processed
	
	/**
	 * This advice enforces contracts of regular method calls
	 * If a contract is broken, a ContractEnforcementException is thrown.
	 */
	Object around(Object dyn): execution(* *.*(..)) && this(dyn)
	&& excludeContractEnforcers() {
		/* Very sensitive pointcut!! Do not perform any method calls here besides preCheck() and postCheck() 
		 * or you'll trigger infinite pointcut matching! */
		try {
			preCheck(thisJoinPoint, dyn);
			Object result = proceed(dyn);
			if (AdbcConfig.checkPostconditions) {
				postCheck(thisJoinPoint, dyn, result);
			}
			return result;
		} catch (ScriptException e) {
			System.err.println(e.getMessage());
			throw new RuntimeException("Failed to evaluate contract: " + e.getMessage());
		}
	}
	
	/**
	 * Enforces the contracts of constructor calls, i.e. its postconditions and invariants
	 * should hold after the constructor finishes.
	 */
	after() returning (Object o) : call(*.new(..)) && excludeContractEnforcers() {
		if (AdbcConfig.checkPostconditions) {
			try {
				constructorCheck(thisJoinPoint, o);
			} catch (ScriptException e) {
				System.err.println(e.getMessage());
				throw new RuntimeException("Failed to evaluate contract: " + e.getMessage());
			}
		}
	}
	
	/*
	 * Check contracts before method execution (preconditions, invariants, substitution principle)
	 */
	private void preCheck(JoinPoint jp, Object dyn) throws ScriptException {
		// Reset bindings
		ceval = new ContractInterpreter();
		
		/* Retrieve the call join point which corresponds to the execution join point that is thisJoinPoint.
		 * We need this call join point because it knows the static type of the method call; the execution join point
		 * only knows the dynamic type.
		 * Note that we can safely pop this entry from CallStack, as no other contract enforcement advice will need it. */
		callJp = CallStack.pop();
		
		// Get the contracts of the static type of the method call
		MethodSignature mSig = (MethodSignature)(callJp.getSignature());
		Method mBody = mSig.getMethod();
		
		pre = new String[]{"true"};
		post = new String[]{"true"};
		inv = new String[]{"true"};
		
		if (mBody.isAnnotationPresent(requires.class)) {
			pre = mBody.getAnnotation(requires.class).value();
		}
		if (mBody.isAnnotationPresent(ensures.class)) {
			post = mBody.getAnnotation(ensures.class).value();
		}
		if (dyn.getClass().isAnnotationPresent(invariant.class)) {
			inv = dyn.getClass().getAnnotation(invariant.class).value();
		}
		
		// Reset postconditions
		postContracts = new Vector<String[]>();
		
		// Bind parameter values
		ceval.setParameterBindings(mSig.getParameterNames(), callJp.getArgs());
		
		// Bind the this object
		ceval.setThisBinding(dyn);
		
		// Evaluate calls to the $old() function in the postcondition 
		try {
			if (AdbcConfig.checkPostconditions) {
				post = ceval.evalOldFunction(post);
			}
		} catch (ScriptException e) {
			throw new RuntimeException("Failed to evaluate old() call: " + e.getMessage());
		}
		
		// Test preconditions
		String brokenContract = ceval.evalContract(pre);
		if(brokenContract!=null) {
			throw new PreConditionException(brokenContract, Thread.currentThread().getStackTrace()[2].toString());
		}
		
		// Test invariants
		brokenContract = ceval.evalContract(inv);
		if(brokenContract!=null) {
			throw new InvariantException(brokenContract, Thread.currentThread().getStackTrace()[2].toString(), "precondition");
		}
		
		// Test Liskov substitution
		if (AdbcConfig.checkSubstitutionPrinciple) {
			liskovPreCheck(dyn.getClass(), mSig);
		}
	}
	
	/*
	 * Check contracts after method execution (postconditions, invariants, substitution principle)
	 */
	private void postCheck(JoinPoint jp, Object dyn, Object result) throws ScriptException {
		// Bind the return value
		ceval.setReturnValueBinding(result);
		
		// Retrieve the method signature of the join point we matched on
		MethodSignature mSig = (MethodSignature)(callJp.getSignature());

		// Test postconditions
		String brokenContract = ceval.evalContract(post);
		if(brokenContract!=null) {
			throw new PostConditionException(brokenContract, dyn.getClass().toString());
		}
		
		// Test invariants
		brokenContract = ceval.evalContract(inv);
		if(brokenContract!=null) {
			throw new InvariantException(brokenContract, dyn.getClass().toString(), "postcondition");
		}
		
		// Test Liskov substitution
		if (AdbcConfig.checkSubstitutionPrinciple) {
			liskovPostCheck(true, dyn.getClass(), mSig, 0);
		}
	}
	
	/*
	 * Checks the postconditions and invariants after a constructor call
	 */
	private void constructorCheck(JoinPoint jp, Object dyn) throws ScriptException {
		// Reset bindings
		ceval = new ContractInterpreter();
		
		// Get the contracts 
		ConstructorSignature cSig = (ConstructorSignature)(jp.getSignature());
		Constructor<?> cBody = cSig.getConstructor();
		
		post = new String[]{"true"};
		inv = new String[]{"true"};
		
		if (cBody.isAnnotationPresent(ensures.class)) {
			post = cBody.getAnnotation(ensures.class).value();
		}
		if (dyn.getClass().isAnnotationPresent(invariant.class)) {
			inv = dyn.getClass().getAnnotation(invariant.class).value();
		}
		
		// Bind parameter values
		ceval.setParameterBindings(cSig.getParameterNames(), jp.getArgs());
		
		// Bind the this object
		ceval.setThisBinding(dyn);

		// Test postconditions
		String brokenContract;
		brokenContract = ceval.evalContract(post);
		if(brokenContract!=null) {
			throw new PostConditionException(brokenContract, dyn.getClass().toString());
		}
		
		// Test invariants
		brokenContract = ceval.evalContract(inv);
		if(brokenContract!=null) {
			throw new InvariantException(brokenContract, dyn.getClass().toString(), "postcondition");
		}
	}
	
	/*
	 * Check the Liskov substitution principle on preconditions
	 */
	private boolean liskovPreCheck(Class<?> dynType, MethodSignature m) throws ScriptException {
		try {
			boolean res = true;
			boolean next = true;
			String brokenContract=null;
			
			// Note that getMethod basically does a lookup procedure! (unlike getDeclaredMethod)
			Method mBody = dynType.getMethod(m.getName(), m.getParameterTypes());
			
			if (mBody.isAnnotationPresent(requires.class)) {
				brokenContract = ceval.evalContract(mBody.getAnnotation(requires.class).value());
				res = brokenContract==null;
			}
			
			if (mBody.getDeclaringClass().getSuperclass()!=Object.class) {
				next = liskovPreCheck(mBody.getDeclaringClass().getSuperclass(), m);
			}
			
			if (dynType.isAnnotationPresent(invariant.class)) {
				String brokenInv = ceval.evalContract(dynType.getAnnotation(invariant.class).value());
				if (brokenInv != null) {
					throw new SubstitutionException(brokenInv,dynType.toString(), "invariant not preserved");
				}
			}
			
			if (mBody.isAnnotationPresent(ensures.class)) {
				postContracts.add(ceval.evalOldFunction(mBody.getAnnotation(ensures.class).value()));
			}
			
			if (!next || res) {
				return res;
			} else {
				throw new SubstitutionException(brokenContract,dynType.toString(), "precondition too strong");
			}
		} catch (SecurityException e) {
			e.printStackTrace();
			return false;
		} catch (NoSuchMethodException e) {
			return true;
		}
		
	}
	
	/*
	 * Check the Liskov substitution principle on postconditions
	 */
	private boolean liskovPostCheck(boolean last, Class<?> dynType, MethodSignature m, int i) throws ScriptException {
		boolean res = true;
		String brokenContract=null;
		
		try {
			Method mBody = dynType.getMethod(m.getName(), m.getParameterTypes());
			
			if (mBody.isAnnotationPresent(ensures.class) && i<postContracts.size()) {
				brokenContract = ceval.evalContract(postContracts.get(i));
				res = brokenContract==null;
			}
			
			if (dynType.isAnnotationPresent(invariant.class)) {
				String brokenInv = ceval.evalContract(dynType.getAnnotation(invariant.class).value());
				if (brokenInv != null) {
					throw new SubstitutionException(brokenInv,dynType.toString(), "invariant not preserved");
				}
			}
			
			if (!last || res) {
				return liskovPostCheck(res, dynType.getSuperclass(), m,i+1);
			} else {
				throw new SubstitutionException(brokenContract, dynType.toString(), "postcondition too weak");
			}
		} catch (SecurityException e) {
			e.printStackTrace();
			return false;
		} catch (NoSuchMethodException e) {
			return true;
		}
		
	}

}
