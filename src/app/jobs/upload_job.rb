class UploadJob < ApplicationJob
	queue_as :default

	def perform(user,password,volume,page,collId,fname,filepath)
		transkribus = TranskribusService.new()
		transkribus.tr_login(user,password)
		uploadId = transkribus.tr_create_upload(collId,fname)
		jobId = transkribus.tr_upload(uploadId,fname,filepath)
		transkribus.tr_wait_job(jobId)
		docId = uploadId
		pageId = transkribus.tr_fulldoc(collId,docId)['pageList']['pages'][0]['pageId']
		jobId = transkribus.tr_LA(collId,docId,pageId)
		transkribus.tr_wait_job(jobId)
		tsId = transkribus.tr_fulldoc(collId,docId)['pageList']['pages'][0]['tsList']['transcripts'][0]['tsId']
		transkribus.add_doc_to_page_image(volume,page,collId,docId,tsId)
		puts "The document was uploaded successfully"
	end	
end
