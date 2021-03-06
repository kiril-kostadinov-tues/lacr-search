require 'will_paginate/array'

class SearchController < ApplicationController

  def chart_wordstart_date
    if params[:term]
      term = params[:term]
      parts = term.split(", ")

      data = []

      parts.each do |part|
        # Strip white-space at the beginning and the end.
        query = part.gsub(/[^0-9a-z]/i, '')

        docs = Search.search(query, {
             fields: ['content'], # Autocomplete for words in content
             match: :word_start, # Use word_start method
             highlight: {tag: "" ,
               fields: {content: {fragment_size: 0}}}, # Highlight only single word
            #  limit: 10, # Limit the number of results
             load: false, # Do not query the database (PostgreSQL)
             misspellings: {
               edit_distance: 1, # Limit misspelled distance to 1
               below: 4, # Do not use misspellings if there are more than 4 results
               transpositions: false # Show more accurate results
             }
           })

        data += docs.results
      end
      

      # Do not use autocomplete for phrases; The search method is not appropriate
      # if query.length < 20 and !query.include? ' '
         render json: data.pluck(:highlighted_content, :date, :entry)
           .delete_if{|content, date, entry| not content or not date or not entry}
           .collect{
             |content, date, entry| [
               content.gsub(/[^0-9a-z]/i, '').downcase,
               '',
               "<span style=\"margin:5px;\"><b>ID:</b> #{entry}</span><br><span style=\"margin:5px;\"><b>Date:</b> #{date}</span>",
               date,
               date
               ]
             }
       return # Finish here to avoid render {}
      # end
    end
    render json: {} # Render this if one of the 2 if statements fails
  end

  def chart_data
    if params[:term]
      term = params[:term]
      parts = term.split(", ")

      data = []

      parts.each do |part|
        query = part.strip.gsub(/[^0-9a-z]/i, '')

        docs = Search.search(query, {
          fields: ['content'], # Autocomplete for words in content
          match: :word_start, # Use word_start method
          highlight: {tag: "" ,
          fields: {content: {fragment_size: 0}}}, # Highlight only single word
          #  limit: 10, # Limit the number of results
          load: false, # Do not query the database (PostgreSQL)
          misspellings: {
            edit_distance: 1, # Limit misspelled distance to 1
            below: 4, # Do not use misspellings if there are more than 4 results
            transpositions: false # Show more accurate results
          }
        })

        data += docs.results
      end

      results = data.pluck(:date, :entry)

      results.each do |r|
        if !r[0].nil?
          r[0] = r[0].slice!(0..3)
        end
      end

      final_data = results.sort_by{|r| r[0]}.group_by {|year, record| year}.map {|year, match| [year, match.count]}
      render json: (final_data)
      return      
    end
    render json: {}
  end

  # Simple Search
  def search
    redirect_to doc_path if Search.count.zero? # Fix search on empty DB

    # Use strong params
    permited = simple_search_params

    # Parse Spelling variants and Results per page
    get_search_tools_params(permited)

    # Send the query to Elasticsearch
    if permited[:sm].to_i == 5
      @searchMethod = 5  # Regexp

        @documents = Search.search '*',
            page: permited[:page], per_page: @results_per_page, # Pagination
            where: {content:{"regexp":".*" + @query + ".*"}}.merge(get_adv_search_params(permited)),
            match: get_serch_method(permited), # Parse search method parameter
            order: get_order_by(permited), # Parse order_by parameter
            load: false # Do not retrieve data from PostgreSQL

        @images = []
    
        @documents.each do |document|
          image = PageImage.find_by_volume_and_page(document.volume, document.page)
          if image
            @images << image.image.normal.url.split('.')[0...-1].join + '.jpeg'
          end
        end

    else
      @queries = [@query]

      # Search fo the original query entered by the user
      @documents = Search.search @query,
          misspellings: {edit_distance: @misspellings,transpositions: false},
          where: get_adv_search_params(permited), # Parse adv search parameters
          match: get_serch_method(permited), # Parse search method parameter
          order: get_order_by(permited), # Parse order_by parameter
          highlight: {tag: "<mark>"}, # Set html tag for highlight
          fields: ['content'], # Search for the query only within content
          suggest: true, # Enable suggestions
          load: false # Do not retrieve data from PostgreSQL
    
      if @query_lat != ""
        # Add Latin to the list of successful translations
        @queries << @query_lat
        # Perform a search for the Latin translation
        @documents_lat = Search.search @query_lat,
          misspellings: {edit_distance: @misspellings,transpositions: false},
          where: get_adv_search_params(permited), # Parse adv search parameters
          match: get_serch_method(permited), # Parse search method parameter
          order: get_order_by(permited), # Parse order_by parameter
          highlight: {tag: "<mark>"}, # Set html tag for highlight
          fields: ['content'], # Search for the query only within content
          load: false # Do not retrieve data from PostgreSQL
      end

      if @query_sc != ""
        # Add Middle Scots to the list of successful translations
        @queries << @query_sc
        # Perform a search for the Middle Scots translation
        @documents_sc = Search.search @query_sc,
          misspellings: {edit_distance: @misspellings,transpositions: false},
          where: get_adv_search_params(permited), # Parse adv search parameters
          match: get_serch_method(permited), # Parse search method parameter
          order: get_order_by(permited), # Parse order_by parameter
          highlight: {tag: "<mark>"}, # Set html tag for highlight
          fields: ['content'], # Search for the query only within content
          load: false # Do not retrieve data from PostgreSQL
      end

      if @query_d != ""
        # Add Dutch to the list of successful translations
        @queries << @query_d
        # Perform a search for the Dutch translation
        @documents_d = Search.search @query_d,
          misspellings: {edit_distance: @misspellings,transpositions: false},
          where: get_adv_search_params(permited), # Parse adv search parameters
          match: get_serch_method(permited), # Parse search method parameter
          order: get_order_by(permited), # Parse order_by parameter
          highlight: {tag: "<mark>"}, # Set html tag for highlight
          fields: ['content'], # Search for the query only within content
          load: false # Do not retrieve data from PostgreSQL
      end

      @images = []
    
      @total_length = @documents.total_count
      @took = @documents.took
      @documents_arr = @documents.results

      unless @documents_lat.nil?
        @total_length += @documents_lat.total_count
        @took += @documents_lat.took
        @documents_arr += @documents_lat.results
      end

      unless @documents_sc.nil?
        @total_length += @documents_sc.total_count
        @took += @documents_sc.took
        @documents_arr += @documents_sc.results
      end

      unless @documents_d.nil?
        @total_length += @documents_d.total_count
        @took += @documents_d.took
        @documents_arr += @documents_d.results
      end

      # Sort by volume, page - ascending
      if @orderBy == 0
        @documents_arr.sort_by! {|d| [d.volume, d.page]}
      # Sort by volume, page - descending
      elsif @orderBy == 2
        @documents_arr.sort_by! {|d| [d.volume, d.page]}.reverse!
      # Sort by date
      elsif @orderBy == 3
        @documents_arr.sort_by! {|d| [d.date]}
      end

      @page = permited[:page]
      if @page.nil?
        @page = 1
      end

      # Create custom pagination for the array
      @documents_pagination = WillPaginate::Collection.create(@page.to_i, @results_per_page, @documents_arr.length) do |pager|
        pager.replace @documents_arr
      end

      start = (@page.to_i - 1) * @results_per_page

      # Truncate the array to only contain the elements on the current page
      @documents_page = @documents_arr[start, @results_per_page]

      # Collect all results images for the gallery
      @documents_arr.each do |document|
        image = PageImage.find_by_volume_and_page(document.volume, document.page)
        if image
          @images << [image.image.normal.url.split('.')[0...-1].join + '.jpeg', document.volume, document.page]
        end
      end

      @image_set = Set.new(@images)
    end
  end

  # Perform semantic search
  def search_annotation

    # Use strong params
    permited = simple_search_params

    # Parse Spelling variants and Results per page
    get_search_tools_params(permited)
    search_query = ""
    terms = params[:term]
    term_values = params[:term_value]
    search_array = []
    if terms.eql?([""])
      # Search for all if the term fields are empty
      search_query = '*'
    else
      # Construct each term and add it to the query
      terms.each_with_index do |term, i|
        unless term.empty?
          if term_values[i].empty?
            term_values[i] = " "
          end
            search_array << "<#{term}>#{term_values[i]}</#{term}>"
        end
      end
      search_query = search_array.join(" ")
    end


    # Perform a search for the constructed query
    @documents = Search.search search_query,
          order: get_order_by(permited), # Parse order_by parameter
          #highlight: {tag: "<mark>"}, # Set html tag for highlight
          fields: ['content'], # Search for the query only within content
          load: false # Do not retrieve data from PostgreSQL
    @documents = @documents.results

    # Check if user wants to filter by verdict
    unless params[:verdict].empty?
      @documents = @documents.select do |document|
        unless document.verdict.nil?
          document.verdict.include?(params[:verdict].to_i)
        end
      end
    end

    # Check if user wants to filter by offence
    unless params[:offence].empty?
      @documents = @documents.select do |document|
        unless document.offence.nil?
          document.offence.include?(params[:offence].to_i)
        end
      end
    end

    # Check if user wants to filter by sentence
    unless params[:sentence].empty?
      @documents = @documents.select do |document|
        unless document.sentence.nil?
          document.sentence.include?(params[:sentence].to_i)
        end
      end
    end

  end


  def autocomplete
    # Strip white-space at the beginning and the end.
    query = params[:term].strip.gsub(/[^0-9a-z]/i, '')

    # Do not use autocomplete for phrases; The search method is not appropriate
    if query.length < 20 and !query.include? ' '
       render json: (Search.search(query, {
         fields: ['content'], # Autocomplete for words in content
         match: :word_start, # Use word_start method
         highlight: {tag: "" ,
           fields: {content: {fragment_size: 0}}}, # Highlight only single word
         limit: 10, # Limit the number of results
         load: false, # Do not query the database (PostgreSQL)
         misspellings: {
           edit_distance: 1, # Limit misspelled distance to 1
           below: 4, # Do not use misspellings if there are more than 4 results
           transpositions: false # Show more accurate results
         }
       }
      # Get only the highlighted word
      # Remove non-aplhanumeric characters, such as white-space
      # Return only unique words
      ).map {|x| x.highlighted_content.gsub(/[^0-9a-z]/i, '')}).uniq
     else
       render json: {}
    end
   end

  def autocomplete_entry
     render json: Search.search(params[:term].strip, {
       fields: ['entry'],
       match: :word_start,
       limit: 5,
       load: false,
       misspellings: false
     }).map(&:entry)
   end

   # Define functions for simplicity
  private

  def simple_search_params
    params.permit(:q, :r, :m, :o, :sm, :entry, :date_from, :date_to, :v, :pg, :pr, :lang, :page)
  end

  def get_search_tools_params(permited)
    # Get text from the user input. In case of empty search -> use '*'
    @query = permited[:q].present? ? permited[:q].strip : '*'
    
    @query_lat = ""
    # Check for translation of whole phrase in Latin
    tr = Translation.find_by language: "latin", translated: @query

    if tr.nil?
      if @query.include? " "
        query_lat = permited[:q].present? ? permited[:q].strip : '*'
        parts = @query.split(" ")
        # Search for word-by-word translations in Latin
        parts.each do |part|
          tr = Translation.find_by language: "latin", translated: part

          unless tr.nil?
            query_lat.gsub!(part, tr.word)
          end
        end
        unless query_lat.eql? @query
          # Avoid duplicating queries if word in Latin is the same as in English
          @query_lat = query_lat
        end
      end
    else
      unless tr.word.eql? @query
        @query_lat = tr.word
      end
    end

    @query_sc = ""
    # Check for translation of whole phrase in Middle Scots
    tr = Translation.find_by language: "scots", translated: @query

    if tr.nil?
      if @query.include? " "
        query_sc = permited[:q].present? ? permited[:q].strip : '*'
        parts = @query.split(" ")
        parts.each do |part|
          # Search for word-by-word translations in Middle Scots
          tr = Translation.find_by language: "scots", translated: part

          unless tr.nil?
            query_sc.gsub!(part, tr.word)
          end
        end
        unless query_sc.eql? @query
          # Avoid duplicating queries if word in Middle Scots is the same as in English
          @query_sc = query_sc
        end
      end
    else
      unless tr.word.eql? @query
        @query_sc = tr.word
      end
    end

    @query_d = ""
    # Check for translation of whole phrase in Dutch
    tr = Translation.find_by language: "dutch", translated: @query

    if tr.nil?
      if @query.include? " "
        query_d = permited[:q].present? ? permited[:q].strip : '*'
        parts = @query.split(" ")
        parts.each do |part|
          # Search for word-by-word translations in Dutch
          tr = Translation.find_by language: "dutch", translated: part

          unless tr.nil?
            query_d.gsub!(part, tr.word)
          end
        end
        unless query_d.eql? @query
          # Avoid duplicating queries if word in Dutch is the same as in English
          @query_d = query_d
        end
      end
    else
      unless tr.word.eql? @query
        @query_d = tr.word
      end
    end

    # Get the number of results per page; Default value -> 5
    @results_per_page = 5
    results_per_page = permited[:r].to_i
    if results_per_page >= 5 and results_per_page <= 50
      @results_per_page = results_per_page
    end

    # Get the misspelling distance; Default value -> 2
    @misspellings = 2
    misspellings = permited[:m].to_i
    if misspellings >= 0 and misspellings <= 5
      @misspellings = misspellings
    end
  end

  def get_order_by(permited)
    # Get the orderBy mode
    # 0 -> Most relevant first
    # 1 -> Volume/Page in ascending order
    # 2 -> Volume/Page in descending order
    # 3 -> Chronological orther
    @orderBy = permited[:o].to_i
    order_by = {}
    if @orderBy == 0
      order_by['volume'] = :asc # volume ascending order
      order_by['page'] = :asc # page ascending order
    elsif @orderBy == 1
      order_by['_score'] = :desc # most relevant first - default
    elsif @orderBy == 2
      order_by['volume'] = :desc # volume descending order
      order_by['page'] = :desc # page descending order
    elsif @orderBy == 3
      order_by['date'] = :asc
    end
    return order_by
  end

  def get_serch_method(permited)
    # Get the search method value
    # 0 -> Analyzed (Default)
    # 1 -> Phrase
    # 2 -> word_start
    # 3 -> word_middle
    # 4 -> word_end
    @searchMethod = permited[:sm].to_i

    case @searchMethod
      when 1 then search_method = :phrase
      when 2 then search_method = :word_start
      when 3 then search_method = :word_middle
      when 4 then search_method = :word_end
      else search_method = :analyzed
    end

    return search_method
  end

  def get_adv_search_params(permited)
    where_query = {}
    if permited[:entry] # Filter by Entry ID
      where_query['entry'] = Regexp.new "#{permited[:entry]}.*"
    end
    date_range = {}
    if permited[:date_from] # Filter by lower date bound
      begin
        date_str = permited[:date_from] # Get date
        # Fix incorrect date format
        case date_str.split('-').length
        when 3 then date_range[:gte] =  date_str.to_date
        when 2 then date_range[:gte] = "#{date_str}-1".to_date
        when 1 then date_range[:gte] = "#{date_str}-1-1".to_date
        else flash[:notice] = "Incorrect \"Date from\" format"
        end
      rescue
        flash[:notice] = "Incorrect \"Date from\" format"
      end
    end
    if permited[:date_to] # Filter by upper date bound
      begin
        date_str = permited[:date_to] # Get date
        # Fix incorrect date format
        case date_str.split('-').length
        when 3 then date_range[:lte] = date_str.to_date
        when 2 then date_range[:lte] = "#{date_str}-28".to_date
        when 1 then date_range[:lte] = "#{date_str}-12-31".to_date
        else  flash[:notice] = "Incorrect \"Date to\" format"
        end
      rescue
        flash[:notice] = "Incorrect \"Date to\" format"
      end
    end
    # Append to where_query
    where_query['date'] = date_range

    if permited[:lang] # Filter by language
      where_query['lang'] = permited[:lang]
    end
    if permited[:v] # Filter by voume
      where_query['volume'] = permited[:v].split(/,| /).map { |s| s.to_i }
    end
    if permited[:pg] # Filter by page
      where_query['page'] = permited[:pg].split(/,| /).map { |s| s.to_i }
    end
    if permited[:pr] # Filter by paragraph
      where_query['paragraph'] = permited[:pr].split(/,| /).map { |s| s.to_i }
    end
    return where_query
  end
end
