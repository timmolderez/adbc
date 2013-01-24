package be.ac.ua.ansymo.example_bank;

import be.ac.ua.ansymo.adbc.annotations.ensures;
import be.ac.ua.ansymo.adbc.annotations.requires;


public class SavingsAccount extends Account {
	public SavingsAccount(double amount, User owner) {
		super(amount, owner);
	}
	
	@requires({
		"amount>0",
		"to!=null",
		"$this.getOwner()==to.getOwner()"})
	@ensures({
		"$this.getAmount()==$old($this.getAmount())-amount",
		"to.getAmount()==$old(to.getAmount())+amount"
		})
	public void transfer(double amount, Account to) {
		withdraw(amount);
		to.deposit(amount);
		
	}
}
