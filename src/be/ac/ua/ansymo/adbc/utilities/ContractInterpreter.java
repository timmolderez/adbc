/**
 * Copyright (c) 2012 Tim Molderez.
 * 
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the 3-Clause BSD License
 * which accompanies this distribution, and is available at
 * http://www.opensource.org/licenses/BSD-3-Clause
 */

package be.ac.ua.ansymo.adbc.utilities;

import java.util.Vector;

import javax.script.ScriptEngine;
import javax.script.ScriptEngineManager;
import javax.script.ScriptException;

import be.ac.ua.ansymo.adbc.AdbcConfig;

/**
 * Helper class used to evaluate contracts 
 * @author Tim Molderez
 */
public class ContractInterpreter {
	
	private ScriptEngine engine;
	private int oldCounter;
	
	private static String thisKeyword = AdbcConfig.keywordPrefix + "this";
	private static String resultKeyword = AdbcConfig.keywordPrefix + "result";
	private static String oldKeyword = AdbcConfig.keywordPrefix + "old";
	private static String procKeyword = AdbcConfig.keywordPrefix + "proc";
	
	/**
	 * Default constructor
	 */
	public ContractInterpreter() {
		ScriptEngineManager manager = new ScriptEngineManager();
		engine = manager.getEngineByName(AdbcConfig.engine);
	}
	
	/**
	 * Evaluates a series of contracts.
	 * @param contracts to be evaluated
	 * @return null if all contracts passed; otherwise the first failing contract is returned
	 * @throws ScriptException if a contract could not be interpreted
	 */
	public String evalContract(String[] contracts) throws ScriptException {
		boolean passed = true;
		for (int i = 0; i < contracts.length || !passed; i++) {
			if (!(Boolean)(engine.eval(contracts[i]))) {
				return contracts[i];
			}
		}
		return null;
	}
		
	/**
	 * Set a binding to the "this" object, available as the $this variable in contracts
	 * @param t		the this object to be bound
	 */
	public void setThisBinding(Object t) {
		engine.put(thisKeyword, t);
	}
	
	/**
	 * Set a binding to the return value, available as the $result variable in postconditions
	 * @param t
	 */
	public void setReturnValueBinding(Object t) {
		engine.put(resultKeyword, t);
	}
	
	/**
	 * Bind the parameters that can occur in a contract
	 * @param names		names of each parameter, may be null 
	 * 					(If null, paramaters are available as "arg0", "arg1", .. as names)
	 * @param values	value of each parameter (in the same order as names)
	 */
	public void setParameterBindings(String[] names, Object[] values) {
		for (int i = 0; i < values.length; i++) {
			if (names!=null && i<names.length) {
				engine.put(names[i], values[i]);
			} else {
				engine.put("arg"+i, values[i]);
			}
		}
	}
	
	/**
	 * Evaluate the proc keyword, in case an advice is *not* mentioned in an @advisedBy clause 
	 * @param jpContracts
	 */
	public String[] evalProc(String[] advContracts, String[] jpContracts) {
		String proc = mergeContracts(jpContracts);
		
		int i=0;
		for (String contract : advContracts) {
			advContracts[i]=contract.replaceAll(procKeyword, proc);
			i++;
		}
		return advContracts;
	}
	
	public String[] evalProc(String[] advContracts, String[] jpContracts, Vector<String[]> advByContracts, Vector<String> advByRuntimeTests) {
		return evalProc_pr(-1, advContracts, jpContracts, advByContracts, advByRuntimeTests);
	}
	
	private String[] evalProc_pr(int i, String[] advContracts, String[] jpContracts, Vector<String[]> advByContracts, Vector<String> advByRuntimeTests) {
		String[] result = new String[advContracts.length];
		
		String proc = evalProc_ab(i+1, jpContracts, advByContracts, advByRuntimeTests);
		
		int j=0;
		for (String contract : advContracts) {
			result[j] = contract.replaceAll(procKeyword, proc);
			j++;
		}
		return result;
	}
	
	private String evalProc_ab(int i, String[] jpContracts, Vector<String[]> advByContracts, Vector<String> advByRuntimeTests) {
		// Base case
		if (i==advByContracts.size()) {
			return mergeContracts(jpContracts);
		}
		
		// Recursive case
		String result="";
		int j=i;
		String separator = "if(";
		while(j<advByRuntimeTests.size() && !advByRuntimeTests.get(j).equals("true")) {
			String proc = mergeContracts(evalProc_pr(j, advByContracts.get(j), jpContracts, advByContracts, advByRuntimeTests));
			result += separator + advByRuntimeTests.get(j) + "){" + proc  + "}";
			
					separator = "else if(";
			j++;
		}
		
		// If we exited the loop because the jth entry is "true", the remaining advice after j are unreachable..
		if(j != advByRuntimeTests.size()) { 
			String proc = mergeContracts(evalProc_pr(j, advByContracts.get(j), jpContracts, advByContracts, advByRuntimeTests));
			if(j==0) {
				result = proc;
			} else {
				result += " else {" + proc + "}";
			}
		// If we exited the loop because we processed all advice in the @advisedBy clause
		} else {
			result += " else {" + mergeContracts(jpContracts) + "}";
		}
		
		return result;
	}
	
	/*
	 * Concatenates an array of contracts (e.g. the preconditions of a method) into one contract, using the && operation
	 */
	private String mergeContracts(String[] contracts) {
		String combined = "";
		String separator = "";
		for (String contract : contracts) {
			combined += separator + contract;
			separator = " && ";
		}
		return combined;
	}
	
	/**
	 * Evaluates all calls to the old() function in a postcondition (may be composed of multiple parts)
	 * @param postCondition	the postcondition
	 * @return				an altered version of the postcondition is returned, in which each old() call
	 * 						is replaced by a variable, which is now bound to the result of that old() call
	 * @throws ScriptException
	 */
	public String[] evalOldFunction(String[] postCondition) throws ScriptException {
		String[] result = new String[postCondition.length];
		for (int i = 0; i < postCondition.length; i++) {
			result[i] = evalOldFunction_helper(postCondition[i]); 
		}
		return result;
	}
	
	/*
	 * Recursive helper function for evalOldFunction()
	 */
	private String evalOldFunction_helper(String expr) throws ScriptException {
		// Find the first old call, if any
		int openPos = expr.indexOf(oldKeyword + "("); 
		if (openPos == -1) {
			return expr;
		}
		openPos +=5; // Get the index right behind the starting bracket of the old function
		
		// Find the index of the matching closing bracket
		int bracketMatcher = 1;
		int i = openPos;
		while(i< expr.length() && bracketMatcher != 0) { 
			if (expr.charAt(i) == '(') {
				bracketMatcher++;
			} else if (expr.charAt(i) == ')') {
				bracketMatcher--;
			}
			i++;
		}

		if (bracketMatcher==0) {
			oldCounter++;
			
			Object oldResult = engine.eval(expr.substring(openPos, i-1));
			engine.put(oldKeyword + oldCounter, oldResult);
			
			// Return the part before the first old() call + the result of the old() call + recursion on the remainder.
			return expr.substring(0, openPos-5) 
					+ oldKeyword + oldCounter 
					+ evalOldFunction_helper(expr.substring(i));
		} else {
			throw new ScriptException("No matching brackets in call to old function.");
		}
	}
}
