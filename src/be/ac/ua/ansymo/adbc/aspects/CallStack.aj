package be.ac.ua.ansymo.adbc.aspects;

import java.util.Stack;

import org.aspectj.lang.JoinPoint;


public aspect CallStack extends AbstractContractEnforcer {
	private static Stack<JoinPoint> stack = new Stack<JoinPoint>();
	
	/**
	 * Capture any method call and store the join point on a stack.
	 * 
	 * We're doing this because contract enforcement needs to happen at the very, very last moment.
	 * That is, contract enforcement has to be the last advice at the execution join point.
	 * We want to check the contracts of the original piece of code only, nothing more.
	 * Problem with that is, an execution join point doesn't know the static type of the corresponding call
	 * join point. We need this static type to be able to check the substitution principle.
	 * This is why we need this CallStack aspect. It captures the call join point, and makes it available 
	 * for the execution join point.
	 * 
	 * TODO: We may get a similar problem when using libraries we don't have the source of..
	 * A more robust strategy may be to configure specifically which packages we're interested in,
	 * instead of trying to capture everything and excluding the parts that cause problems.. 
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
