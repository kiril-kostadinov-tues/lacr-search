class TranslationController < ApplicationController

	def get
		@tr = Translation.find_by word: params[:word], language: params[:lang]

		respond_to do |format|
			format.json { render json: @tr }
		end
	end

	def edit 
		translated = params[:translated]
		word = params[:word]
		language = params[:lang]

		tr = Translation.find_by word: word, language: language

		if tr.nil?
			tr = Translation.new
			tr.word = word
			tr.language = language
		end

		tr.translated = translated
		tr.save
	end

end
