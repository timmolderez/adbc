package be.ac.ua.ansymo.example_bank.aspects;

import java.util.HashSet;

import org.aspectj.lang.annotation.AdviceName;

import be.ac.ua.ansymo.adbc.annotations.ensures;
import be.ac.ua.ansymo.adbc.annotations.requires;
import be.ac.ua.ansymo.example_bank.Account;
import be.ac.ua.ansymo.example_bank.User;

/**
 * Checks the authentication/authorisation of users in the bank
 */
public aspect Security {
	private boolean User.loggedIn = false;
	
	private HashSet<String> User.rights;
	
	public boolean User.isLoggedIn() {
		return loggedIn;
	}
	
	public boolean User.isAuthorized() {
		return true;
	}
	
	@requires("u!=null")
	@ensures("u.isLoggedIn()")
	public static void login(User u, String password) {
		// Password is unused; some authentication this is..
		u.loggedIn = true;
	}
	
	@requires("u.isLoggedIn()")
	public static void addRights(User u, String key) {
		
	}
	
	@requires("$proc")
	@ensures({"from.getOwner().isLoggedIn()?$proc:true"})
	@AdviceName("authenticate")
	void around(Account from, double amount, Account to): call(void Account.transfer(double, Account)) 
	&& args(amount, to) && target(from) {
		if (from.getOwner().isLoggedIn()) {
			System.out.println("Authenticate: " + from.getOwner().getName() + " is logged in");
			proceed(from, amount, to);
		} else {
			System.err.println(from.getOwner().getName() + " is not logged in!");
		}
	}
	
	
	@requires("$proc")
	@ensures({"from.getOwner().isAuthorized()?$proc:true"})
	@AdviceName("authorize")
	void around(Account from): call(void Account.transfer(double, Account)) && target(from) {
		if (from.getOwner().isLoggedIn()) {
			System.out.println("Authorize: " + from.getOwner().getName() + " is authorized to access this method");
			proceed(from);
		} else {
			System.err.println(from.getOwner().getName() + " is not authorized to access this method!");
		}
	}
}