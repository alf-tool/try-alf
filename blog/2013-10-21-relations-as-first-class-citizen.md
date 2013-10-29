<div class="blog-post-date">2013, October 21</div>

# Relations as First-Class Citizen - A Paradigm Shift for Software/Database Interoperability

I'm happy to announce that Alf v0.15.0 has just been released and with it,
this web site! I've been hacking on Alf during my free time for about two
years now; I think it was time to share it in a slightly more official way
than as an (almost invisible) [open-source
project](https://github.com/alf-tool) on github.

Alf is a modern, powerful implementation of relational algebra. It brings
relational algebra where you don't necessarily expect it: in shell, in
scripting and for building complex software. Alf has an rich set of features.
Among them, it allows you to:

* Query .json, .csv, .yaml files and convert from one format to the other with
  ease,
* Query SQL databases with a sounder and more powerful query language than SQL
  itself,
* Export structured and so-called "semi-structured" query results in various
  exchange formats,
* Query multiple data sources as if they were one and only one database,
* Create database *viewpoints* (mostly read-only viewpoints for now), to
  provide your users with a true database interface while keeping them away
  from data they may not have access to,
* Define your own high-level, domain-specific, relational operators.

Alf is very young and not all of the advanced features are stable and/or
documented. I plan to spend some time in the next weeks and months to work on
them, so stay tuned. In the mean time, you can play with Alf on this website,
install [Alf 0.15.0](https://rubygems.org/gems/alf) and start playing with it
on your own datasets and databases. I'll come with advanced material on this
blog as soon as possible, I promise.

The rest of this post explains the context of this work and why it exists in
the first place, in the form of a (very accessible) scientific paper (this
writing style is also a test, let me know what you think). The [section
immediately following](#intro) provides a short overview of the proposed
approach, explaining the title of this blog post. We then detail Alf's
proposal, first with an [short example](#practice) illustrating the advantages
compared to existing solutions, then with [a more theoretical
presentation](#theory). You can read those two sections in the order you want.
[Alf's limitations and features to come](#ongoing-work) are then briefly
discussed, before [concluding](#conclusion) with a slightly broader
perspective.

<h2 id="intro">Yet another database connectivity library?</h2>

We already have [ARel](https://github.com/rails/arel),
[Sequel](http://sequel.rubyforge.org/),
[SQLAlchemy](http://www.sqlalchemy.org/), [Korma](http://www.sqlkorma.com/),
[jOOQ](http://www.jooq.org/) and probably hundreds of similar projects for
connecting to databases from code. Do we really need one more?

Well, Alf is a database connectivity library but it is first and foremost
about a proposal for a new _kind_ of software/database interoperability, or a
paradigm shift if you want. This paradigm is called **Relations as First-Class
Citizen** and it makes Alf different from existing approaches. The difference
lies in the kind of data abstraction exposed to the software developer:

* Call-level interfaces (e.g. JDBC) expose SQL query strings and database
  cursors (e.g. `java.sql.ResultSet`),
* Higher-level SQL libraries, such as [ARel](https://github.com/rails/arel),
  [Sequel](http://sequel.rubyforge.org/), and [jOOQ](http://www.jooq.org/)
  expose SQL queries as well. However, they abstract them behind abstract
  syntax trees (AST), and algebra-inspired manipulation operators.
* Object-Relational Mappers (ORMs) expose classes and objects together with
  the SQL/AST interface they generally rely on (e.g. the symbiosis between
  [ARel](https://github.com/rails/arel) and
  [ActiveRecord](http://guides.rubyonrails.org/active_record_querying.html)),
* [Alf](https://github.com/alf-tool/alf) and
  [Axiom](https://github.com/dkubb/axiom) expose _Relations_ (i.e. [sets of
  tuples](/doc/relational-basics)) and relational algebra. For those
  interested, I'll discuss the differences between Alf and Axiom later in this
  blog post. In the mean time and unless stated otherwise, what is said about
  Alf applies to Axiom too.

In this blog post, I'm going to compare Alf with the second category above,
i.e. high-level SQL-driven libraries. Not because the **Relations as
First-Class Citizen** paradigm cannot be compared to, say, Object-Relational
Mapping but because, at first glance, Alf shares a lot more with those
libraries than with ORMs. First things first thus, let start looking at those
similitudes and (sometimes subtle) differences. We start with a motivating
example in the next section before moving to more theoretical arguments in the one immediately following.

<h2 id="practice">Motivating example</h2>

<i>This might appear rude or offensive, but I need to start by complaining
about existing approaches and libraries (why would I work on Alf in the first
place otherwise?). [Sequel](http://sequel.rubyforge.org/) is used in this blog
post but the situation is similar with all the libraries I mentioned
previously. I've chosen Sequel because I commonly use and actually</i> love
<i>it. No offense to be taken therefore even if I claim, in essence, that
things could be improved.</i>

My main complaint is that, despite providing [closure under
operations](http://en.wikipedia.org/wiki/Closure_(mathematics)), existing
libraries fail at providing a truly composable way of tackling data
requirements. To understand why, let me take a concrete software engineering
example on (a slighly modified version of) the [suppliers and parts
examplar](http://en.wikipedia.org/wiki/Suppliers_and_Parts_database). We'll
use the following [`suppliers`](/?src=c3VwcGxpZXJz) and
[`cities`](/?src=Y2l0aWVz) relations:

```
suppliers:                                     cities:
+------+-------+---------+--------+            +----------+----------+
| :sid | :name | :status | :city  |            | :city    | :country |
+------+-------+---------+--------+            +----------+----------+
| S1   | Smith |      20 | London |            | London   | England  |
| S2   | Jones |      10 | Paris  |            | Paris    | France   |
| S3   | Blake |      30 | Paris  |            | Athens   | Greece   |
| S4   | Clark |      20 | London |            | Brussels | Belgium  |
| S5   | Adams |      30 | Athens |            +----------+----------+
+------+-------+---------+--------+
```

Let suppose that the suppliers themselves are the software users and that the
following requirements must be met by the particular inferface showing the
list of suppliers to the current user:

1. A supplier may only see information about the suppliers located in the same
   city than himself.
2. The supplier's `status` is sensitive and should not be displayed.
3. The country name must be displayed together with the supplier's city

In terms of the query to be built, those requirements involve a restriction
(`same city as`), a selection (`no status`) and a join (`with country name`).
Suppose you are supplier `S3`, the list of suppliers you see [looks like
this](/?src=cmVxdWVzdGVyID0gIlMzIgpqb2luKGFsbGJ1dChtYXRjaGluZyhzdXBwbGllcnMsIHByb2plY3QocmVzdHJpY3Qoc3VwcGxpZXJzLCBzaWQ6IHJlcXVlc3RlciksIFs6Y2l0eV0pKSwgWzpzdGF0dXNdKSwgY2l0aWVzKQ):

```
+------+-------+-------+----------+
| :sid | :name | :city | :country |
+------+-------+-------+----------+
| S2   | Jones | Paris | France   |
| S3   | Blake | Paris | France   |
+------+-------+-------+----------+
```

<h3 id="struggling">Struggling with reuse and separation of concerns</h3>

Writting a monolithic query is rather straightforward. Using [Sequel](http://sequel.rubyforge.org/) for instance:

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
algebraic equivalence does not hold in `Sequel`, preventing us from using the
design above:

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

* SQL has not been designed with composition and separation of concerns in
  mind,
* Avoiding strong coupling between subqueries tends to be very difficult in
  practice,
* Coupling hurts separation of concerns and software design.

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
course, but possible. I won't provide the details in this blog post, let me
know if a dedicated one is welcome. For now, let see how our new paradigm
helps.

### Relation Algebra at the rescue...

Libraries like Sequel and Arel offer closure under operations, meaning that
you can chain operator invocations (e.g. `operand.select(...).where(...).where(...)`).
Subtly enough, that does not make them exposing an algebra, because SQL is not
itself a pure relational algebra (see later) and these libraries do espouse
SQL in a rather faithful way.

In contrast, the **Relations as First-Class Citizen** paradigm aims at
providing an interface that is _designed for_ composition and reuse. To
achieve this, Alf takes some distance from SQL and exposes a true relational
algebra instead, inspired from <a
href="http://en.wikipedia.org/wiki/D_(data_language_specification)"
target="_blank"><b>Tutorial D</b></a>. This makes a real difference, even if
subtle. To convince yourself, I invite you to use Alf's try console to check
that the example below works as expected. As shown, the three requirements of
our case study can be incorporated incrementally thanks to the true
composition mechanism offered by an algebra. Commenting a line amounts at
ignoring the corresponding requirement:

```try
requester_city = 'Paris'
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
optimization and smart SQL compilation. I invite you to check the `Optimizer`
and `Query plan` tabs of the console on both queries. The generated SQL query
is the same in both cases. Alf tries very hard to keep generated SQL as simple
as possible, in the hope to avoid ugly query plans in the SQL DBMS itself:

```sql
SELECT t1.sid AS sid, t1.name AS name, t1.city AS city, t2.country AS country
FROM suppliers AS t1
INNER JOIN cities AS t2 ON (t1.city = t2.city)
```

### ... plus extra

What if `cities` (that does not actually exists in the original suppliers and
parts examplar), come from somewhere else? A .csv file, another database or
whatever datasource?

```try
requester_city = 'Paris'
solution = suppliers

# 1) and 2) above, but inline
solution = allbut(restrict(solution, city: requester_city), [:status])

# Might be Relation.load('cities.csv'); we use a literal for execution on try-alf.org
third_party_cities = Relation([
  {city: 'London', country: 'England'},
  {city: 'Paris',  country: 'France'}
])
solution = join(solution, third_party_cities)
```

The example above shows that, in addition to the advantages previously cited,
the composition mechanism of relational algebra, unlike SQL queries, makes few
assumptions about where the operands come from, by very nature. In a sense,
the **Relations as First-class citizen** can be seen as a purely functional
kind of programming where immutable values are relations and functions are
relational operators. This kind of comparison is not new. It was already
suggested several years ago in Ben Moseley's famous <a
href="http://shaffner.us/cs/papers/tarpit.pdf">Out of the Tar Pit</a> essay.
Alf contributes an example of the general framework outlined there.

<h2 id="theory">More about the paradigm and its motivation</h2>

Moving from SQL to a relational algebra is one of the changes underlying the
**Relations as First-Class Citizen** paradigm, but it is not the only one and
maybe not the most important (?). The following subsections detail the
paradigm further and provides motivations and theoretical arguments.

### From Relational Calculus (SQL) to Relational Algebra

In my opinion, the fact that SQL is used daily by software developers is the
result of an historical mistake, or a misfortune at least. Indeed, SQL has
been invented in the database community at a time where it was envisioned that
_end users_ would query relational databases. This is more than 40 years ago.
At that time, the nature of software, software engineering, requirements
engineering and human-software interactions were not understood as they are
today.

With this envisioned reality in mind, SQL has been chosen nearer to (tuple)
relational calculus than to relational algebra (for the sake of accuracy, it
is a strange mix of both; yet another obscure historical reasons explain
this). For a good understanding of the discussion here, it is important to
understand the difference in nature between a calculus and an algebra:

* In a calculus, what you describe is the problem to solve, not how to solve
  it. Hence the `from ... select ... such that ...` declarative kind of
  question you actually ask to an SQL DBMS:

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

As shown by the example above, a calculus is more declarative than an algebra.
In other words, the latter looks more like an algorithm. This explains why
SQL, probably the most idiomatic _end-user_ query language ever, has been
designed as a calculus. As an end-user, when you (manually) query a database
you generally know the problem at hand. Therefore, you welcome a declarative
language since it allows you to express that problem while leaving to the
underlying engine the job of finding the solution instead of having to
describe the algorithm to compute it. _This_ is what SQL offers to its users.

Now, I suppose it is not too risky to claim that, today, a large majority of
interactions with databases is done by software components, possibly on behalf
of their end users, and generally in accordance to specific requirements. The
_actual_ users of (relational) databases are not end-users after all, but
software components and, indirectly, their developers.

Yet, developping software is of a very different nature than querying
databases. As a software engineer, you generally don't have one single problem
at hand. Instead, you have a set of problems called _requirements_ and you
find a design that allows meeting them all (cfr. [the previous
section](#practice) for an example). One of the most effective strategies
available in the software engineer toolset is _divide and conquer_. A modular
design, for example, helps achieving a good separation of concerns with
respect to those requirements while ensuring that the software behaves as
expected when all modules are put together.

While the declarative style of programming of SQL is very nice for solving
very specific and well isolated sub-problems in your requirements & design
space, it is of almost no aid for putting the architectural pieces together.
Yet, putting the pieces together is something software engineers do every
single day. And so is writing algorithms. Exposing a relational algebra
therefore appears more natural when it comes to software development, and when
it comes to _manipulating_ data vs. _querying_ database. To be fair, libraries
such as [ARel](https://github.com/rails/arel),
[Sequel](http://sequel.rubyforge.org/), and [jOOQ](http://www.jooq.org/)
already show the way: they provide an API that is closer to relational
algebra than relational calculus. [Alf](https://github.com/alf-tool/alf) and
[Axiom](https://github.com/dkubb/axiom) simply go further this path by
abstracting from SQL and choosing a sound algebra known as <a
href="http://en.wikipedia.org/wiki/D_(data_language_specification)"
target="_blank"><b>Tutorial D</b></a> as a better inspiration than SQL towards
the same objective.

The **Relations as First-Class Citizen** paradigm makes all of this more sound
in my opinion, because putting _relations_ together is much easier than
putting _SQL queries_ together (cfr. [the _join_ example](#struggling) in the
previous section). The semantics of "putting together" is more straightforward
in the former case, that's all. An algebra *is* about providing operators for
putting operands together, a calculus simply is not. Approaches such as Alf's
is no less expressive, quite the contrary. For instance, expressing a SQL
`WHERE NOT EXISTS` is kind of [a
nightmare](http://stackoverflow.com/questions/7152424/rails-3-arel-for-not-exists)
with existing approaches, and almost impossible to do in a modular way due to
the coupling between the main query and the sub-query:

```
# Show suppliers that supply no part at all (Sequel)
DB[:suppliers___s].where(~DB[:supplies___sp].where(Sequel.qualify(:sp, :sid) => (Sequel.qualify(:s, :sid))).exists)
```

It is dead simple in Alf:

```try
# Show suppliers that supply no part at all (Alf)
not_matching(suppliers, supplies)
```

Now, relational calculus and relation algebra are known to be equivalent in
expressive power. This is what allows Alf to compile queries in the second
form above to something similar to the former one and to send it to an
underlying SQL DBMS. The feature is limited by the ability to reconcile the
Ruby and SQL type systems though, something I will discuss in the next
section.

### From SQL's to Host's Type System

There is another very important change I have not discussed so far regarding
the proposed **Relations as First-Class Citizen** paradigm. In essence, it is
a challenging proposal (from an implementation point of view at least): _why
not abstracting from SQL completely?_

_Aside: this section applies to Alf but, as far as I know, not to Axiom._

Indeed, almost all approaches (even ORMs) do actually espouse SQL in a very
rigid way. An obvious example is that the developer is almost never allowed to
express filtering conditions or to perform computations that are not supported
by SQL in the first place. It is unfortunate, because SQL's type system is
poor (no user-defined types, for instance) and old. How about providing a
query interface that actually espouse the host type system, i.e. the one of
the host programming language (here, Ruby)?

Want to express a filtering condition involving a ruby regular expression? No
problem:

```try
# Get suppliers whose name contains a 'J' or a 'B'
restrict(suppliers, ->(t){ t.name =~ /J|B/ })
```

Want to compute an array-valued attribute (or even use you own user-defined
data type/class)? No problem:

```try
# Get suppliers and the letters of their name in uppercase
extend(suppliers, letters: ->(t){ t.name.upcase.chars.to_a })
```

Want to group tuples as sub-relations? There is even an operator for that:

```try
# Get suppliers grouped by city
group(suppliers, [:sid, :name, :status], :suppliers)
```

This might look at simply providing a consistent interface for working with
relations. Absolutely, that's the point. You can mix everything in a natural
way, that is by composing queries in the idiomatic way. In the example below,
Alf still compiles the 'Paris' restriction to SQL while it computes the
'letters' extension itself (see the optimizer and query plans), even if the
extension comes _before_ the restriction:

```try
rel = extend(suppliers, letters: ->(t){ t.name.upcase.chars.to_a })
rel = restrict(rel, city: 'Paris')
```

Now think about it. This amounts at _abstracting_ from SQL and letting
developers think in terms of their _usual_ type system. While powerful, this
is very challenging (but fun) in practice for the implementer (i.e. for me)
and comes at a cost (for you). There are drawbacks and limitations that you
must be aware of (I'll come back to this point in the next section). That
means that you can't abstract from reality entirely after all, as often with
abstractions, but yet more than with existing approaches in my opinion.

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

Database viewpoints are currently read-only in Alf. I intentionnally left the
question of database updates aside in this blog post. Alf comes only with a
very experimental interface for updates (cfr. [Alf in Ruby](#/doc/alf-in-ruby))
but a lot of work is still needed in this area.

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

I'd like to thank Sergio Castro, Erwin Smout, Enrico Sartorello, David
Livingstone, Magnus Holm and Louis Lambeau for their feedback and comments on
earlier versions of this blog post.
