require 'enginery/version'

class << Enginery
  def usage
<<USAGE

Enginery version #{EngineryVersion::FULL}

Generator:

  enginery g[enerate][:p] Foo  - generates a new application in ./Foo/ folder
  enginery g[enerate][:p]      - generates a new application in current folder

  enginery g[enerate]:c[ontroller] Foo     - generates Foo controller
  enginery g[enerate]:c[ontroller] Foo Bar - generates Foo and Bar controllers

  enginery g[enerate]:r[oute] Foo bar      - generates Foo#bar action 
  enginery g[enerate]:r[oute] Foo bar baz  - generates Foo#bar and Foo#baz actions

  enginery g[enerate]:s[pec] Foo bar - generates a spec for Foo#bar action

  enginery g[enerate]:v[iew] Foo bar - generates view file for Foo#bar action

  enginery g[enerate]:m[odel] Foo     - generates Foo model
  enginery g[enerate]:m[odel] Foo Bar - generates Foo and Bar models

Generator Options:
  
  ORM:
    enginery g o[rm]:[ActiveRecord|ar] - generated project will use ActiveRecord ORM
    enginery g o[rm]:[DataMapper|dm]   - generated project will use DataMapper ORM
    enginery g o[rm]:[Sequel|sq]       - generated project will use Sequel ORM

  Engine:
    enginery g[enerate] e[ngine]:Slim              - generated project will use Slim engine
    enginery g[enerate]:c[ontroller] e[ngine]:Haml - generated controller will use Haml engine

    Note: engine name should be provided in full and are case sensitive

#{ migrator_usage }

USAGE
  end

  def migrator_usage
<<USAGE
Migrator:
  
  enginery m[igration] migration-name m[odel]:Foo c[olumn]:bar     - create bar column of string type
  enginery m[igration] migration-name m[odel]:Foo c[olumn]:bar:baz - create bar column of baz type

  enginery m[igration] migration-name m[odel]:Foo u[pdate_]c[olumn]:bar:baz - set bar column type to baz

  enginery m[igration] migration-name m[odel]:Foo r[ename_]c[olumn]:bar:baz - rename bar column to baz
  
  enginery m[igration]:l[ist]    - list all available migrations

  enginery m[igrate]:up|down N   - perform up|down migration with serial number N

  enginery m[igrate]:up|down N M - perform up|down migrations with serial numbers N and M

  enginery m[igrate]:up|down N-M - perform up|down migrations with serial numbers from N to M
 
USAGE
  end
end
