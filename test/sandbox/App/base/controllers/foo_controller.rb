class Foo < E
  include FooHelpers if defined?(FooHelpers)
  # controller-wide setups
  
end
