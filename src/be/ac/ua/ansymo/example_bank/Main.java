package be.ac.ua.ansymo.example_bank;

import be.ac.ua.ansymo.example_bank.aspects.Authentication;

/**
 * A simple demo application to demonstrate the use of the contract enforcer
 * Just tinker around with the contracts in the application, or modify the
 * calls within this main() function to see what happens if a contract is violated.
 * 
 * @author Tim Molderez
 * 
 */
public class Main {

	/**
	 * Start the demo application
	 * @param args
	 */
	public static void main(String[] args) {
		try {
			User u1 = new User("Finn");
			Account u1acc1 = new Account(30.0, u1);
			Account u1acc2 = new SavingsAccount(30.0, u1);
			
			User u2 = new User("Jake");
			Account u2acc1 = new Account(30.0, u2);
			
			Authentication.login(u1, "Peebles"); // Comment this out and Authentication will break the postcondition of its advised join point
			
			u1acc1.transfer(5.0, u2acc1);
			
//			u1acc2.transfer(5.0, u2acc1); // Uncomment this line to trigger a Liskov substitution error; precondition of SavingsAccount.transfer is stronger than that of Account
			u1acc2.transfer(10.0, u1acc1);	
		} catch (Exception e) {
			System.err.println(e.getMessage());
		}
	}
}