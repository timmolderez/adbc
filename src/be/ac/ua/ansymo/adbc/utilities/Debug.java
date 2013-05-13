package be.ac.ua.ansymo.adbc.utilities;

/**
 * Debugging helper methods..
 * @author Tim Molderez
 */
public class Debug {
	static public void print(Object[] arr) {
		for (Object obj : arr) {
			System.out.println(obj.toString());
		}
	}
}
