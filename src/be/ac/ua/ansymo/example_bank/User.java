package be.ac.ua.ansymo.example_bank;

import be.ac.ua.ansymo.adbc.annotations.ensures;


/**
 * A bank user
 */
public class User {
	private String name;
	
	public User(String name) {
		this.name = name;
	}
	
	@ensures("$result!=null")
	public String getName() {
		return name;
	}
}
