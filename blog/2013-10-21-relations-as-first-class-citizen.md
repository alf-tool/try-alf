<div class="blog-post-date">2013, October 21</div>

# Relations as First-Class Citizen - A Paradigm Shift for Software/Database Collaboration

I'm happy to announce that Alf v0.15.0 has just been released and with it,
this web site! I've been hacking on Alf on my free time for about two years
now; I think it was time to share it in a slightly more official way that an
(almost invisible) [open-source project](https://github.com/alf-tool) on
github.

Alf is a modern, powerful implementation of relational algebra. It brings
relational algebra where you don't necessarily expect it: in shell, in
scripting and for building complex software (in ruby so far). Alf has an
impressive list of features. Among them, it allows you to:

* Query .json, .csv, .yaml files and convert from one format to the other with
  ease,
* Query SQL databases with a sounder and more powerful query language than SQL
  itself,
* Export structured and so-called "semi-structured" query results in various
  exchange formats,
* Query multiple data sources as if they were one and only one database,
* Create database *viewpoints*, to provide your users with a true database
  interface while keeping them away from data they may not have access to,
* Define your own high-level, domain-specific, relational operators.

Alf is very young and not all of the advanced features are stable and/or
documented. I plan to spend some time in the next weeks and months to work on
them, so stay tuned. In the mean time, you can play with Alf on this website,
install [alf 0.15.0](https://rubygems.org/gems/alf) and start playing with it
on your own datasets and databases. I'll come with advanced material on this
blog as soon as possible, I promise. The rest of this post explains the
context of this work and why it exists in the first place.

## Yet another database connectivity library?

We already have [ARel](https://github.com/rails/arel),
[Sequel](http://sequel.rubyforge.org/),
[SQLAlchemy](http://www.sqlalchemy.org/), [Korma](http://www.sqlkorma.com/),
[jOOQ](http://www.jooq.org/) and probably hundreds of similar projects for
connecting to databases from code. Do we really need one more?

Well, Alf is a database connectivity library but it is first and foremost a
proposal for a new _kind_ of database connectivity, or a paradigm shift if you
want. This new paradigm is called **Relations as First-Class Citizen** and it
makes Alf very different from the projects aforementionned. The difference
lies in the kind of abstraction that the library exposes to the software
developer: SQL queries for the former, _Relations_ for the latter.

In almost all [but](http://www.datomic.com/)
[a](https://github.com/dkubb/axiom)
[few](http://dbappbuilder.sourceforge.net/Rel.php) database connectivity
layers, the developer is indeed exposed to SQL queries. The SQL query is often
abstracted behind a higher-level API for manipulating its abstract syntax tree
(AST). But even in this case, the exposed abstraction is a SQL query. The fact
is that a SQL query, even when abstracted behind an AST, tends to be a very
poor abstraction for developing software. Before substantiating this claim,
let us illustrate the difference between our approach and those with a simple
example.

### Example

In Java/JDBC for instance, queries are simple SQL strings. No abstraction at
all; we all know the cost in terms of maintenance, security, etc.


```java
String location = ... // from user input;
String qry  = "SELECT name, city FROM suppliers WHERE";
       qry += "city='" + location + "'";
```

Common high-level approaches are slightly more abstract. While more secure and
flexible, they still expose a SQL query abstraction. In the following example,
using [ARel](https://github.com/rails/arel):

```
location = ... # from user input
qry  = Arel::Table.new(:suppliers)
qry  = qry.project(qry[:name], qry[:city])
qry  = qry.where(qry[:city].eq(location))
```

The **Relations as First-Class Citizen** paradigm changes this by abstracting
from SQL and exposing true relations instead. In the example below,
`suppliers` is a relation, `restrict` is a relational operator and its
invocation returns another relation:

```
location = ... # from user input
restrict(suppliers, :city => location)
```

Alf does just that: it expose relations as first class citizen to the software
developer. It has two main modes, with and without lazy evaluation, the
details of which are out of scope of this general blog post (see [Alf in
Ruby](/doc/alf-in-ruby))

### What does really change?

This paradigm shift may not seem very significant at first glance, but
abstracting from SQL is an important change in practice:

* First, when exposing SQL as an software abstraction, you also expose its
  type system. SQL's type system is poor and old. Developers need rich type
  systems. In our new paradigm, the type system is the one of the host
  language (Ruby in our case), with all its power:

    ```try
    # Get suppliers whose name matches a Ruby regular expression.
    restrict(suppliers, ->(t){ t.name =~ /J|B/ })
    ```

  While powerful, this is very challenging in practice and comes at a cost: as
  any abstraction, it leaks and you must be aware of the drawbacks and
  limitations. We'll come back to this point at the end of this blog post.

* SQL is a calculus. In contrast, the **Relations as First-Class Citizen**
  paradigm relies on the availibility of an algebra. We claim that an algebra
  exposes better abstractions for software engineering, as the rest of this
  post will explain.

## SQL, Relational Calculus vs. Relational Algebra

SQL has been invented to allow _human beings_ to query relational databases.
In fact, SQL is nearest to (tuple) relational calculus than to relational
algebra (for the sake of accuracy, it is a strange mix of both). To understand
our proposal, it is important to understand the difference in nature between a
calculus and an algebra:

* In a calculus, what you describe is the problem to solve, not how to solve
  it. Hence the `from ... select ... such that ...` declarative kind of
  question you actually ask to a SQL DBMS:

      ```
      # Get the cities where at least one supplier is located, provided
      # at least one part is located there too.
      SELECT DISTINCT city FROM suppliers AS s
      WHERE EXISTS (
        SELECT city FROM parts AS p
        WHERE s.city = p.city
      )
      ```

* In contrast, with an algebra you manipulate symbols, that denote _values_,
  through a predefined set of operators. You use those operators to _build_
  or _reach_ the solution to your problem:

      ```try
      # Get the cities where at least one supplier is located, provided
      # at least one part is located there too.
      cities_from_suppliers = project(suppliers, [:city])
      cities_from_parts     = project(parts, [:city])
      intersect(cities_from_suppliers, cities_from_parts)
      ```

Relational calculus and relation algebra are known to be equivalent in
expressiveness. This is what allows Alf to compile the second form above to
something similar to the former one and to send it to an underlying SQL DBMS
(a feature obviously limited by the ability to reconcilie the respective type
systems, see later). However, as shown by the example above, a calculus is
more declarative than an algebra. In other words, the latter looks more like
an algorithm. Despite this, we do claim that relational algebra exposes better
abstractions for developing software when it comes to querying databases or,
more generally, to manipulating data. Why is that so?

## Querying databases vs. developing software

When you (manually) query a database (either a SQL, a NoSQL one or whatever)
you generally know the problem at hand. Therefore, you welcome a declarative
language since it allows you to express that problem while leaving to the
underlying engine the job of finding the solution instead of having to
describe the algorithm to compute it. This is what SQL offers to you. This is
what [logic
programming](https://bernardopires.com/2013/10/try-logic-programming-a-gentle-introduction-to-prolog/)
and [constraint
programming](http://en.wikipedia.org/wiki/Constraint_programming) offer too.

Developping software is of a very different nature. As a software developer,
you generally don't have one single problem at hand. Instead, you have a set
of problems called _requirements_ and you find a design that allows meeting
them all. One of the most effective strategy for this is _divide and conquer_.
A modular design, for example, helps achieving a good separation of concerns
with respect to those requirements while ensuring that the software behaves as
expected when all modules are put together.

The declarative styles of programming cited above are very nice for solving
very specific and well isolated sub-problems of your requirements space
(especially logic and constraint programming as they also allow searching
through an entire solution space). In contrast, they are of almost no aid for
putting the architectural pieces together. Yet, putting the pieces together is
something software engineers do every single day.

When it comes to manipulating data, putting _relations_ together is much
easier than putting _SQL queries_ together, because the semantics of "putting
together" is more straightfoward in the former case. This leads us back to the
calculus vs. algebra distinction. An algebra *is* about providing operators
for putting operands togethers, a calculus simply is not. The next section
illustrates this on our running example.

## The struggle of SQL with abstraction and reuse

In the SQL query below observe the coupling induced by `s.city = p.city`
between the `FROM` clause and the `EXISTS` subquery:

```
SELECT DISTINCT city
FROM suppliers AS s
WHERE EXISTS (
  SELECT city FROM parts AS p
  WHERE s.city = p.city
)
```

This kind of coupling explains why SQL-driven database connectivity librairies
stop shining as soon a join is involved, not even talking about more complex
queries. Indeed, even if possible, it is not idiomatic to build SQL queries
from various parts constructed in a really independent way. Common
connectivity libraries actually do a very hard job at trying to maintain the
illusion that it is possible, but they generally fail at doing so. To convince
yourself, suppose the following additional requirement:

```
# Join the set of cities obtained previously with `cities` so as to also display their country.
```

The most immediate way of writing such query seriously breaks separation of
concerns because you'll need to know a lot about how the previous building
block has been written. In particular, observe how the `SELECT` and `FROM`
clauses have to change:

```
SELECT DISTINCT s.city, c.country 
FROM suppliers AS s JOIN cities AS c ON s.city = c.city
WHERE EXISTS (
  SELECT city FROM parts AS p
  WHERE s.city = p.city
)
```

There is actually a few ways to write such query without breaking abstraction
levels. For example, obverse how `q1` is preserved in the query below:

```
WITH q1 AS (
       SELECT DISTINCT city
       FROM suppliers AS s
       WHERE EXISTS (
         SELECT city FROM parts AS p
         WHERE s.city = p.city
       )
     ),
     q2 AS (SELECT city, country FROM cities)
SELECT * FROM q1 NATURAL JOIN q2
```

Ironically, building such a query with common connectivity libraries is not
idiomatic, when even possible. Worse, it is so hard to maintain this kind of
beasts that simply breaking your software design tends to be a better choice.
Last, but not least, if `cities` comes from another database, a .csv file or
whatever data source, the game simply ends.

## Relations provide a true abstraction mechanism

The same is not true with relational algebra, more specifically with the
**Relations as First-Class Citizen** paradigm (RFCC). For instance, the
building block of our original solution above may be kept unchanged yet
further joined:

```try
# Get the cities where at least one supplier is located, provided
# at least one part is located there too.
cities_from_suppliers = project(suppliers, [:city])
cities_from_parts     = project(parts, [:city])
building_block = intersect(cities_from_suppliers, cities_from_parts)

# Join the set of cities obtained previously with `cities` so as to also
# display their country.
join(building_block, cities)
```

What if cities come from somewhere else? A .csv file, another database or
whatever datasource?

```try
# Get the cities... (unchanged, just inlined)
building_block = intersect(project(suppliers, [:city]), project(parts, [:city]))

# Join them...
# Might be Relation.load('cities.csv'); we use a literal for execution on try-alf.org
cities = Relation([
  {city: 'London', country: 'England'},
  {city: 'Paris',  country: 'France'}
])
join(building_block, cities)

```

Relational algebra and RFCC can be seen as a purely functional kind of
programming where immutable values are relations and functions are relational
operators. This kind of comparison is not new. It was already suggested
several years ago in Ben Moseley's famous <a
href="http://shaffner.us/cs/papers/tarpit.pdf">Out of the Tar Pit</a> essay.
Alf contributes an example of the general framework outlined there.

## Limitations and future work

The approach outlined here opens an avenue for further optimization,
experimentation and research. We close this blog post with an overview of our
own future work in this area. We also draw the reader attention on Alf's
current limitations.

### Towards high-level, domain-specific relational operators

The closure property of relational algebra opens the ability to define new
relational operators in a very simple way, provided they are shortcuts over
longer expressions. Alf comes with such a facility, as illustrated below:

```try
# It relation `test` contains at least one tuple return `then_relation`,
# otherwise return `else_relation`
def ite(test, then_relation, else_relation)
  union(
    matching(then_relation, project(test, [])),
    not_matching(else_relation, project(test, [])))
end

# It there are at least one Red part, show suppliers in London, otherwise
# show suppliers in Paris
ite(
  restrict(parts, color: 'Red'),
  restrict(suppliers, city: 'London'),
  restrict(suppliers, city: 'Paris'))
```

While the example above is contrived, our experience suggests that the `ite`
relational operator proves very useful in practice when dealing with complex
data visibility and privacy requirements. Interresting enough, you can check
that the compilation involves only one SQL query sent to the underlying DBMS,
resulting in important performance improvements compared to other approaches
relying on an `if/then/else` statement in the host language.

Similarly, even when involving complex data types and collections, most query
plans involve a _constant_ number of SQL queries, avoiding the 'N+1 queries'
trap [infamously known with Object-Relational
Mappers](http://www.revision-zero.org/orm-haters-do-get-it):

```try
join(suppliers, group(join(supplies, parts), [:sid], :supplied_parts, allbut: true))
```

Alf already has a few high-level operators such as [matching](/doc/matching)
or [page](/doc/page). The next release should include a few others currently
evaluated on case studies: `ite`, `image`, `abstract`, `quota`, etc.

### Database viewpoints

The closure property of relational algebra also opens the ability to define
composable database viewpoints. Viewpoints provide a very effective
abstraction mechanism for implementing complex security/privacy requirements,
as well as providing context-aware database interfaces.

Without entering the details here, the following example illustrates the
approach by hacking on Ruby's `super` mechanism. Suppose we want to provide a
database viewpoint on suppliers and parts located in London:

```try
# Start of the viewpoint
def suppliers
  restrict(super, city: 'London')
end
def parts
  restrict(super, city: 'London')
end
def supplies
  # restore foreign keys given the previous restrictions
  matching(matching(super, parts), suppliers)
end
# End of the viewpoint

# Query as usual. This is entirely transparent.
# Check it yourself, supplier S2 no longer exists in this viewpoint.
restrict(supplies, sid: 'S1')
```

### Reconciling heterogeneous type systems

As already suggested, abstracting from SQL is challenging. More specifically,
abstracting from SQL *and* guaranteeing soundness and efficiency at the same
time are conflicting requirements. Alf has a smart compiler that delegates to
underlying engines what can be delegated, but the explicit use of the host
type system is a showstopper during compilation. To better understand this,
consider the following query:

```try
restrict(
  extend(suppliers, uppercased: ->(t){ t.name.upcase }),
  city: 'Paris', uppercased: 'JONES')
```

If you take a look at the query plan, you'll observe that the `restrict`
invocation is only partially compiled to SQL. The `uppercased` attribute is
computed by Alf in Ruby and cannot be translated back to the SQL engine. This
has serious performance implications, of course. As of current Alf version,
this is in true as soon as you use a ruby block (e.g. `->(t){ ... }`).

All other approaches we are aware of either have a similar problem or forbid
such queries in the first place (and are hence less expressive). This calls
for further symbiosis and interoperability between heterogeneous type systems
(SQL and Ruby in the present case).

### What about updates?

We intentionnally left the question of database updates aside in this blog
post. Alf comes only with a very experimental interface for updates but a lot
of work is still needed in this area. Our general aim is to come with a well
chosen subset of relational operators supporting updates.

## Conclusion

Arrived here? Kudos. Stay tuned, we'll provide more material soon. In the mean
time, enjoy Alf. Any question or contribution (of any kind) can be adressed by
sending an email to Bernard Lambeau (see the [About](/about/) page).
