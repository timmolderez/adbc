adbc - Design by Contract for AspectJ
=====================================

![adbc logo](https://raw.github.com/timmolderez/adbc/master/doc/adbc.png)

Adbc is a small and lightweight library that adds support for [design by contract](http://en.wikipedia.org/wiki/Design_by_contract) to the [AspectJ](http://eclipse.org/aspectj/) programming language.  
<sub>Released under the [BSD 3-Clause license](http://opensource.org/licenses/BSD-3-Clause).</sub>

- Add the library to your AspectJ project and contracts will automatically be enforced at runtime. Whenever a contract is broken, an exception is thrown which also indicates who is to blame.
- Contracts are written as JavaScript expressions within Java annotations. (The library uses the JSR 223 API, so you can easily configure which scripting engine is used to evaluate the contracts.)
- Contract enforcement is guided by [behavioural subtyping](http://en.wikipedia.org/wiki/Liskov_substitution_principle) and the [advice substitution principle](http://dl.acm.org/citation.cfm?id=2162015), which allows for modular reasoning. That is, you can reason about a method call just by looking at the contracts of the method body in the static type, even in the presence of advice. In a nutshell, to ensure that an advice complies with the advice substitution principle, its contracts should not interfere with those of the methods being advised. If an advice cannot avoid breaking the principle, modular reasoning can be0 restored by explicitly mentioning that advice's name in an `@advisedBy` annotation at each method it advises. (See the [documentation](https://raw.github.com/timmolderez/adbc/master/doc/README.pdf) for more information.)

### [Download adbc](http://timmolderez.be/builds/adbc/)


## Requirements

- Java 6 (or later)
- AspectJ (tested on versions 1.6.12 and 1.7.2)

## Usage

When using Eclipse+AJDT, just add `adbc.jar` to your project's InPath and you can start writing contracts (using the annotations in `be.ac.ua.ansymo.adbc.annotations`). Contract enforcement is automatically enabled, and can be disabled if needed via the `AdbcConfig` class. 
For more information, be sure to have a look at adbc's [documentation](https://raw.github.com/timmolderez/adbc/master/doc/README.pdf).
