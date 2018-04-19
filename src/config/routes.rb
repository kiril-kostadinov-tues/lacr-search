Rails.application.routes.draw do

  devise_scope :user do
    get "/sign_in" => "devise/sessions#new" # custom path to login/sign_in
    get 'login', to: 'devise/sessions#new'
    get "/sign_up" => "devise/registrations#new", as: "new_user_registration" # custom path to sign_up/registration
  end

  devise_for :users

  # Home page routes
  root to: 'home#index'
  get '/about', to: 'home#about'
  get '/contact', to: 'home#contact'

  # Documents page routes
  get 'doc', to: "documents#index"
  get 'doc/new', to: "documents#new"
  post 'doc/new', to: "documents#upload"
  post 'doc/:id/edit', to: "documents#edit", as: "doc_edit"
  post 'doc/edit', to: "documents#edit_finished"
  get 'doc/show', to: "documents#show"
  get 'doc/page', to: "documents#page"
  get 'doc/page-s', to: "documents#page_simplified"
  get 'doc/selected', to: "documents#selected"
  delete 'doc/destroy', to: "documents#destroy"

  # Download
  get 'download/archive', to: "download#archive"

  # Ajax
  post 'ajax/download', to: "download#index"
  get 'ajax/doc/selected/pdf', to: "download#selected_gen_pdf"
  post 'ajax/doc/destroy', to: "documents#destroy"
  get 'ajax/doc/list', to: "documents#list"
  get 'ajax/search/autocomplete', to: 'search#autocomplete'
  get 'ajax/search/autocomplete-entry', to: 'search#autocomplete_entry'
  get 'ajax/search/chart/worddate', to: 'search#chart_wordstart_date'
  get 'ajax/search/chart/data', to: 'search#chart_data'

  # Search routes
  get 'search', to: 'search#search'
  get 'query', to: 'xquery#index'
  post 'query', to: 'xquery#show'
  post 'post', to: 'comment#post'
  
  # Semantic search routes
  get 'semantic_search', to: 'semantic_search#index'
  post 'semantic_search_page', to: 'semantic_search#show'
  post 'semantic_search_word', to: 'search#search_annotation'
  get 'word_semantic', to: 'semantic_search#show_word_semantic'
  post 'word_semantic', to: 'semantic_search#word_semantic'
  get 'page_semantic', to: 'semantic_search#show_page_semantic'
  patch 'page_semantic', to: 'semantic_search#page_semantic_patched'
  post 'semantic_search/create', to: 'semantic_search#create'
  post 'create_offence', to: 'semantic_search#create_offence'
  post 'create_verdict', to: 'semantic_search#create_verdict'
  post 'create_sentence', to: 'semantic_search#create_sentence'
  post 'create_category', to: 'semantic_search#create_category'
  delete 'annotation_delete', to: 'semantic_search#delete_annotation'
end


#<%= form_for @documents, url: {action: "page_semantic_patched"} do |f| %>
 # Offence <%= f.select_tag(:offence, options_for_select([['Arsony', 'arsony'],['Huinq', 'huinq']]), {include_blank: true}) %>
 # Verdict <%= f.select_tag(:verdict, options_for_select([['Sentenced', 'sentenced'],['Huinq', 'huinq']]), {include_blank: true}) %>
 # Sentence <%= f.select_tag(:sentence, options_for_select([['Death', 'death'],['Huinq', 'huinq']]), {include_blank: true}) %>
 # <%= f.hidden_field_tag :page, @page%>
 # <%= f.hidden_field_tag :volume, @volume %>
#  <%= f.submit "Submit" %>s
#<% end %>