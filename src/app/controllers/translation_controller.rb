class TranslationController < ApplicationController

	def get
		@tr = Translation.find_by word: params[:word], language: params[:lang]

		respond_to do |format|
			format.json { render json: @tr }
		end
	end

	def edit 
		if user_signed_in? and current_user.admin?
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
		else
	      redirect_to new_user_session_path, :alert => "Not logged in or Insufficient rights!"
	    end
	end
end
