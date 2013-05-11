/**
 * Copyright (c) 2012 Tim Molderez.
 * 
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the 3-Clause BSD License
 * which accompanies this distribution, and is available at
 * http://www.opensource.org/licenses/BSD-3-Clause
 */

package be.ac.ua.ansymo.adbc.aspects;

import java.lang.reflect.AccessibleObject;
import java.lang.reflect.Method;
import java.util.Vector;

import javax.script.ScriptException;

import org.aspectj.lang.JoinPoint;
import org.aspectj.lang.reflect.CodeSignature;
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
	 * @param dyn	the this object, used to determine the dynamic type
	 */
	Object around(Object dyn): execution(* *.*(..)) && this(dyn)
	&& excludeContractEnforcers() {
		/* Very sensitive pointcut!! Only use what's excluded by excludeContractEnforcers()
		 * or you'll trigger infinite pointcut matching! */
		
		try {
			/* Retrieve the call join point which corresponds to the execution join point that is thisJoinPoint.
			 * We need this call join point because it knows the static type of the method call; the execution join point only knows the dynamic type.
			 * Note that we can safely pop this entry from CallStack, as no other contract enforcement advice will need it. */
			callJp = CallStack.pop();
			
			preCheck(dyn);
			Object result = proceed(dyn);
			if (AdbcConfig.checkPostconditions) {
				postCheck(dyn, result);
			}
			return result;
		} catch (ScriptException e) {
			System.err.println(e.getMessage());
			throw new RuntimeException("Failed to evaluate contract: " + e.getMessage());
		}
	}
	
	/**
	 * This advice enforces contracts of constructors
	 * If a contract is broken, a ContractEnforcementException is thrown.
	 */
//	Object around(Object dyn): execution(*.new(..)) && excludeContractEnforcers() && this(dyn) {
//		// Skip enforcement if this is the internal constructor of an aspect..
//		if(constructorCheck(thisJoinPoint)) {
//			return proceed(dyn);
//		}
//		
//		// Temporarily disable substitution checking, as it does not apply to constructors..
//		boolean subst = AdbcConfig.checkSubstitutionPrinciple;
//		AdbcConfig.checkSubstitutionPrinciple = false;
//		try {
//			/* In constructors, there's no notion of static and dynamic type,
//			 * so we can just use thisJoinPoint to retrieve the static contracts.. */
//			callJp=thisJoinPoint;
//			
//			preCheck(null);
//			Object result = proceed(dyn);
//			if (AdbcConfig.checkPostconditions) {
//				postCheck(dyn, null);
//			}
//			AdbcConfig.checkSubstitutionPrinciple=subst;
//			return result;
//		} catch (ScriptException e) {
//			AdbcConfig.checkSubstitutionPrinciple=subst;
//			System.err.println(e.getMessage());
//			throw new RuntimeException("Failed to evaluate contract: " + e.getMessage());
//		}
//	}
	
	/*
	 * Check contracts before method execution (preconditions, invariants, substitution principle)
	 * @param dyn	the this object
	 */
	private void preCheck(Object dyn) throws ScriptException {
		// Reset bindings
		ceval = new ContractInterpreter();
		
		// Get the contracts of the method call's static type
		CodeSignature sig = (CodeSignature)(callJp.getSignature());
		
		System.out.println("HEY" + sig + "---" + dyn);

		AccessibleObject body = null;
		if(sig instanceof MethodSignature) {
			body = ((MethodSignature)sig).getMethod();
		} else if (sig instanceof ConstructorSignature) {
			body = ((ConstructorSignature)sig).getConstructor();
		}
		
		pre = new String[]{"true"};
		post = new String[]{"true"};
		inv = new String[]{"true"};
		
		if (body.isAnnotationPresent(requires.class)) {
			pre = body.getAnnotation(requires.class).value();
		}
		if (body.isAnnotationPresent(ensures.class)) {
			post = body.getAnnotation(ensures.class).value();
		}
		if (dyn!= null && dyn.getClass().isAnnotationPresent(invariant.class)) {
			inv = dyn.getClass().getAnnotation(invariant.class).value();
		}
		
		// Reset postconditions
		postContracts = new Vector<String[]>();
		
		// Bind parameter values
		ceval.setParameterBindings(sig.getParameterNames(), callJp.getArgs());
		
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
			throw new PreConditionException(brokenContract, sig.toShortString(), Thread.currentThread().getStackTrace()[6].toString());
		}
		
		// Test invariants
		brokenContract = ceval.evalContract(inv);
		if(brokenContract!=null) {
			throw new InvariantException(brokenContract, Thread.currentThread().getStackTrace()[2].toString(), "precondition");
		}
		
		// Test Liskov substitution
		if (AdbcConfig.checkSubstitutionPrinciple) {
			liskovPreCheck(dyn.getClass(), sig);
		}
	}
	
	/*
	 * Check contracts after method execution (postconditions, invariants, substitution principle)
	 * @param dyn		the this object
	 * @param result	return value of the method call
	 */
	private void postCheck(Object dyn, Object result) throws ScriptException {
		// Bind the return value
		ceval.setReturnValueBinding(result);
		
		// Retrieve the method signature of the join point we matched on
		CodeSignature sig = (CodeSignature)(callJp.getSignature());
		
		System.out.println(sig + "---" + dyn);
		
		// In case of constructors, now fetch the invariants and bind this.. 
		if (sig instanceof ConstructorSignature) {
			if (dyn.getClass().isAnnotationPresent(invariant.class)) {
				inv = dyn.getClass().getAnnotation(invariant.class).value();
			}
			ceval.setThisBinding(dyn);
		}

		// Test postconditions
		System.out.println("fdlfs;" + post[0]);
		String brokenContract = ceval.evalContract(post);
		if(brokenContract!=null) {
			throw new PostConditionException(brokenContract, dyn.toString());
		}
		
		// Test invariants
		brokenContract = ceval.evalContract(inv);
		if(brokenContract!=null) {
			throw new InvariantException(brokenContract, dyn.getClass().toString(), "postcondition");
		}
		
		// Test Liskov substitution
		if (AdbcConfig.checkSubstitutionPrinciple) {
			liskovPostCheck(true, dyn.getClass(), sig, 0);
		}
	}
	
	/*
	 * Checks whether the current join point is the execution of an internal constructor in an aspect
	 * (which cannot have contracts .. plus does not have any corresponding call join point)
	 * @param jp	thisJoinPoint
	 */
	private boolean constructorCheck(JoinPoint jp) {
		return jp.getThis().getClass().isAnnotationPresent(org.aspectj.lang.annotation.Aspect.class);
	}
	
	/*
	 * Check the Liskov substitution principle on preconditions
	 * @param dynType	check whether this type's preconditions respect its parents
	 * @param sig		signature of the method to be checked
	 * @return			true if Liskov substitution is respected in this instance
	 */
	private boolean liskovPreCheck(Class<?> dynType, CodeSignature sig) throws ScriptException {
		try {
			boolean res = true;
			boolean next = true;
			String brokenContract=null;
			
			// Note that getMethod basically does a lookup procedure! (unlike getDeclaredMethod)
			Method mBody = dynType.getMethod(sig.getName(), sig.getParameterTypes());
			
			if (mBody.isAnnotationPresent(requires.class)) {
				brokenContract = ceval.evalContract(mBody.getAnnotation(requires.class).value());
				res = brokenContract==null;
			}
			
			if (mBody.getDeclaringClass().getSuperclass()!=Object.class) {
				next = liskovPreCheck(mBody.getDeclaringClass().getSuperclass(), sig);
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
	 * @param last		result of the caller 
	 * @param dynType	check whether this type's postconditions respect its parents
	 * @param sig		signature of the method to be checked
	 * @param i			index indicating which entry of postContracts to use
	 * @return			true if Liskov substitution is respected in this instance
	 */
	private boolean liskovPostCheck(boolean last, Class<?> dynType, CodeSignature sig, int i) throws ScriptException {
		boolean res = true;
		String brokenContract=null;
		
		try {
			Method mBody = dynType.getMethod(sig.getName(), sig.getParameterTypes());
			
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
				return liskovPostCheck(res, dynType.getSuperclass(), sig,i+1);
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
