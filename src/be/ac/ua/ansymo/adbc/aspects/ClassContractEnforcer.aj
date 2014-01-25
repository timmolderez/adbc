/*******************************************************************************
 * Copyright (c) 2012-2014 Tim Molderez.
 * 
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the 3-Clause BSD License
 * which accompanies this distribution, and is available at
 * http://www.opensource.org/licenses/BSD-3-Clause
 ******************************************************************************/

package be.ac.ua.ansymo.adbc.aspects;

import java.lang.reflect.AccessibleObject;
import java.lang.reflect.Method;
import java.util.EmptyStackException;
import java.util.Vector;

import javax.script.ScriptException;

import org.aspectj.lang.JoinPoint;
import org.aspectj.lang.reflect.CodeSignature;
import org.aspectj.lang.reflect.ConstructorSignature;
import org.aspectj.lang.reflect.MethodSignature;

import be.ac.ua.ansymo.adbc.AdbcConfig;
import be.ac.ua.ansymo.adbc.exceptions.InvariantException;
import be.ac.ua.ansymo.adbc.exceptions.PostConditionException;
import be.ac.ua.ansymo.adbc.exceptions.PreConditionException;
import be.ac.ua.ansymo.adbc.exceptions.SubstitutionException;
import be.ac.ua.ansymo.adbc.utilities.ContractInterpreter;
import be.ac.ua.ansymo.adbc.utilities.ContractStore;

/**
 * This aspect enforces the contracts of all application classes.
 * If a contract is broken, a ContractEnforcementException is thrown.
 * @author Tim Molderez
 */
public aspect ClassContractEnforcer extends AbstractContractEnforcer {
	
	/**
	 * This advice enforces contracts of regular method calls
	 * If a contract is broken, a ContractEnforcementException is thrown.
	 * @param dyn	the this object, used to determine the dynamic type
	 */
	Object around(Object dyn): execution(* *.*(..)) && this(dyn)
	&& excludeContractEnforcers() {
		/* Very sensitive pointcut!! Only use what's excluded by excludeContractEnforcers()
		 * or you'll trigger an infinite recursion! */
		
		try {
			PostData pD = preCheck(thisJoinPoint, dyn);
			Object result = proceed(dyn);
			if (AdbcConfig.checkPostconditions) {
				postCheck(pD, thisJoinPoint, dyn, result);
			}
			return result;
		} catch (ScriptException e) {
			throw new RuntimeException("Failed to evaluate contract: " + e.getMessage());
		}
	}
	
	/**
	 * This advice enforces contracts of constructors
	 * If a contract is broken, a ContractEnforcementException is thrown.
	 * @param dyn	the this object, used to determine the dynamic type
	 */
	Object around(Object dyn): execution(*.new(..)) && excludeContractEnforcers() && this(dyn) {
		// Skip enforcement if this is the internal constructor of an aspect..
		if(aspectConstructorCheck(thisJoinPoint)) {
			return proceed(dyn);
		}
		
		try {
			PostData pD = preCheck(thisJoinPoint, null);
			Object result = proceed(dyn);
			if (AdbcConfig.checkPostconditions) {
				postCheck(pD, thisJoinPoint, dyn, null);
			}
			return result;
		} catch (ScriptException e) {
			throw new RuntimeException("Failed to evaluate contract (in constructor): " + e.getMessage());
		}
	}
	
	/*
	 * Check contracts before method execution (preconditions, invariants, substitution principle)
	 * @param jp	thisJoinPoint
	 * @param dyn	the this object
	 * @return data to be passed on to postCheck()
	 */
	private PostData preCheck(JoinPoint jp, Object dyn) throws ScriptException {
		/* ****************************************************************
		 * Fetching the necessary info...
		 **************************************************************** */
		
		// Retrieve the join point of the method call we're contract-enforcing
		JoinPoint callJp = null;
		try {
			callJp = CallStack.pop();
		} catch (EmptyStackException e) {
			callJp = jp; // You might end up here in case of constructors..
		}
		
		// Reset bindings
		ContractInterpreter ceval = new ContractInterpreter();
		
		// Get the contracts of the method call's static type
		CodeSignature sig = (CodeSignature)(callJp.getSignature());
		AccessibleObject body = null;
		if(sig instanceof MethodSignature) {
			body = ((MethodSignature)sig).getMethod();
		} else if (sig instanceof ConstructorSignature) {
			body = ((ConstructorSignature)sig).getConstructor();
		}
		
		ContractStore store = ContractStore.getInstance();
		String[] pre = store.getPre(body);
		String[] post = store.getPost(body);
		String[] inv = dyn==null?new String[]{"true"}:store.getInvariant(callJp.getSignature().getDeclaringType());
		// Reset postconditions (used in substitution checking)
		Vector<String[]> postContracts = new Vector<String[]>();
		
		/* ****************************************************************
		 * Binding contract variables
		 **************************************************************** */
		
		// Bind parameter values
		ceval.setParameterBindings(sig.getParameterNames(), callJp.getArgs());
		
		// Bind the this object
		ceval.setThisBinding(dyn);
		
		/* ****************************************************************
		 * Actual contract enforcement
		 **************************************************************** */
		
		// Test preconditions
		String brokenContract = ceval.evalContract(pre);
		if(brokenContract!=null) {
			throw new PreConditionException(brokenContract, getStaticSignature(callJp), getCallerSignature());
		}

		// Test invariants
		brokenContract = ceval.evalContract(inv);
		if(brokenContract!=null) {
			throw new InvariantException(brokenContract, callJp.getSignature().getDeclaringTypeName(), getCallerSignature(), "precondition");
		}
		
		// Test precondition substitution rule (does not apply to constructors..)
		if (dyn!=null && AdbcConfig.checkSubstitutionPrinciple) {
			subPreCheck(ceval, dyn.getClass(), null, sig, postContracts);
		}
		
		// Evaluate calls to the $old() function in the postcondition
		// (This should be done last; it should be safe for the developer to assume that the preconditions passed when using the $old() function.)
		try {
			if (AdbcConfig.checkPostconditions) {
				post = ceval.evalOldFunction(post);
			}
		} catch (ScriptException e) {
			throw new RuntimeException("Failed to evaluate old() call: " + e.getMessage());
		}
		
		return new PostData(ceval, post, inv, callJp, postContracts);
	}
	
	/*
	 * Check contracts after method execution (postconditions, invariants, substitution principle)
	 * @param pD		container object with various information produced during the preCheck
	 * @param jp		thisJoinPoint
	 * @param dyn		the this object
	 * @param result	return value of the method call
	 */
	private void postCheck(PostData pD, JoinPoint jp, Object dyn, Object result) throws ScriptException {
		// Get information from the PostData containeer
		ContractInterpreter ceval = pD.ceval;
		JoinPoint callJp = pD.callJp;
		String[] inv = pD.inv;
		String[] post = pD.post;
		Vector<String[]> postContracts = pD.postContracts;
		
		// Bind the return value
		ceval.setReturnValueBinding(result);
		
		// Retrieve the method signature of the join point we matched on
		CodeSignature sig = (CodeSignature)(callJp.getSignature());
		boolean isConstructor = sig instanceof ConstructorSignature;
				
		// In case of constructors, now you can fetch the invariants and bind this.. 
		if (isConstructor) {
			ContractStore store = ContractStore.getInstance();
			inv = store.getInvariant(dyn.getClass());
			ceval.setThisBinding(dyn);
		}

		// Test postconditions
		String brokenContract = ceval.evalContract(post);
		if(brokenContract!=null) {
			throw new PostConditionException(brokenContract, getStaticSignature(callJp), getDynamicSignature(dyn.getClass(), sig));
		}
		
		// Test invariants
		brokenContract = ceval.evalContract(inv);
		if(brokenContract!=null) {
			throw new InvariantException(brokenContract, callJp.getSignature().getDeclaringTypeName(), getDynamicSignature(dyn.getClass(), sig), "postcondition");
		}
		
		// Test postcondition substitution rule 
		if (!isConstructor && AdbcConfig.checkSubstitutionPrinciple) {
			subPostCheck(ceval, true, dyn.getClass(), null, sig, postContracts, 0);
		} else if (AdbcConfig.checkSubstitutionPrinciple) {
			// Only test invariants for constructors
			subPostConstructorCheck(ceval, dyn.getClass(), null);
		}
	}
	
	/*
	 * Checks whether the current join point is the execution of an internal constructor in an aspect
	 * @param jp	thisJoinPoint
	 */
	private boolean aspectConstructorCheck(JoinPoint jp) {
		return jp.getThis().getClass().isAnnotationPresent(org.aspectj.lang.annotation.Aspect.class);
	}
	
	/*
	 * Check the precondition rule of behavioural subtyping
	 * (Subtype's precondition should be equal to or weaker than the supertype's. Invariants should also be preserved.)
	 * @param ceval			contract interpreter
	 * @param dynType		check whether this type's preconditions respect its parents
	 * @param toBeBlamed	blame this class if a contract is broken
	 * @param sig			signature of the method to be checked
	 * @param postContracts	when the method finishes, this will be filled up with the postconditions in the traversed type hierarchy, with their $old functions evaluated
	 * @return				true if the precondition+invariant rule holds
	 */
	private boolean subPreCheck(ContractInterpreter ceval, Class<?> dynType, Class<?> toBeBlamed, CodeSignature sig, Vector<String[]> postContracts) throws ScriptException {
		try {
			boolean res = false;
			boolean next = false;
			String brokenContract=null;
			ContractStore store = ContractStore.getInstance();
			
			// Note that getMethod basically does a lookup procedure! (unlike getDeclaredMethod)
			Method mBody = dynType.getMethod(sig.getName(), sig.getParameterTypes());
			
			brokenContract = ceval.evalContract(store.getPre(mBody));
			res = brokenContract==null;
			
			if (mBody.getDeclaringClass()!=Object.class) {
				next = subPreCheck(ceval, dynType.getSuperclass(), dynType, sig, postContracts);
			}
			
			String brokenInv = ceval.evalContract(store.getInvariant(dynType));
			if (brokenInv != null) {
				throw new SubstitutionException(brokenInv,dynType.getCanonicalName(), toBeBlamed.getCanonicalName(), "invariant not preserved");
			}

			postContracts.add(ceval.evalOldFunction(store.getPost(mBody)));

			if (!next || res) {
				return res;
			} else {
				throw new SubstitutionException(brokenContract,sig.toLongString() , dynType.getCanonicalName() + "." + mBody.toString(), "precondition too strong");
			}
		} catch (SecurityException e) {
			e.printStackTrace();
			return false;
		} catch (NoSuchMethodException e) {
			return false;
		}
		
	}
	
	/*
	 * Check the postcondition rule of behavioural subtyping
	 * (If the precondition of the supertype held in the pre-state,
	 * the postcondition of the subtype should be equal to or stronger than the supertype's.
	 * Invariants should also be preserved.)
	 * @param ceval		contract interpreter
	 * @param last		result of the caller 
	 * @param dynType	check whether this type's postconditions respect its parents
	 * @param toBeBlamed	blame this class if a contract is broken
	 * @param sig		signature of the method to be checked
	 * @param i			index indicating which entry of postContracts to use
	 * @return			true if the postcondition+invariant rule holds
	 */
	private boolean subPostCheck(ContractInterpreter ceval, boolean last, Class<?> dynType, Class<?> toBeBlamed, CodeSignature sig, Vector<String[]> postContracts, int i) throws ScriptException {
		try {
			boolean res = true;
			String brokenContract=null;
			Method mBody=null;
			ContractStore store = ContractStore.getInstance();

			mBody = dynType.getMethod(sig.getName(), sig.getParameterTypes());

			if (i<postContracts.size()) {
				brokenContract = ceval.evalContract(postContracts.get(i));
				res = brokenContract==null;
			}


			String brokenInv = ceval.evalContract(store.getInvariant(dynType));
			if (brokenInv != null) {
				throw new SubstitutionException(brokenInv,dynType.getCanonicalName(), toBeBlamed.getCanonicalName(), "invariant not preserved");
			}

			if (!last || res) {
				return subPostCheck(ceval, res, dynType.getSuperclass(), dynType, sig, postContracts, i+1);
			} else {
				throw new SubstitutionException(brokenContract, sig.toLongString() , dynType.getCanonicalName() + "." + mBody.toString(), "postcondition too weak");
			}
		} catch (SecurityException e) {
			e.printStackTrace();
			return true;
		} catch (NoSuchMethodException e) {
			return true;
		}
	}

	/*
	 * Check that invariants are preserved in the post-state of a constructor
	 * @param ceval			contract interpreter
	 * @param last			result of the caller 
	 * @param dynType		check whether this type's postconditions respect its parents
	 * @param toBeBlamed	blame this class if a contract is broken
	 * @return				true if the invariant rule holds
	 */
	private boolean subPostConstructorCheck(ContractInterpreter ceval,Class<?> dynType, Class<?> toBeBlamed) throws ScriptException {
		if(dynType==null) {
			return false;
		}

		ContractStore store = ContractStore.getInstance();
		String brokenInv = ceval.evalContract(store.getInvariant(dynType));
		if (brokenInv != null) {
			throw new SubstitutionException(brokenInv,dynType.getCanonicalName(), toBeBlamed.getCanonicalName(), "invariant not preserved");

		}
		return subPostConstructorCheck(ceval, dynType.getSuperclass(), dynType);
	}

	/*
	 * Retrieve the caller of the method
	 * @return the caller's signature
	 */
	private String getCallerSignature() {
		/* Runtime stack at this point:
		 * 0: getStackTrace()
		 * 1: getCallerSignature_aroundBody()
		 * 2: getCallerSignature()
		 * 3: preCheck_aroundBody()
		 * 4: preCheck()
		 * 5: inlineAccessMethod
		 * 6: contract advice
		 * 7: user advice
		 * 8+ The actual caller should be around here, after skipping all the internal stuff AspectJ creates.. */

		int i=8;
		StackTraceElement[] elems = Thread.currentThread().getStackTrace();
		while (i<elems.length) {
			String m = elems[i].getMethodName();

			// Anything ending in proceed or run or aroundBody should be internal AspectJ stuff..
			if(m.matches(".*proceed\\d*") || m.endsWith("run") || m.matches(".*aroundBody\\d*(\\$advice)?")) {
				i++;
			} else {
				return elems[i].getClassName() + "." + elems[i].getMethodName();
			}
		}
		return "(caller not found)";
	}

	/*
	 * Retrieve the signature of the method body in the method call's dynamic type
	 * @param dynType	dynamic type
	 * @param sig		method signature (its declaring type is ignored..)
	 * @return dynamic signature
	 */
	private String getDynamicSignature(Class<?> dynType, CodeSignature sig) {
		Method mBody;
		try {
			mBody = dynType.getMethod(sig.getName(), sig.getParameterTypes());
			return dynType.getCanonicalName() + "." + mBody.toString();
		} catch (Exception e) {
			return "(method not found)";
		}
	}

	/*
	 * Retrieve the signature of the method body in the method call's static type
	 * @param jp	call join point
	 * @return static signature	
	 */
	private String getStaticSignature(JoinPoint jp) {
		return jp.getSignature().toLongString();
	}

	/*
	 * Container for the data to be passed from preCheck() to postCheck()
	 */
	private class PostData {
		public PostData(ContractInterpreter ceval, String[] post, String[] inv, JoinPoint callJp, Vector<String[]> postContracts) {
			this.ceval = ceval;
			this.post = post;
			this.inv = inv;
			this.callJp = callJp;
			this.postContracts = postContracts;
		}
		
		public ContractInterpreter ceval;		// Contract interpreter
		public String[] post;					// Postconditions of method call's static type
		public String[] inv;					// Invariants of method call's static type
		
		public JoinPoint callJp;				// The call join point corresponding to the execution join point captured by the contract enforcement advice
		public Vector<String[]> postContracts;	// Postconditions of ancestors, with their $old() calls processed
	}
}
