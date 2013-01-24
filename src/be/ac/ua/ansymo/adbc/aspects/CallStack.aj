package be.ac.ua.ansymo.adbc.aspects;

import java.util.Stack;

import org.aspectj.lang.JoinPoint;


public aspect CallStack extends AbstractContractEnforcer {
	private static Stack<JoinPoint> stack = new Stack<JoinPoint>();
	
	/**
	 * Capture any method call and store the join point on a stack.
	 * Be sure to exclude calls to the JRE, since they don't generate any execution join points,
	 * which trips up the contract enforcement aspects..
	 * 
	 * TODO: We may get a similar problem when using libraries we don't have the source of..
	 * A more robust strategy may be to configure specifically which packages we're interested in,
	 * instead of trying to capture everything and excluding the parts that cause problems.. 
	 */
	before(): call(* *.*(..))
	&& !call(* java.*.*.*(..)) // Exclude JRE libs; these don't generate execution join points and will mess up
	&& excludeContractEnforcers() {
		thisJoinPoint.getTarget();
		stack.push(thisJoinPoint);
	}
	
	static public JoinPoint pop() {
		return stack.pop();
	}
	
	static public JoinPoint peek() {
		return stack.peek();
	}
}
