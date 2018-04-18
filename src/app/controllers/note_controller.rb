class NoteController < ApplicationController
	def create
		note = Note.new
		note.content = params[:content]
		note.user_id = params[:user_id]
		note.search_volume = params[:volume]
		note.search_page = params[:page]
		note.search_paragraph = params[:paragraph]
		note.save
		redirect_to :back
 	end

 	def index
 		if user_signed_in?
 			@usrnote = current_user.note
 		end
 	end

 	def destroy
 		note = Note.where(id: [params[:id].to_i]).first
 		if user_signed_in?
 			if current_user.id == note.user_id
 				note.destroy
 				redirect_to :back
 			end
 		end
 	end

 end