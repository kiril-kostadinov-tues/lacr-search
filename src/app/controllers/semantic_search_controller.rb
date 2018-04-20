class SemanticSearchController < ApplicationController
	def index
		offences = Offence.all
	    verdicts = Verdict.all
	    sentences = Sentence.all
	    annotations = Annotation.all

	    @offences = [["Any Offence",""]]
	    @verdicts = [["Any Verdict",""]]
	    @sentences = [["Any Sentence",""]]
	    @annotations = [[""]]


	    offences.each do |offence|
	    	@offences << [offence.name,offence.id]
	    end

	    verdicts.each do |verdict|
	    	@verdicts << [verdict.name,verdict.id]
	    end

	    sentences.each do |sentence|
	    	@sentences << [sentence.name,sentence.id]
	    end

	    annotations.each do |annotation|
	    	@annotations << [annotation.name]
	    end
	end

	def show
	   @results = Search.all
	   unless params[:verdict].empty?
	   	@results = @results.where(":ver = ANY (verdict)", ver: params[:verdict])
	   end

	   unless params[:offence].empty?
	   	@results = @results.where(":off = ANY (offence)", off: params[:offence])
	   end

	   unless params[:sentence].empty?
	   	@results = @results.where(":sen = ANY (sentence)", sen: params[:sentence])
	   end
	end

	def create_category
		if Annotation.where(:name => params[:annotation].titleize).empty?
			Annotation.create(:name => params[:annotation].titleize)
			redirect_to :back
			flash[:notice] = "Category Successfully Created"
		else
			redirect_to :back
			flash[:notice] = "Category Already Exists."
		end
	end

	def delete_annotation
		if params.has_key?(:p) and params.has_key?(:v) \
	      and params[:v].to_i > 0 and  params[:v].to_i < 1000000 \
	      and params[:p].to_i > 0 and  params[:p].to_i < 1000000
	      	# Store the volume and page from the input
	    	@volume, @page,@id = params[:v].to_i, params[:p].to_i, params[:id].to_i

	     	@xmlcontent = Search.where(:volume => @volume).where(:page => @page).where(:id => @id).to_a[0]
		    @xmlcontent.content.gsub!("<#{params[:tag]}>#{params[:annotation]}</#{params[:tag]}>", params[:annotation])
		    @xmlcontent.save
			redirect_to :back
			flash[:notice] = "Annotation Deleted"
	  	else
	  		redirect_to doc_path
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
		if params[:word]
			@word = params[:word]
		else
			flash[:notice] = "Something went wrong!"
		end
		@annotations = []
		anno = Annotation.all
		anno.each do |annotation|
			@annotations << annotation.name
		end

		
	end

	def word_semantic
		if params.has_key?(:p) and params.has_key?(:v) \
	      and params[:v].to_i > 0 and  params[:v].to_i < 1000000 \
	      and params[:p].to_i > 0 and  params[:p].to_i < 1000000
	      # Store the volume and page from the input
	      @volume, @page,@id,annotation = params[:v].to_i, params[:p].to_i, params[:id].to_i, params[:word]
	      if params[:searchID]
	        @searchID = 'searchID'
	      end
	  else
	  	redirect_to doc_path
	    end
	    @xmlcontent = Search.where(:volume => @volume).where(:page => @page).where(:id => @id).to_a[0]
	    @xmlcontent.content.gsub!(annotation,"<#{params[:tag]}>#{annotation}</#{params[:tag]}>")
	    @xmlcontent.save
	    redirect_to doc_path
	    flash[:notice] = "Successfully created annotation."
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
	    offences = Offence.all
	    verdicts = Verdict.all
	    sentences = Sentence.all

	    @offences = []
	    @verdicts = []
	    @sentences = []

	    offences.each do |offence|
	    	@offences << [offence.name,offence.id]
	    end

	    verdicts.each do |verdict|
	    	@verdicts << [verdict.name,verdict.id]
	    end

	    sentences.each do |sentence|
	    	@sentences << [sentence.name,sentence.id]
	    end

	end

	def page_semantic_patched

		@documents = Search.where(:volume => params[:volume]).where(:page => params[:page]).where(:id => params[:id]).to_a[0]
			@documents.verdict = params[:verdict]
			@documents.sentence = params[:sentence]
			@documents.offence = params[:offence]
			@documents.save
		redirect_to doc_path
	end

	def create_offence
		if Offence.where(:name => params[:name]).empty?
			Offence.create(name: params[:name])
			redirect_to :back
			flash[:notice] = "Offence successfully created."
		else
			redirect_to :back
			flash[:notice] = "Offence already exists."
		end
	end

	def create_verdict
		if Verdict.where(:name => params[:name]).empty?
			Verdict.create(name: params[:name])
			redirect_to :back
			flash[:notice] = "Verdict successfully created."
		else
			redirect_to :back
			flash[:notice] = "Verdict already exists."
		end
	end

	def create_sentence
		if Sentence.where(:name => params[:name]).empty?
			Sentence.create(name: params[:name])
			redirect_to :back
			flash[:notice] = "Sentence successfully created."
		else
			redirect_to :back
			flash[:notice] = "Sentence already exists."
		end
	end

	def get_string_between(my_string, start_at, end_at)
	    my_string = " #{my_string}"
	    ini = my_string.index(start_at)
	    return my_string if ini == 0
	    ini += start_at.length
	    length = my_string.index(end_at, ini).to_i - ini
	    my_string[ini,length]
	end
end

