adbc - Design by Contract for AspectJ
=====================================

![adbc logo](https://raw.github.com/timmolderez/adbc/master/doc/adbc.png)

Adbc is a small and lightweight library that adds support for [Design by Contract](http://en.wikipedia.org/wiki/Design_by_contract) to the [AspectJ](http://eclipse.org/aspectj/) programming language.

- Just add the library to your AspectJ project and contracts will be enforced at runtime. Whenever a contract is broken, an exception is thrown which also indicates who is to blame.
- Contract enforcement is guided by the [Liskov](http://en.wikipedia.org/wiki/Liskov_substitution_principle) and [advice substitution principle](http://dl.acm.org/citation.cfm?id=2162015). If an advice's contracts do not interfere with the contracts of the methods being advised, that advice satisfies the advice substitution principle. In this case, no extra effort is needed to preserve modular reasoning. In case an advice does break the principle, modular reasoning is restored by explicitly mentioning that advice's name in an `@advisedBy` annotation at each method it advises.
- Contracts are written as Javascript expressions within Java annotations. (The library uses the JSR 223 API, so you can easily configure which scripting engine is used to evaluate the contracts.)

## Requirements

- Java 6 (or later)
- AspectJ (tested on versions 1.6.12 and 1.7.2)

## Usage

When using Eclipse+AJDT, just add `adbc.jar` to your project's InPath and you can start writing contracts (using the annotations in `be.ac.ua.ansymo.adbc.annotations`). Contract enforcement is automatically enabled, and can be disabled if needed via the `AdbcConfig` class. 
For more information, be sure to have a look at adbc's [documentation](https://raw.github.com/timmolderez/adbc/master/doc/README.pdf).