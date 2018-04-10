class SemanticSearchController < ApplicationController
	def index
	end

	def show
		#begin
	      # create session
	   #   session = BaseXClient::Session.new(ENV['BASEX_URL'], 1984, "readOnly", ENV['BASEX_READONLY'])
	      # session.create_readOnly()
	      # Open DB or create if does not exist
	    #  session.execute("open xmldb")
	      # Get user query
	    #  input = "//ns:#{params[:term]}"
	     # XQuery declaration of the namespace
	    #  declarate_ns = 'declare namespace ns = "http://www.tei-c.org/ns/1.0";'
	      # Create instance the BaseX Client in Query Mode
	   #   query = session.query(declarate_ns + input)
	      # Store the result
	    #  @query_result = query.execute.gsub(/<[^>]*>/, "")
	      # Count the number of results
	    #  @number_of_results = session.query("#{declarate_ns}count(#{input})").execute.to_i
	      # close session
	    #  query.close()
	    #  session.close
	   # rescue Exception => e
	   #   logger.error(e)
	    #  @query_result = "--- Sorry, this query cannot be executed ---\n"+e.to_s
	   # end
	   @offenceentries = []
	   @offenceoutput = Search.where(:offence => params[:term]).to_a
	   @offenceoutput.each do |entry|
	   	@offenceentries.push(entry.content)
	   end
	end

	def create

	end

	def show_word
		begin
	      create session
	      session = BaseXClient::Session.new(ENV['BASEX_URL'], 1984, "readOnly", ENV['BASEX_READONLY'])
	      session.create_readOnly()
	      #Open DB or create if does not exist
	      session.execute("open xmldb")
	       #Get user query
	      input = "//ns:#{params[:term]}"
	      #XQuery declaration of the namespace
	      declarate_ns = 'declare namespace ns = "http://www.tei-c.org/ns/1.0";'
	      # Create instance the BaseX Client in Query Mode
	      query = session.query(declarate_ns + input)
	      # Store the result
	      @query_result = query.execute.gsub(/<[^>]*>/, "")
	      # Count the number of results
	      @number_of_results = session.query("#{declarate_ns}count(#{input})").execute.to_i
	      # close session
	      query.close()
	      session.close
	    rescue Exception => e
	      logger.error(e)
	      @query_result = "--- Sorry, this query cannot be executed ---\n"+e.to_s
	    end
	end

	def show_word_semantic
		if params.has_key?(:p) and params.has_key?(:v) \
	      and params[:v].to_i > 0 and  params[:v].to_i < 1000000 \
	      and params[:p].to_i > 0 and  params[:p].to_i < 1000000
	      # Store the volume and page from the input
	      @volume, @page,@id = params[:v].to_i, params[:p].to_i, params[:id].to_i
	      if params[:searchID]
	        @searchID = 'searchID'
	      end
	  else
	  	redirect_to doc_path
	    end
		if params[:maikatiputkata]
			@da = params[:maikatiputkata]
		else
			flash[:notice] = "Something's wrong!"
		end
		
	end

	def word_semantic
		if params.has_key?(:p) and params.has_key?(:v) \
	      and params[:v].to_i > 0 and  params[:v].to_i < 1000000 \
	      and params[:p].to_i > 0 and  params[:p].to_i < 1000000
	      # Store the volume and page from the input
	      @volume, @page,@id,@da = params[:v].to_i, params[:p].to_i, params[:id].to_i, params[:word]
	      if params[:searchID]
	        @searchID = 'searchID'
	      end
	  else
	  	redirect_to doc_path
	    end
	    @xmlcontent = Search.where(:volume => @volume).where(:page => @page).where(:id => @id).to_a[0]
	    @xmlcontent.content.gsub!(@da,"<#{params[:person]}>#{@da}</#{params[:person]}>")
	    @xmlcontent.save
	end

	def word_semantic_patched
		
	end



	def show_page_semantic
		if params.has_key?(:p) and params.has_key?(:v) \
	      and params[:v].to_i > 0 and  params[:v].to_i < 1000000 \
	      and params[:p].to_i > 0 and  params[:p].to_i < 1000000
	      # Store the volume and page from the input
	      @volume, @page,@id = params[:v].to_i, params[:p].to_i, params[:id].to_i
	      if params[:searchID]
	        @searchID = 'searchID'
	      end
	  else
	  	redirect_to doc_path
	    end
	    
	    @documents = Search.where(:volume => @volume).where(:page => @page).where(:id => @id).to_a[0]


	end

	def page_semantic_patched

		@documents = Search.where(:volume => params[:volume]).where(:page => params[:page]).where(:id => params[:id]).to_a[0]
			@documents.verdict = params[:verdict]
			@documents.sentence = params[:sentence]
			@documents.offence = params[:offence]
			@documents.save
		redirect_to doc_path
	end
end
