
Spec.new "Index#index" do
  map Index[:index]

  get
  is(last_response).ok?
end
