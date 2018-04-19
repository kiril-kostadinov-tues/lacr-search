class LinesController < ApplicationController
	def update_lines

	end

	def do_update
	    if user_signed_in? and current_user.admin? 
	    	vol = params[:vol].to_i
	    	page = params[:page].to_i

	    	pages = PageImage.where('volume' => vol).rewhere('page' => page)

		    user = "teamcharlielacr@gmail.com"
		    pw = "lacrsearch2"
		    AddLinesJob.perform_later(user,pw,vol,page,pages[0].collId,pages[0].docId)
      		flash[:notice] = "The lines are updated"
      		redirect_to :back
	    else
	    	redirect_to new_user_session_path, :alert => "Not logged in or Insufficient rights!"  
	    end
	end
end
