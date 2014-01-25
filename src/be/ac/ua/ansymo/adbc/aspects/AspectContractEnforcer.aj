/*******************************************************************************
 * Copyright (c) 2012-2014 Tim Molderez.
 * 
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the 3-Clause BSD License
 * which accompanies this distribution, and is available at
 * http://www.opensource.org/licenses/BSD-3-Clause
 ******************************************************************************/

package be.ac.ua.ansymo.adbc.aspects;

import java.lang.reflect.Method;
import java.util.Arrays;
import java.util.EmptyStackException;
import java.util.Vector;

import javax.script.ScriptException;

import org.aspectj.lang.Aspects;
import org.aspectj.lang.JoinPoint;
import org.aspectj.lang.annotation.AdviceName;
import org.aspectj.lang.reflect.AdviceSignature;
import org.aspectj.lang.reflect.MethodSignature;

import be.ac.ua.ansymo.adbc.AdbcConfig;
import be.ac.ua.ansymo.adbc.annotations.advisedBy;
import be.ac.ua.ansymo.adbc.annotations.ensures;
import be.ac.ua.ansymo.adbc.annotations.pointcutRuntimeTest;
import be.ac.ua.ansymo.adbc.annotations.requires;
import be.ac.ua.ansymo.adbc.exceptions.InvariantException;
import be.ac.ua.ansymo.adbc.exceptions.PostConditionException;
import be.ac.ua.ansymo.adbc.exceptions.PreConditionException;
import be.ac.ua.ansymo.adbc.exceptions.SubstitutionException;
import be.ac.ua.ansymo.adbc.utilities.ContractInterpreter;
import be.ac.ua.ansymo.adbc.utilities.ContractStore;

/**
 * This aspect enforces the contracts of all aspects in the application. 
 * If a contract is broken, a ContractEnforcementException is thrown.
 * 
 * @author Tim Molderez
 */
public aspect AspectContractEnforcer extends AbstractContractEnforcer {

	/**
	 * Contract enforcer for advice
	 * @param dyn	the user-advice
	 */
	Object around(Object dyn): adviceexecution() && this(dyn) 
	&& !within(be.ac.ua.ansymo.adbc.aspects.*) && excludeContractEnforcers() {
		/* Very sensitive pointcut!! Only use what's excluded by excludeContractEnforcers()
		 * or you'll trigger an infinite recursion! */

		try {
			PostData pD = preCheck(thisJoinPoint, dyn);
			Object result = proceed(dyn);
			if (pD != null && AdbcConfig.checkPostconditions) {
				postCheck(pD, thisJoinPoint,dyn, result);
			}
			return result;
		} catch (ScriptException e) {
			throw new RuntimeException("Failed to evaluate contract: " + e.getMessage());
		}
	}

	/*
	 * Do the necessary preparation and
	 * check all contracts before advice execution (preconditions, invariants, substitution principle)
	 * @param jp	thisJoinPoint
	 * @param dyn	the user-advice
	 * @return data to be passed on to postCheck()
	 */
	private PostData preCheck(JoinPoint jp, Object dyn) throws ScriptException {
		/* ****************************************************************
		 * Fetching the necessary info...
		 **************************************************************** */
		
		// Retrieve the join point advised by the user-advice
		JoinPoint tjp = null;
		try {
			// Note that we're peeking into CallStack, not popping! Other contract enforcement advice still need this top entry!
			tjp = CallStack.peek();
		} catch (EmptyStackException e) {
			/* In case the advice we've intercepted advises join points other than calls and executions,
			 * there's not going to be an entry on the CallStack for it..
			 * TODO: For now we don't support these kinds of advice yet. */
			return null;
		}

		// Retrieve the method being advised by the user-advice
		String m = tjp.getSignature().toString();
		int lastdot = m.lastIndexOf('.');
		m = m.substring(lastdot + 1, m.length());
		Method mBody = ((MethodSignature) tjp.getSignature()).getMethod();

		// Retrieve the user-advice
		ContractStore store = ContractStore.getInstance();
		AdviceSignature aSig = (AdviceSignature) (jp.getSignature());
		Method aBody = aSig.getAdvice();

		// Determine whether this advice is mentioned in an @advisedBy clause. And if so, which advice follow in that clause?
		String[] advBySuffix = isAdvisedBy(mBody, aBody, tjp.getKind());
		boolean isAdvisedBy = advBySuffix != null;

		// Get the contracts of the user-advice's advised joinpoint
		String[] pre = store.getPre(mBody);
		String[] post = store.getPost(mBody);
		String[] inv = tjp.getTarget()==null?new String[]{"true"}:store.getInvariant(tjp.getTarget().getClass());
		
		// Get the contracts of the user-advice itself		
		String[] advPre = store.getPre(aBody);
		String[] advPost = store.getPost(aBody);
		String[] advInv = store.getInvariant(dyn.getClass());

		// Determine user-advice kind (relying on its internal method name)
		String advKind = "around";
		if (aSig.getName().contains("$before$")) {
			advKind = "before";
		} else if (aSig.getName().contains("$after$")) {
			advKind = "after";
		}

		/* ****************************************************************
		 * Binding contract variables
		 **************************************************************** */

		// Reset bindings
		ContractInterpreter ceval = new ContractInterpreter();

		// Resolve the $proc keyword + $this variable binding (of the user advice's this object)
		if(isAdvisedBy && advKind.equals("around")) {
			AdvBySuffix suffixInfo = getAdvBySuffixContracts(advBySuffix);
			suffixInfo.aspectInstances.add(0, jp.getThis());
			pre = ceval.evalProc(advPre, pre, suffixInfo.pre, suffixInfo.runtimeTests, suffixInfo.aspectInstances);
			post = ceval.evalProc(advPost, post, suffixInfo.post, suffixInfo.runtimeTests, suffixInfo.aspectInstances);
		} else {
			advPre = ceval.evalProc(advPre, pre, jp.getThis());
			advPost = ceval.evalProc(advPost, post, jp.getThis());
		}
		
		// Bind $this to the advised method call's receiver
		ceval.setThisBinding(tjp.getTarget());
		
		// Bind parameter values of advised join point and the advice itself
		MethodSignature mSig = (MethodSignature) (tjp.getSignature());
		ceval.setParameterBindings(mSig.getParameterNames(),tjp.getArgs());
		ceval.setParameterBindings(aSig.getParameterNames(),jp.getArgs());
		
		/* ****************************************************************
		 * Actual contract enforcement
		 **************************************************************** */
		
		// Test preconditions
		if (!advKind.equals("after")) {
			String stPreFailed = ceval.evalContract(pre);
			if (stPreFailed != null) {
				throw new PreConditionException(stPreFailed, getStaticSignature(tjp), getCallerSignature());
			}
		}
		
		// Test invariants
		String invFailed = ceval.evalContract(inv);
		if (invFailed != null) {
			throw new InvariantException(invFailed, tjp.getSignature().getDeclaringTypeName(), getCallerSignature(), "precondition");
		}

		// Test advice substitution (if applicable)
		if (!isAdvisedBy && AdbcConfig.checkSubstitutionPrinciple) {
			ceval.setParameterBindings(aSig.getParameterNames(),jp.getArgs());

			String jpPreFailed = ceval.evalContract(advPre);
			if (jpPreFailed != null) {
				throw new SubstitutionException(jpPreFailed, getDynamicSignature(jp), getDynamicSignature(jp), "precondition too strong");
			}

			invFailed = ceval.evalContract(advInv);
			if (invFailed != null) {
				throw new InvariantException(invFailed, jp.getSignature().getDeclaringTypeName(), getDynamicSignature(jp), "invariant not preserved");
			}
		}
		
		// Evaluate calls to the $old() function in postconditions of advice
		try {
			if (AdbcConfig.checkPostconditions && !isAdvisedBy && AdbcConfig.checkSubstitutionPrinciple) {
				advPost = ceval.evalOldFunction(advPost);
			}
		} catch (ScriptException e) {
			throw new RuntimeException("Failed to evaluate old() call: " + e.getMessage());
		}

		// Evaluate calls to the $old() function in postconditions of the advised join point
		try {
			if (AdbcConfig.checkPostconditions) {	
				post = ceval.evalOldFunction(post);
			}
		} catch (ScriptException e) {
			throw new RuntimeException("Failed to evaluate old() call: " + e.getMessage());
		}
		
		return new PostData(ceval, post, inv, advPost, advInv, tjp, advKind, isAdvisedBy);
	}

	/*
	 * Check contracts after advice execution (postconditions, invariants, substitution principle)
	 * @param pD		container object with various information produced during the preCheck
	 * @param jp		thisJoinPoint
	 * @param dyn		the user-advice instance
	 * @param result	return value of the user-advice execution
	 */
	private void postCheck(PostData pD, JoinPoint jp, Object dyn, Object result) throws ScriptException {
		ContractInterpreter ceval = pD.ceval;
		
		// Bind the return value
		ceval.setReturnValueBinding(result);

		// Test postconditions
		if (!pD.advKind.equals("before")) {
			String stPostFailed = ceval.evalContract(pD.post);
			if (stPostFailed != null) {
				throw new PostConditionException(stPostFailed, getStaticSignature(pD.tjp), getDynamicSignature(jp));
			}
		}

		// Test invariants
		String invFailed = ceval.evalContract(pD.inv);
		if (invFailed != null) {
			throw new InvariantException(invFailed, pD.tjp.getSignature().getDeclaringTypeName(), getDynamicSignature(jp), "postcondition");
		}

		// Test advice substitution
		if (!pD.isAdvisedBy && AdbcConfig.checkSubstitutionPrinciple) {
			String jpPostFailed = ceval.evalContract(pD.advPost);
			
			if (jpPostFailed != null) {
				throw new SubstitutionException(jpPostFailed, jp.getSignature().getDeclaringTypeName(), getDynamicSignature(jp), "postcondition too weak");
			}

			invFailed = ceval.evalContract(pD.advInv);
			if (invFailed != null) {
				throw new InvariantException(invFailed, jp.getSignature().getDeclaringTypeName(), getDynamicSignature(jp), "invariant not preserved");
			}
		}
	}
	
	/*
	 * Determine whether advice aBody appears in the advisedBy clause of method mBody (or the same method in an ancestor class)
	 * @param mBody				the method being advised
	 * @param aBody				the user-advice
	 * @param joinpointKind		kind of the advised join point (e.g. "method call")
	 * @return					if the advice is mentioned in an @advisedBy clause, return a list of the advice names that follow
	 * 							; if the advice isn't mentioned, return null
	 */
	private String[] isAdvisedBy(Method mBody, Method aBody, String joinpointKind) {
		// We only allow advice on call join points to be mentioned in @advisedBy clauses
		if (!joinpointKind.equals("method-call")) {
			return null;
		}
		
		// The advice must have a name in order for it to be mentioned..
		if (!aBody.isAnnotationPresent(AdviceName.class)) {
			return null;
		}

		String advName = aBody.getAnnotation(AdviceName.class).value();
		Class<?> mClass = mBody.getDeclaringClass();
		Class<?>[] mParTypes = mBody.getParameterTypes();
		String mName = mBody.getName();

		while(mClass!=null) {
			try {
				mBody = mClass.getMethod(mName, mParTypes);
				// If there's an @advisedBy annotation, go check whether aBody is mentioned..
				if (mBody.isAnnotationPresent(advisedBy.class)) {
					String[] advBy = mBody.getAnnotation(advisedBy.class).value();
					int i=0;
					for (String listedName : advBy) {
						if(listedName.equals(aBody.getDeclaringClass().getCanonicalName() + "." + advName)) {
							return Arrays.copyOfRange(advBy, i+1, advBy.length);
						}
						i++;
					}
				}
			} catch (Exception e) {/* If the method is not found within mClass, do nothing.. */}
			mClass = mClass.getSuperclass();
		}
		return null;
	}
	
	/*
	 * Given a list of advice that follow after the current advice (in the @advisedBy annotation in which the current advice is mentioned),
	 * return the preconditions and postconditions of those advice, as well as the run-time portion of their pointcuts
	 * @param advBySuffix	list of following advice names in @advisedBy annotation
	 * @return contracts of following advice mentioned in @advisedBy annotation
	 */
	private AdvBySuffix getAdvBySuffixContracts(String[] advBySuffix) {
		AdvBySuffix result = new AdvBySuffix();
		result.pre = new Vector<String[]>();
		result.post = new Vector<String[]>();
		result.runtimeTests = new Vector<String>();
		result.aspectInstances = new Vector<Object>();
		
		for (String adv : advBySuffix) {
			try {
				ContractStore store = ContractStore.getInstance();
				int separator = adv.lastIndexOf('.');
				String aspectName = adv.substring(0, separator);
				String adviceName = adv.substring(separator+1, adv.length());

				Class<?> asp = Class.forName(aspectName);
				result.aspectInstances.add(Aspects.aspectOf(asp));
				
				// Find the advice with the name we're looking for
				for (Method adv2 : asp.getMethods()) {
					if(adv2.isAnnotationPresent(AdviceName.class)&& adv2.getAnnotation(AdviceName.class).value().equals(adviceName)) {
						String[] proc = {"$proc"};
						if (adv2.isAnnotationPresent(requires.class)) {
							result.pre.add(store.getPost(adv2));
						} else {
							result.pre.add(proc);
						}
						
						if (adv2.isAnnotationPresent(ensures.class)) {
							result.post.add(store.getPost(adv2));
						} else {
							result.post.add(proc);
						} 
						
						if(adv2.isAnnotationPresent(pointcutRuntimeTest.class)) {
							result.runtimeTests.add(adv2.getAnnotation(pointcutRuntimeTest.class).value());
						} else {
							result.runtimeTests.add("true");
						}
					}
				}
			} catch (ClassNotFoundException e) {
				e.printStackTrace();
			}
		}
		return result;
	}

	/*
	 * Retrieve the caller of the user-advice
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
	 * Retrieve the signature of the user-advice
	 * @param dynType	dynamic type
	 * @param sig		method signature (its declaring type is ignored..)
	 * @return dynamic signature
	 */
	private String getDynamicSignature(JoinPoint jp) {
		AdviceSignature aSig = (AdviceSignature) (jp.getSignature());
		Method aBody = aSig.getAdvice();
		String advName = "anonymous";
		if (aBody.isAnnotationPresent(AdviceName.class)) {
			advName = aBody.getAnnotation(AdviceName.class).value();
		}
		
		return aSig + "(Advice name: " + advName + ")";
	}
	
	/*
	 * Retrieve the signature of the advised joinpoint
	 * @param jp	call join point
	 * @return static signature	
	 */
	private String getStaticSignature(JoinPoint jp) {
		return jp.getSignature().toLongString();
	}
	
	// Container for return value of getAdvBySuffixContracts
	private class AdvBySuffix {
		public Vector<String[]> pre;
		public Vector<String[]> post;
		public Vector<String> runtimeTests;
		public Vector<Object> aspectInstances;
	}
	
	// Container for the data to be passed from preCheck() to postCheck()
	private class PostData {
		public PostData(ContractInterpreter ceval, String[] post,
				String[] inv, String[] advPost,
				String[] advInv, JoinPoint tjp, String advKind, boolean isAdvisedBy) {
			this.ceval = ceval;
			this.post = post;
			this.inv = inv;
			this.advPost = advPost;
			this.advInv = advInv;
			this.tjp = tjp;
			this.advKind = advKind;
			this.isAdvisedBy = isAdvisedBy;
		}
		
		public ContractInterpreter ceval;	// Contract interpreter
		
		public String[] post;				// Postconditions of advised join point
		public String[] inv;				// Invariants of advised join point
		
		// Contracts of the user-advice
		public String[] advPost;			// Postconditions of the user-advice
		public String[] advInv;				// Invariants of the user-advice
		
		public JoinPoint tjp;				// The thisjoinpoint object of the user-advice
		public String advKind;				// User-advice kind (before, after around)
		public boolean isAdvisedBy;			// Is the user-advice mentioned in an @advisedBy clause?
	}
}
