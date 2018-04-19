class UpdateLinesJob < ActiveJob::Base
	queue_as :default

	def perform(user,password)
		transkribus = TranskribusService.new()
		transkribus.tr_login(user,password)
		transkribus.update_lines()	
	end

end
