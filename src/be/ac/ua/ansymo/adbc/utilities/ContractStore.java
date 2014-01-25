/*******************************************************************************
 * Copyright (c) 2012-2014 Tim Molderez.
 * 
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the 3-Clause BSD License
 * which accompanies this distribution, and is available at
 * http://www.opensource.org/licenses/BSD-3-Clause
 ******************************************************************************/

package be.ac.ua.ansymo.adbc.utilities;

import java.lang.reflect.AccessibleObject;
import java.lang.reflect.Constructor;
import java.lang.reflect.Method;
import java.util.HashMap;

import be.ac.ua.ansymo.adbc.AdbcConfig;
import be.ac.ua.ansymo.adbc.annotations.ensures;
import be.ac.ua.ansymo.adbc.annotations.invariant;
import be.ac.ua.ansymo.adbc.annotations.requires;


/**
 * Singleton used to retrieve the contracts of a certain class or aspect
 * @author Tim Molderez
 */
public class ContractStore {
	private static String superKeyword = AdbcConfig.keywordPrefix + "super";
	
	private static ContractStore instance = new ContractStore();
	private HashMap<String, String[]> preStore = new HashMap<String, String[]>();
	private HashMap<String, String[]> postStore = new HashMap<String, String[]>();
	private HashMap<String, String[]> invStore = new HashMap<String, String[]>();
	String[] defaultContract = new String[]{"$super"};
	
	/*
	 * Private constructor (singleton pattern)
	 */
	private ContractStore() {}
	
	/**
	 * Retrieve the ContractStore instance
	 * @return
	 */
	public static ContractStore getInstance() {
		return instance;
	}
	
	/**
	 * Retrieve the precondition of a certain method
	 * (with $super already filled in..)
	 * @param body
	 * @return
	 */
	public String[] getPre(AccessibleObject body) {
		String key = body.toString();
		String[] pre = preStore.get(key);
		
		// Cache miss; go find the contract and fill in $super
		if (pre == null) {
			// Find the contract
			if (body.isAnnotationPresent(requires.class)) {
				pre = body.getAnnotation(requires.class).value();
			} else {
				pre = defaultContract;
			}
			
			// Fill in $super
			AccessibleObject overridden = null;
			if (body instanceof Method) {
				overridden = getOverriddenMethod((Method)body);	
			} else if (body instanceof Constructor<?>) {
				overridden = getOverriddenConstructor((Constructor<?>)body);
			}
			
			String overriddenPre = "true";
			if (overridden != null) {
				overriddenPre = ContractInterpreter.mergeContracts((getPre(overridden)));
			}
			
			int i=0;
			for (String contract : pre) {
				pre[i]=contract.replace(superKeyword, "(" + overriddenPre + ")");
				i++;
			}
			preStore.put(key, pre);
		}
		return pre;
	}
	
	/**
	 * Retrieve the postcondition of a certain method
	 * (with $super already filled in..)
	 * @param body
	 * @return
	 */
	public String[] getPost(AccessibleObject body) {
		String key = body.toString();
		String[] post = postStore.get(key);
		
		// Cache miss; find the contract and fill in $super
		if(post==null) {
			// Find the contract
			if (body.isAnnotationPresent(ensures.class)) {
				post = body.getAnnotation(ensures.class).value();
			} else {
				post = defaultContract;
			}
			
			// Fill in $super
			AccessibleObject overridden = null;
			if (body instanceof Method) {
				overridden = getOverriddenMethod((Method)body);	
			} else if (body instanceof Constructor<?>) {
				overridden = getOverriddenConstructor((Constructor<?>)body);
			}
			
			String overriddenPost = "true";
			if (overridden != null) {
				overriddenPost = ContractInterpreter.mergeContracts((getPost(overridden)));
			}
			
			int i=0;
			for (String contract : post) {
				post[i]=contract.replace(superKeyword, "(" + overriddenPost + ")");
				i++;
			}
			postStore.put(key, post);
		}
		
		return post;
	}
	
	/**
	 * Retrieve the invariants of a class
	 * (with $super already filled in..)
	 * @param body
	 * @return
	 */
	public String[] getInvariant(Class<?> cls) {
		String key = cls.toString();
		String[] inv = invStore.get(key);
		
		// Cache miss; find the contract and fill in $super
		if(inv==null) {
			// Find the contract
			if (cls.isAnnotationPresent(invariant.class)) {
				inv = cls.getAnnotation(invariant.class).value();
			} else {
				inv = defaultContract;
			}
			
			// Fill in $super
			Class<?> superCls = cls.getSuperclass();
			String superInv = "true";
			if (superCls != null) {
				superInv = ContractInterpreter.mergeContracts((getInvariant(superCls)));
			}
			
			int i=0;
			for (String contract : inv) {
				inv[i]=contract.replace(superKeyword, "(" + superInv + ")");
				i++;
			}
			invStore.put(key, inv);
		}
		
		return inv;
	}
	
	/*
	 * Given a constructor body, go find the body it overrides, if any.
	 * (If none is found, null is returned.) 
	 * @param m
	 * @return
	 */
	private AccessibleObject getOverriddenConstructor(Constructor<?> m) {
		Class<?> current = m.getDeclaringClass();
		Class<?>[] types = m.getParameterTypes();
		
		while (current.getSuperclass() != null) {
			current = current.getSuperclass();
			try {
				AccessibleObject found = current.getConstructor(types);
				return found;
			} catch (NoSuchMethodException e) {
			} catch (SecurityException e) {e.printStackTrace();}
		}
		return null;
	}
	
	/*
	 * Given a method body, go find the body it overrides, if any.
	 * (If none is found, null is returned.) 
	 * @param m
	 * @return
	 */
	private AccessibleObject getOverriddenMethod(Method m) {
		Class<?> current = m.getDeclaringClass();
		String name = m.getName();
		Class<?>[] types = m.getParameterTypes();
		
		while (current.getSuperclass() != null) {
			current = current.getSuperclass();
			try {
				AccessibleObject found = current.getMethod(name, types);
				return found;
			} catch (NoSuchMethodException e) {
			} catch (SecurityException e) {e.printStackTrace();}
		}
		return null;
	}
}
