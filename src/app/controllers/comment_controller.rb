class CommentController < ApplicationController
	
	def post
		comment = Comment.new
		comment.content = params[:content]
		comment.user_id = params[:user_id]
		comment.search_volume = params[:volume]
		comment.search_page = params[:page]
		comment.save
		redirect_to :back
 	end


end
