package be.ac.ua.ansymo.example_bank.aspects;

import be.ac.ua.ansymo.adbc.annotations.ensures;
import be.ac.ua.ansymo.adbc.annotations.requires;
import be.ac.ua.ansymo.example_bank.Account;
import be.ac.ua.ansymo.example_bank.User;

/**
 * Checks the authentication of users in the bank
 */
public aspect Authentication {
	private boolean User.loggedIn = false;
	
	public boolean User.isLoggedIn() {
		return loggedIn;
	}
	
	@requires("to!=null")
	@ensures({"from.getOwner().isLoggedIn()?from.getAmount()==$old(from.getAmount())-amount:false",
		"from.getOwner().isLoggedIn()?to.getAmount()==$old(to.getAmount())+amount:false"})
	
	void around(Account from, double amount, Account to): execution(void Account.transfer(double, Account)) 
	&& args(amount, to) && this(from) {
		if (from.getOwner().isLoggedIn()) {
			proceed(from, amount, to);
		} else {
			System.err.println(from.getOwner().getName() + " is not logged in!");
		}
	}
	
	@requires("u!=null")
	@ensures("u.isLoggedIn()")
	public static void login(User u, String password) {
		// Password is unused; some authentication this is..
		u.loggedIn = true;
	}
}
