package be.ac.ua.ansymo.example_bank.aspects;

/**
 * Some advice meant for debugging/experimentation..
 */
public aspect Debug {
//	@requires("$proc")
//	@ensures("true")
//	after(): call(void Account.*(..)) {
//		System.out.println("Testing");
//	}
	
	/* If an advice breaks the advice substitution principle, @advisedBy annotations should be added to its join point shadows.
	 * On the upside though, you can use these annotations to make your pointcuts simpler, and more stable.
	 * 
	 * That is, rather than saying the advice should match on call X, Y & Z, you could just say
	 * that it only needs to match with those methods that mention you in their @advisedBy annotation.
	 */
//	@AdviceName("Test")
//	after(): call(@advisedBy * *(..)) {
//		String[] advBy = ((MethodSignature)(thisJoinPoint.getSignature())).getMethod().getAnnotation(advisedBy.class).value();
//		
//		for (String adv : advBy) {
//			if (adv.equals(this.getClass().getCanonicalName() + ".Test")) {
//				System.out.println("match!");
//			}
//		}
//	}
}
