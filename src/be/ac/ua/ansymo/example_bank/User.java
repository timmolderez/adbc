package be.ac.ua.ansymo.example_bank;

import be.ac.ua.ansymo.adbc.annotations.ensures;
import be.ac.ua.ansymo.adbc.annotations.invariant;
import be.ac.ua.ansymo.adbc.annotations.requires;


/**
 * A bank user
 */
@invariant("$this.name!=null")
public class User {
	private String name;
	
	@requires("name!=null")
	@ensures("$this.name.equals(name)")
	public User(String name) {
		this.name = name;
	}
	
	@ensures("$result!=null")
	public String getName() {
		return name;
	}
}
