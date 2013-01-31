package be.ac.ua.ansymo.example_bank;

import be.ac.ua.ansymo.adbc.annotations.ensures;
import be.ac.ua.ansymo.adbc.annotations.invariant;
import be.ac.ua.ansymo.adbc.annotations.requires;

@invariant("true")
public class Account {
	double amount;
	User owner;
	public int bla = 5;
	
	public Account(double amount, User owner) {
		this.amount = amount;
		this.owner = owner;
	}
	
	@requires("amount>0")
	@ensures("$this.getAmount()==$old($this.getAmount())+amount")
	public void deposit(double amount) {
		this.amount+=amount;
	}
	
	@requires("amount>0")
	@ensures("$this.getAmount()==$old($this.getAmount())-amount")
	public void withdraw(double amount) {
		this.amount-=amount;
	}
	
	@requires({
		"amount>0",
		"to!=null"})
	@ensures({
		"$this.getAmount()==$old($this.getAmount())-amount",
		"to.getAmount()==$old(to.getAmount())+amount"
		})
	public void transfer(double amount, Account to) {
		withdraw(amount);
		to.deposit(amount);
		
	}
	
	public double getAmount() {
		return amount;
	}
	
	@requires("true")
	@ensures("$result!=null")
	public User getOwner() {
		return owner;
	}
}