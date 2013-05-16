class Index < E
  include IndexHelpers if defined?(IndexHelpers)
  # controller-wide setups
  map '/'
  
end
