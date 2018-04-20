class AddLinesJob < ActiveJob::Base
	queue_as :default

	# Update line information from Transkribus
	def perform(user,password,volume,page,collId,docId)
		transkribus = TranskribusService.new()
		transkribus.tr_login(user,password)
		transkribus.add_lines(volume,page,collId,docId)
	end

end
