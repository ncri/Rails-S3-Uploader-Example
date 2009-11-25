ActionController::Routing::Routes.draw do |map|

  map.root :controller => 'uploads', :action => 'new'

  map.connect ':controller/:action/:id'
  map.connect ':controller/:action/:id.:format'
end
