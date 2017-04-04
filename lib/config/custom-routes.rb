# -*- encoding : utf-8 -*-
# Here you can override or add to the pages in the core website

Rails.application.routes.draw do
  # Additional help pages
  match '/help/help_out' => 'help#help_out', :as => 'help_help_out'
  match '/help/right_to_know' => 'help#right_to_know', :as => 'help_right_to_know'

  # redirect the blog page to blog.asktheeu.org
  match '/blog/' => redirect('http://blog.asktheeu.org/')
end
