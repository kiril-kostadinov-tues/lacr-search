#app/services/transkribus_service.rb
require 'net/http'
require 'json'
require 'uri'

class TranskribusService
	def initialize()
		@sessionId = ""
	end

	# Login into Transkribus
	def tr_login(user,password)
		req_params = {:user => user, :pw => password}
		uri = URI("https://transkribus.eu/TrpServer/rest/auth/login")
		res = Net::HTTP.post_form(uri,req_params)
		if res.code == "200"
		  @sessionId = Nokogiri::XML(res.body).xpath('//sessionId')[0].to_s[/\>(.*?)</,1]
		end
	end

	#def tr_logout(sessionId)
  	#  url = URI("https://transkribus.eu/TrpServer/rest/auth/logout?JSESSIONID="+sessionId)  
  	#  http = Net::HTTP.new(url.host,url.port)
  	#  http.use_ssl = true
  	#  req = Net::HTTP::Post.new(url)
  	#  return http.request(req)
  	#end

  	# Wait for a job to complete
	def tr_wait_job(jobId)
		finished = false

		url = URI("https://transkribus.eu/TrpServer/rest/jobs/#{jobId}?JSESSIONID="+@sessionId)
		http = Net::HTTP.new(url.host,url.port)
		http.use_ssl = true

		while !finished do
		  sleep 15
		  req = Net::HTTP::Get.new(url)
		  finished = JSON.parse(http.request(req).body)['success']
		end
	end

	# Create the structure necessary to upload an image into Transkribus
	def tr_create_upload(collId,fname)
	    url = URI.parse("https://transkribus.eu/TrpServer/rest/uploads")
	    sess_params = {:collId => collId, :JSESSIONID => @sessionId}
	    url.query = URI.encode_www_form(sess_params)
	    http = Net::HTTP.new(url.host,url.port)
	    http.use_ssl = true
	    req = Net::HTTP::Post.new(url,"Content-Type" => "application/json")
	    req.body = { md: {title: fname[/(.*?)\./,1], "author": "lacr"}, pageList: {pages: [{fileName: fname, pageNr: 1}] } }.to_json

	    return Nokogiri::XML(http.request(req).body).xpath('//uploadId')[0].to_s[/\>(.*?)</,1]
	end

	# Upload an image to Transkribus
	def tr_upload(uploadId,fname,filepath)
		url = URI("https://transkribus.eu/TrpServer/rest/uploads/#{uploadId}?JSESSIONID="+@sessionId)
		http = Net::HTTP.new(url.host,url.port)
		http.use_ssl = true
		header = {"Content-Type" => 'multipart/form-data; boundary=----WebKitFormBoundary7MA4YWxkTrZu0gW'}
		request = Net::HTTP::Put.new(url,header)
		request.body = "------WebKitFormBoundary7MA4YWxkTrZu0gW\r\nContent-Disposition: form-data; name=\"img\"; filename=\"#{fname}\"\r\nContent-Type: image/jpeg\r\n\r\n"+File.read(filepath)+"\r\n------WebKitFormBoundary7MA4YWxkTrZu0gW--"
		return Nokogiri::XML(http.request(request).body).xpath('//jobId')[0].to_s[/\>(.*?)</,1] #jobId
	end

	# Delete a document (containing an image) from Transkribus
	def tr_delete_doc(collId,docId)
		url = URI("https://transkribus.eu/TrpServer/rest/collections/#{collId}/#{docId}?JSESSIONID="+@sessionId)
		http = Net::HTTP.new(url.host,url.port)
		http.use_ssl = true

		req = Net::HTTP::Delete.new(url)
		response = http.request(req)
		return response.code
	end

	# Perform Layout Analysis on an image
	def tr_LA(collId,docId,pageId)
		url = URI("https://transkribus.eu/TrpServer/rest/LA")
		sess_params = {:JSESSIONID => @sessionId, :collId => collId, :doBlockSeg => true, :doLineSeg => true, :doWordSeg =>false, :jobImpl => "CITlabAdvancedLaJob", :doCreateJobBatch => false}
		url.query = URI.encode_www_form(sess_params)

		http = Net::HTTP.new(url.host,url.port)
		http.use_ssl = true
		req = Net::HTTP::Post.new(url,"Content-Type" => "application/json")
		req.body = {"docList": {"docs": [{"docId": docId, "pageList": {"pages": [{"pageId": pageId, "tsId": 0, "regionIds": []}]}}]},"params": {"entry": []}}.to_json
		return Nokogiri::XML(http.request(req).body).xpath('//jobId')[0].to_s[/\>(.*?)</,1] #jobId
	end

	# Get the metadata for the given document. Includes transcriptions and line coordinates.
	def tr_fulldoc(collId,docId)
		url = URI("https://transkribus.eu/TrpServer/rest/collections/#{collId}/#{docId}/fulldoc?JSESSIONID="+@sessionId)
		http = Net::HTTP.new(url.host,url.port)
		http.use_ssl = true
		req = Net::HTTP::Get.new(url)
		response = http.request(req) 
		if response.code == "200"
		  return JSON.parse(response.body)
		else
		  return response.code
		end
	end

	# Get simplified coordinates for a line
	def get_line_coords(linesUrl)
		url = URI(linesUrl)
		http = Net::HTTP.new(url.host,url.port)
		http.use_ssl = true
		req = Net::HTTP::Get.new(url)
		return http.request(req)
	end

	# Delete line info from the database
	def destroy_lines(volume,page)
		lines = Line.where('volume' => volume).rewhere('page' => page)
		lines.each do |line|
			line.destroy
		end
	end

	# Updates PageImage information
	def add_doc_to_page_image(vol, page, collId, docId, tsId)
		page = PageImage.find_by_volume_and_page(vol, page)
		page.collId = collId
		page.docId = docId
		page.tsId = tsId
		if page.save!
		  puts "The page was updated"
		else
		  puts"There was a problem with updating the page"
		end
	end

	# Add line info to the database
	def add_lines(vol, page, collId, docId)
		tr = tr_fulldoc(collId,docId)['pageList']['pages'][0]['tsList']['transcripts'][0]
		linesUrl = tr['url']
		tsId = tr['tsId']

		#extracting lines' coords
		response = get_line_coords(linesUrl)
		lines = response.body.split("<TextLine").drop(1)

		changed = false

		lines.each do |line|
		  lineCoords = line[/Coords points="(.*?)"/,1].split(" ")
		  transcript = line[/<Unicode>(.*?)</,1]
		  if transcript
		  	if !changed
				destroy_lines(vol,page)
			end

		    changed = true
		    l = Line.new
		    l.volume = vol
		    l.page = page
		    l.x1,l.y1 = lineCoords[-1].split(',')
		    l.x2,l.y2 = lineCoords[0].split(',')
		    l.x3,l.y3 = lineCoords[lineCoords.length/2-1].split(',')
		    l.x4,l.y4 = lineCoords[lineCoords.length/2].split(',')
		    l.transcript = transcript
		    if l.save!
		      puts "Line successfully created"
		    #  puts "X1 = #{l.x1}, Y1 = #{l.y1}\nX2 = #{l.x2}, Y2 = #{l.y2}\nX3 = #{l.x3}, Y3 = #{l.y3}\nX4 = #{l.x4}, Y4 = #{l.y4}\n\n"  
		    #  puts l.transcript + '\n'
		    end
		  end  
		end 

		if changed
			add_doc_to_page_image(vol,page,collId,docId,tsId)
		end   

	end 

end