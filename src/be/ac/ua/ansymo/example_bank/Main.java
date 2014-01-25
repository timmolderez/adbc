/*******************************************************************************
 * Copyright (c) 2012-2014 Tim Molderez.
 * 
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the 3-Clause BSD License
 * which accompanies this distribution, and is available at
 * http://www.opensource.org/licenses/BSD-3-Clause
 ******************************************************************************/

package be.ac.ua.ansymo.example_bank;

import be.ac.ua.ansymo.example_bank.aspects.Authentication;
import be.ac.ua.ansymo.example_bank.aspects.Authorization;

//import be.ac.ua.ansymo.example_bank.aspects.Authentication;
//import be.ac.ua.ansymo.example_bank.aspects.Authorization;

/**
 * A simple demo application to demonstrate the use of the contract enforcer
 * Just tinker around with the contracts in the application, or modify the
 * calls within this main() function to see what happens if a contract is violated.
 * 
 * @author Tim Molderez
 */
public class Main {
	
	static Main inst = new Main();

	public static void main(String[] args) {
		try {
			// Uncomment to alter adbc's settings
//			AdbcConfig.enforceContracts = false;
//			AdbcConfig.engine = "JavaScript";
//			AdbcConfig.keywordPrefix = "$";
			
			inst.start();
		} catch (Exception e) {
			e.printStackTrace();
		}
	}
	
	public void start() {
		User u1 = new User("Finn");
		Account u1acc1 = new Account(30.0, u1);
		Account u1acc2 = new SavingsAccount(30.0, u1);
		
		User u2 = new User("Jake");
		Account u2acc1 = new Account(30.0, u2);
		
		/* Remove these two lines and contracts will still be satisfied when calling transfer() later on,
		 * even though the transfer operation is actually blocked by the authentication/authorization advice in Security.
		 * This is because, when looking at transfer(), there is an @advisedBy annotation there, indicating that
		 * we should be aware of the authentication/authorization advice in Security.
		 * However, try to see what happens if you remove these two lines and the @advisedBy clause. */
		Authentication.login(u1, "Peebles");
		Authorization.addRights(u1, "transfer");
		
		u1acc1.transfer(5.0, u2acc1);
		
//		u1acc2.transfer(5.0, u2acc1); // Uncomment this line to trigger a substitution error; the precondition of SavingsAccount.transfer is stronger than that of Account
		u1acc2.transfer(10.0, u1acc1);
	}
}
