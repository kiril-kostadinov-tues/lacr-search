class CommentController < ApplicationController
	
	# Post a new coment
	def post
		comment = Comment.new
		comment.content = params[:content]
		comment.user_id = params[:user_id]
		comment.search_volume = params[:volume]
		comment.search_page = params[:page]
		comment.save
		redirect_to :back
		flash[:notice] = "Comment successfully posted."
 	end

 	# Delete a comment
 	def destroy
 		comment = Comment.where(id: [params[:id].to_i]).first
 		if user_signed_in?
 			# Check if the user trying to delete the comment is the owner
 			if current_user.id == comment.user_id
 				comment.destroy
 				redirect_to :back
 			end
 		end
 	end


end
