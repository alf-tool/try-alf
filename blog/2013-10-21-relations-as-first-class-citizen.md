<div class="blog-post-date">2013, October 21</div>

# Relations as First-Class Citizen - A Paradigm Shift for Software/Database Interoperability

I'm happy to announce that Alf v0.15.0 has just been released and with it,
this web site! I've been hacking on Alf during my free time for about two
years now; I think it was time to share it in a slightly more official way
than as an (almost invisible) [open-source
project](https://github.com/alf-tool) on github.

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
blog as soon as possible, I promise.

The rest of this post explains the context of this work and why it exists in
the first place. The [section immediately following](#intro) provides a short
overview of the proposed approach, explaining the title of this blog post. We
then detail Alf's proposal, first from [a theoretical perspective](#theory)
then with an [short example](#practice) illustrating the advantages. You can
read those two sections in the order you want. [Alf's limitations and features
to come](#ongoing-work) are then discussed, before [conclusion](#conclusion).

<h2 id="intro">Yet another database connectivity library?</h2>

We already have [ARel](https://github.com/rails/arel),
[Sequel](http://sequel.rubyforge.org/),
[SQLAlchemy](http://www.sqlalchemy.org/), [Korma](http://www.sqlkorma.com/),
[jOOQ](http://www.jooq.org/) and probably hundreds of similar projects for
connecting to databases from code. Do we really need one more?

Well, Alf is a database connectivity library but it is first and foremost a
proposal for a new _kind_ of database connectivity, or a paradigm shift if you
want. This new paradigm is called **Relations as First-Class Citizen** and it
makes Alf very different from the projects mentioned above. The difference
lies in the kind of abstraction that the library exposes to the software
developer: SQL queries with these libraries, _Relations_ with Alf.

In almost all database connectivity layers, the developer is indeed exposed to
SQL queries. The SQL query is often abstracted behind a higher-level API for
manipulating its abstract syntax tree (AST). But even in this case, the
exposed abstraction is an SQL query. The fact is that a SQL query, even when
abstracted behind an AST, tends to be a very poor abstraction for developing
software. Before substantiating this claim, let us illustrate the difference
between our approach and a few others with a simple example.

### Example

In Java/JDBC for instance, queries are simple SQL strings. No abstraction at
all; we all know the cost in terms of maintenance, security (quotes in
`location` should be escaped below, for instance), etc.


```java
String location = ... // from user input;
String qry  = "SELECT name, city FROM suppliers WHERE";
       qry += "city='" + location + "'";
```

Common high-level approaches are slightly more abstract. While more secure and
flexible, they still expose a SQL query abstraction. In the following example,
using [Ruby/Arel](https://github.com/rails/arel):

```
location  = ... # from user input
suppliers = Arel::Table.new(:suppliers)
qry = suppliers
    .project(suppliers[:name], suppliers[:city])
    .where(suppliers[:city].eq(location))
qry.to_sql
# => SELECT suppliers.name, suppliers.city FROM suppliers  WHERE suppliers.city = ...
```

The **Relations as First-Class Citizen** paradigm changes this by abstracting
from SQL and exposing true relations instead. In the example below,
`suppliers` is a relation, `restrict` is a relational operator and its
invocation returns another relation; `project` is another operator taking the
former relation as first argument; it returns another relation, and so on:

```
location = ... # from user input
project(restrict(suppliers, :city => location), [:name, :city])
```

Alf does just that: it exposes relations as first class citizen to the
software developer. It currently supports two main modes, with and without
lazy evaluation, and two styles, a functional one (shown here) and an
Object-Oriented one. The details are out of scope for this blog post, but can
be found in the '[Alf in Ruby](/doc/alf-in-ruby)' documentation page.

<h2 id="theory">What does really change, and why? &mdash; A theoretical aside</h2>

This paradigm shift may not seem very significant at first glance, that is, it
may look like a simple syntactic issue. However, abstracting from SQL is an
important change in practice for at least two reasons:

* First, when exposing SQL as a software abstraction, you also expose its
  type system. SQL's type system is poor and old. Developers need rich type
  systems. In our new paradigm, the type system is the one of the host
  language (Ruby in our case), with all its power:

    ```try
    # Get suppliers whose name matches a Ruby regular expression
    restrict(suppliers, ->(t){ t.name =~ /J|B/ })
    ```

    ```try
    # Get each supplier together with the parts located in same city
    extend(suppliers, parts: ->(t){ restrict(parts, city: t.city) })
    ```

  While powerful, this is very challenging in practice for the implementer
  (i.e. for me) and comes at a cost (for you). There are drawbacks and
  limitations that you must be aware of. We'll come back to this point at the
  end of this blog post.

* SQL is a calculus. In contrast, the **Relations as First-Class Citizen**
  paradigm relies on the availibility of an algebra. We claim that an algebra
  exposes better abstractions for software engineering. The next subsections
  substantiate this claim from a theoretical point of view; an detailed
  example immediately follows.

### What: from Relational Calculus to Relational Algebra

SQL has been invented to allow _human beings_ to query relational databases.
In fact, SQL is nearer to (tuple) relational calculus than to relational
algebra (for the sake of accuracy, it is a strange mix of both). To understand
our proposal, it is important to understand the difference in nature between a
calculus and an algebra:

* In a calculus, what you describe is the problem to solve, not how to solve
  it. Hence the `from ... select ... such that ...` declarative kind of
  question you actually ask to a SQL DBMS:

      ```sql
      -- Get the cities where at least one supplier is located, provided
      -- at least one part is located there too.
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
(a feature obviously limited by the ability to reconcile the respective type
systems, see later). However, as shown by the example above, a calculus is
more declarative than an algebra. In other words, the latter looks more like
an algorithm. Despite this, we do claim that relational algebra exposes better
abstractions for developing software when it comes to querying databases or,
more generally, to manipulating data. Why is that so?

### Why? Querying Databases vs. Developing Software

When you (manually) query a database (either a SQL, a NoSQL one or whatever)
you generally know the problem at hand. Therefore, you welcome a declarative
language since it allows you to express that problem while leaving to the
underlying engine the job of finding the solution instead of having to
describe the algorithm to compute it. This is what SQL offers to you. This is
what
[logic programming](https://bernardopires.com/2013/10/try-logic-programming-a-gentle-introduction-to-prolog/)
and
[constraint programming](http://en.wikipedia.org/wiki/Constraint_programming) offer too.

Developping software is of a very different nature. As a software engineer,
you generally don't have one single problem at hand. Instead, you have a set
of problems called _requirements_ and you find a design that allows meeting
them all. One of the most effective strategies for this is _divide and conquer_.
A modular design, for example, helps achieving a good separation of concerns
with respect to those requirements while ensuring that the software behaves as
expected when all modules are put together.

The declarative styles of programming such as SQL's are very nice for solving
very specific and well isolated sub-problems in your requirements & design
space (logic and constraint programming are even more useful; unlike SQL or
relational algebra, they also allow searching through an entire solution
space, for optimization problems for instance). In contrast, they are of
almost no aid for putting the architectural pieces together. Yet, putting the
pieces together is something software engineers do every single day.

When it comes to manipulating data, putting _relations_ together is much
easier than putting _SQL queries_ together, because the semantics of "putting
together" is more straightfoward in the former case. This leads us back to the
calculus vs. algebra distinction. An algebra *is* about providing operators
for putting operands together, a calculus simply is not. To be fair, as they
are equivalent in terms of expressiveness, it is not SQL itself that must be
blamed. Instead, it is _our use_ of SQL, more specifically the _idiomatic_ way
of using SQL, as exposed by the API of connectivity libraries. Alf proposes a
new approach that is easier and more interoperable. The next two sections
illustrate this on a concrete example.

<h2 id="practice">The Paradigm Change in Action &mdash; An example</h2>

Let us take a concrete software engineering example on the [suppliers and
parts examplar](http://en.wikipedia.org/wiki/Suppliers_and_Parts_database), to
which we add the following `cities` relation:

```try
# Cities, each with a `name` and corresponding `country` name
cities
```

Let suppose that the suppliers themselves are software users and that the
following requirements must be met by the particular inferface showing the
list of suppliers to the current user:

1. A supplier may only see information about the suppliers located in the same
   city than himself.
2. The supplier's `status` is sensitive and should not be displayed.
3. The country name must be displayed together with the supplier's city.

In terms of the query to be built, those requirements involve a restriction
(`same city as`), a selection (`no status`) and a join (`with country name`).
Let compare the two approaches.

### Struggling with separation of concerns and reuse

Writting a monolithic query is rather straightforward, here using
[Sequel](http://sequel.rubyforge.org/):

```
requester_city = ... # from context (authenticated user)

DB[:suppliers]
  .natural_join(:cities)
  .select(:sid, :name, :city, :country)
  .where(:city => requester_city)

# => SELECT sid, name, city, country
#    FROM suppliers NATURAL JOIN cities
#    WHERE (city = ...)
```

In software involving complex requirements, relying on monolithic queries is
unfortunately not always possible and/or desirable (otherwise, creating
database views would simply be enough). Two main reasons explain this:

* The same requirements tend to apply to various and independent software
  features. For instance, the first two requirements above might apply
  _everytime_ a list of suppliers is shown, while the third one might not.
  Complex requirements generally call for a design that achieves both
  separation of concerns and reuse.
* Complex software also involves context-dependent requirements. For instance,
  the first requirement above might be relaxed for administrators (say,
  suppliers with status greater than 30).

This explains why connectivity libraries and their SQL utilities exist in the
first place: because of the need to _build_ queries, often at runtime and
according to some context. There is a desperate need for more support for this
in DBMSs themselves. In the mean time, developers rely on the ability of host
programming languages and third-party libraries.

Back to our example above, what about the following "design"?

```
# Meet 1) and 2) together as a utility method: separation of concerns
def suppliers_in(city)
  DB[:suppliers]
    .select(:sid, :name, :city)
    .where(:city => city)
end

# Meet 3) as a utility method: separation of concerns
def with_country(operand)
  operand.natural_join(:cities)
end

# Meet them all: composition and reuse
requester_city = ... # from context
with_country(suppliers_in(requester_city))
```

Wrong. The original, and correct, SQL query was:

```sql
-- Give the id, name, city and country of every supplier located in city ...
SELECT sid, name, city, country
FROM suppliers NATURAL JOIN cities
WHERE (city = ...)
```

The new one seems smiliar, but is wrong. As shown below, we lost the country
in the process:

```sql
-- Give the id, name and city of every supplier located in city ..., provided
-- the city is known in `cities`
SELECT sid, name, city
FROM suppliers NATURAL JOIN cities
WHERE (city = ...)
```

What happened? In short, `Sequel`'s join does not correspond to a _algebraic_
join of its operands. Instead, its specification looks like "adds a term to
the `SQL` query's `FROM` clause", whose data semantics is far from obvious
(here you can blame `SQL` itself). Observe in particular that the following
algebraic equivalence does not hold, preventing us from designing as above:

```
suppliers
  .natural_join(cities)
  .select(:sid, :name, :city, :country)
<=!=>
suppliers
  .select(:sid, :name, :city)
  .natural_join(cities.select(:city, :country))
```

Join is a striking example of the problem at hand, but others exist that
involve different operators. Let me insist on something: the same is true with
[ARel](https://github.com/rails/arel), [Sequel](http://sequel.rubyforge.org/),
[SQLAlchemy](http://www.sqlalchemy.org/), [Korma](http://www.sqlkorma.com/),
[jOOQ](http://www.jooq.org/) to cite a few. The fact is:

* SQL has not been thought with composition and separation of concerns in mind,
* Using it naively leads to a lot of coupling between various parts of the queries,
* Coupling hurts software design.

To be fair... There _is_ a way to use `SQL` (and, sometimes, those libraries)
so as to avoid the problem described here. It amounts at using `SQL` in a
purely algebraic way. Unfortunately, that way is not idiomatic and leads to
complex SQL queries, that may have bad execution plans (at least in major
open-source DBMSs). In the example at hand, using Sequel's `from_self` in a
systematic way (e.g. on every reusable piece) is safe from the point of view
of composition and reuse:

```
def suppliers_in(city)
  DB[:suppliers]
    .select(:sid, :name, :city)
    .where(:city => city)
    .from_self
end

def with_country(operand)
  operand
    .natural_join(:cities)
    .from_self
end

requester_city = ... # from context
with_country(suppliers_in(requester_city))

# SELECT * FROM (
#   SELECT * FROM (
#     SELECT sid, name, city FROM suppliers
#     WHERE (city = ...)
#   ) AS 't1'
#   NATURAL JOIN cities
# ) AS 't1'
```

The complete recipe for using SQL in such a "safe" way is more complex, of
course. I won't provide the details in this blog post, let me know if a
dedicated one is welcome. For now, let see how our new paradigm helps.

### Relation Algebra at the rescue

The **Relations as First-Class Citizen** paradigm aims at providing an
interface that is _designed for_ composition and reuse. We invite you to use
Alf's try console to check that the example below works as expected. As shown,
the three requirements can be incorporated incrementally thanks to the true
composition mechanism offered by an algebra. Commenting a line amounts at
ignoring the corresponding requirement:

```try
requester_city = 'London'
solution = suppliers

# 1). A supplier may only see information about the suppliers located
# in the same city than himself.
solution = restrict(solution, city: requester_city)

# 2) The supplier's `status` is sensitive and should not be displayed.
solution = allbut(solution, [:status])

# 3). The country name must be displayed together with the supplier's city.
solution = join(solution, cities)
```

To better understand why it works, observe that in Alf, the equivalence
mentionned in the previous section holds. That is, the two following queries
are equivalent, something that you can check by yourself using the console:

```try
project(
  join(suppliers, cities),
  [:sid, :name, :city, :country])
```

and

```try
join(
  project(suppliers, [:sid, :name, :city]),
  project(cities, [:city, :country]))
```

Interestingly enough, this kind of equivalences may be used for query
optimization and smart SQL compilation. We invite the reader to check the
`Optimizer` and `Query plan` tabs of the console on both queries. The
generated SQL queries are the same in both cases; they are kept as simple as
possible, in to hope to avoid ugly physical plans in the SQL DBMS itself.

## ... plus extra

What if cities come from somewhere else? A .csv file, another database or
whatever datasource?

```try
requester_city = 'London'
solution = suppliers

# 1) and 2) above, but inline
solution = allbut(restrict(solution, city: 'London'), [:status])

# Might be Relation.load('cities.csv'); we use a literal for execution on try-alf.org
third_party_cities = Relation([
  {city: 'London', country: 'England'},
  {city: 'Paris',  country: 'France'}
])
solution = join(solution, third_party_cities)
```

The example above shows that, in addition to the advantages previously cited,
the composition mechanism of relational algebra makes few assumptions about
where the operands come from, by nature. **Relations as First-class citizen**
can be seen as a purely functional kind of programming where immutable values
are relations and functions are relational operators. This kind of comparison
is not new. It was already suggested several years ago in Ben Moseley's famous
<a href="http://shaffner.us/cs/papers/tarpit.pdf">Out of the Tar Pit</a>
essay. Alf contributes an example of the general framework outlined there.

<h2 id="ongoing-work">Limitations and ongoing work</h2>

The approach proposed here opens an avenue for further optimization,
experimentation and research. I close this blog post with an overview of my
own ongoing work in this area (which are all subjects I will be talking about
here in the near future). I also draw the reader's attention on Alf's current
limitations.

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
data visibility and privacy requirements. Interesting enough, you can check
that the compilation involves only one SQL query sent to the underlying DBMS,
resulting in important performance improvements compared to other approaches
relying on an `if/then/else` statement in the host language.

Similarly, even when involving complex data types and collections, most query
plans involve a _constant_ number of SQL queries, avoiding the 'N+1 queries'
trap [infamously
known](http://stackoverflow.com/questions/97197/what-is-the-n1-selects-issue)
with Object-Relational Mappers:

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

As already suggested, abstracting from SQL is challenging for the implementer.
More specifically, abstracting from SQL *and* guaranteeing soundness and
efficiency at the same time are conflicting requirements. Alf has a smart
compiler that delegates to underlying engines what can be delegated, but the
explicit use of the host type system is a showstopper during compilation. To
better understand this, consider the following query:

```try
restrict(
  extend(suppliers, uppercased: ->(t){ t.name.upcase }),
  city: 'Paris', uppercased: 'JONES')
```

If you take a look at the query plan, you'll observe that the `restrict`
invocation is only partially compiled to SQL. The `uppercased` attribute is
computed by Alf in Ruby and cannot be translated back to the SQL engine. This
has serious performance implications, of course. As of current Alf version,
this is the case as soon as you use a ruby block (e.g. `->(t){ ... }`).

All other approaches I'm aware of either have a similar problem or forbid
such queries in the first place (and are hence less expressive). This calls
for further symbiosis and interoperability between heterogeneous type systems
(SQL and Ruby in the present case).

### What about updates?

I intentionnally left the question of database updates aside in this blog
post. Alf comes only with a very experimental interface for updates but a lot
of work is still needed in this area. My general aim is to come with a well
chosen subset of relational operators supporting updates.

<h2 id="conclusion">Conclusion</h2>

Arrived here? Kudos. To summarize, I'm convinced that **Relations as
First-class citizen** provides better abstractions than existing approaches
for software-database interoperability, or more generally, for handling the
data manipulation subset of our software engineering requirements. In
particular, I hope to have shown how current database connectivity approaches
hurt separation of concerns and reuse (more generally, software design) and
why favoring pure relational algebra over (idiomatic) SQL helps avoiding the
trap.

I can't close this blog post without putting some fairness back to the
picture. Indeed, I must confess that comparing Alf to libraries such as
[Sequel](http://sequel.rubyforge.org/), or [jOOQ](http://www.jooq.org/) is a
little unfair. This is especially true when you know that Alf itself currently
relies on `Sequel` to generate cross-DBMS SQL code in an easy way. The reason
is that there is a risk here to compare apples and oranges. Shouldn't Alf be
compared to [Object-Relational
Mappers](http://en.wikipedia.org/wiki/Object-relational_mapping)
instead, because it puts a layer of abstraction _above_ SQL?

The short answer is yes. **Relations as First-Class Citizen** (RFCC) is better
compared to **Object-Relational Mapping** (ORM). Both are paradigms that
present data to the software in a particular way: Relations for the former,
Classes/Objects for the latter. As you may already know from [some previous
writings of mine](http://www.revision-zero.org/orm-haters-do-get-it) I'm not a
huge fan of ORM. Without re-opening the war here, they hurt software design in
far too many ways in my opinion. I'm looking for other solutions for a while
and ended-up with this one so far. That said, `Alf` is to **RFCC** what
`Sequel`, `Arel` and the others are to **ORM**, so the comparison actually
applies. Software abstraction boundaries are not clear enough to always avoid
potentially harmful comparisons, I'm affraid.

That also means that our new paradigm goes (and need to go) further that
simply providing an algebraic query language. Stay tuned, I'll provide more
material soon to use Alf in more complex software (such as the famous
viewpoints). In the mean time, any question or contribution (of any kind) can
be adressed by sending an email to Bernard Lambeau (see the [About](/about/)
page; I'm easily found on the Internet too). I'm currently looking for
contributors both in the academics and in the industrial world for discussing,
enhancing, testing and evaluating the approach, don't hesitate to contact me
by email.

## Acknowledgements

I'd like to thank Erwin Smout, Enrico Sartorello, David Livingstone and Sergio
Castro for feedback and comments on earlier versions of this blog post.
