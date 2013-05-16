package be.ac.ua.ansymo.example_bank.aspects;

/**
 * Defines the precedence order of all aspects in the application
 * @author Tim
 */
public aspect Precedence {
	declare precedence: TransactionLogger, Security;
}