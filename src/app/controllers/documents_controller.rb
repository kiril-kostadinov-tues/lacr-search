require "#{Rails.root}/lib/BaseXClient"
require 'net/http'
require 'uri'
require 'json'

class DocumentsController < ApplicationController
  def index
    @documents = Search.select(:page, :volume).distinct.order(volume: :asc, page: :asc).group(:volume, :page)
    @images = []
    
    @documents.each do |document|
      image = PageImage.find_by_volume_and_page(document.volume, document.page)
      if image
        @images << image.image.normal.url.split('.')[0...-1].join + '.jpeg'
      end
    end
  end

  def selected
    selected_entries = cookies[:selected_entries]
    if selected_entries
      @documents = Search.where({entry: selected_entries.split(',')})
      if @documents.length == 0
        cookies.delete :selected_entries
        redirect_to doc_path, :alert => "No selected paragraphs!"
      end
    else
      cookies.delete :selected_entries
      redirect_to doc_path, :alert => "No selected paragraphs!"
    end
  end

  def list
    @documents = Search.select(:page, :volume).distinct.order(volume: :asc, page: :asc).group(:volume, :page)
    
    respond_to do |format|
      format.html { redirect_to doc_path }
      format.json { render json: @documents }
      format.js   { render :layout => false }
    end
  end

  def new
    if not user_signed_in? or not current_user.admin?
      redirect_to new_user_session_path, :alert => "Not logged in or Insufficient rights!"
    end
  end

  def edit
    if user_signed_in? and current_user.admin?
      @content = TrParagraph.find(params[:id]).content_xml
    else
      redirect_to new_user_session_path, :alert => "Not logged in or Insufficient rights!"  
    end
  end

  def edit_finished
    if user_signed_in? and current_user.admin?
      xml = params[:transcription_xml][:new_xml]
      @new_text = TrParagraph.find(params[:edited_document_id])
      @new_text.content_xml = xml
      @new_text.save
      @new_text = TrParagraph.find(params[:edited_document_id])
      new_html = Nokogiri::XML(xml) 
      xml_to_html(new_html) 
      @new_text.content_html = new_html
      @new_text.save
      redirect_to doc_path
      flash[:notice] = "Document successfully edited!"
    else
      redirect_to new_user_session_path, :alert => "Not logged in or Insufficient rights!"
    end
  end

  def show
    if params.has_key?(:p) and params.has_key?(:v) \
      and params[:v].to_i > 0 and  params[:v].to_i < 1000000 \
      and params[:p].to_i > 0 and  params[:p].to_i < 1000000
      # Store the volume and page from the input
      @volume, @page = params[:v].to_i, params[:p].to_i 
      page_image = PageImage.find_by_volume_and_page(@volume, @page)       
      if page_image # Has been uploaded
          # Simple Fix of the file extension after image convert
          @document_image_normal = page_image.image.normal.url.split('.')[0...-1].join + '.jpeg'
          @document_image_large = page_image.image.large.url.split('.')[0...-1].join + '.jpeg'
      end
      @lines = Line.where('volume' => @volume).rewhere('page' => @page)
      if params[:searchID]
        @searchID = 'searchID'
      end
    else
      redirect_to doc_path, notice:  "The document has not been found."
    end
  end

  def page_simplified
    if params.has_key?(:p) and params.has_key?(:v) \
      and params[:v].to_i > 0 and  params[:v].to_i < 1000000 \
      and params[:p].to_i > 0 and  params[:p].to_i < 1000000
      # Store the volume and page from the input
      @volume, @page = params[:v].to_i, params[:p].to_i
      # Select Documents
      @documents = Search.order(:paragraph).where('volume' => @volume).rewhere('page' => @page)
      if @documents.length > 0
        # Select image
        respond_to do |format|
         format.html { render :partial => "documents/page_simplified" }
       end
      else
        render status: 500
      end
    else
      render status: 500
    end
  end

  def page  
    if params.has_key?(:p) and params.has_key?(:v) \
      and params[:v].to_i > 0 and  params[:v].to_i < 1000000 \
      and params[:p].to_i > 0 and  params[:p].to_i < 1000000
      # Store the volume and page from the input
      @volume, @page = params[:v].to_i, params[:p].to_i
      # Select Documents
      @documents = Search.order(:paragraph).where('volume' => @volume).rewhere('page' => @page)      
      @comments = Comment.where("search_volume = ? AND search_page = ?", @volume, @page)
      @lines = Line.where('volume' => @volume).rewhere('page' => @page)

      if @documents.length > 0
        # Select image
        page_image = PageImage.find_by_volume_and_page(@volume, @page)
        if page_image # Has been uploaded
          # Simple Fix of the file extension after image convert
          @document_image_normal = page_image.image.normal.url.split('.')[0...-1].join + '.jpeg'
          @document_image_large = page_image.image.large.url.split('.')[0...-1].join + '.jpeg'

        end
        respond_to do |format|
         format.html { render :partial => "documents/page" }

        end

      else
        render status: 500
      end
    else
      render status: 500
    end
  end

  def upload
    if user_signed_in? and current_user.admin?
        @succesfully_uploaded = {xml:[], image:[]}
        @unsuccesfully_uploaded = {xml:[], image:[]}
        if params.has_key?(:transcription_xml)
          xml_files = xml_upload_params
          xml_files_content = []
          # Save all uploaded xml files, call method ...
          xml_files['xml'].each do |file|
            # Get filename
            filename = file.original_filename
            # Check namespace
            nokogiri_obj = Nokogiri::XML(File.open(file.path))
            if ( nokogiri_obj.collect_namespaces.values.include? TranscriptionXml::HISTEI_NS )
              # Show message when overwrites
              output_message = TranscriptionXml.exists?(filename: filename) ? "Overwritten #{filename}" : filename
              # Create new or find existing record
              t = TranscriptionXml.find_or_create_by(filename: filename)
              # Store the information about the uploaded file
              t.xml = file
              # If the save was successful
              if t.save!
                @succesfully_uploaded[:xml].push(output_message)
                # Store file content and filename for import to BaseX
                xml_files_content.push([filename, nokogiri_obj.to_xml.gsub('xml:lang="sc"', 'xml:lang="sco"').gsub('xml:lang="la"', 'xml:lang="lat"').gsub('xml:lang="nl"', 'xml:lang="nld"')])
                # Proccess the XML file
                t.histei_split_to_paragraphs
              else
                @unsuccesfully_uploaded[:xml].push("Unexpected error on saving: #{filename}")
              end
            else
              @unsuccesfully_uploaded[:xml].push("HisTEI namespace not found: #{filename}")
            end
          end

          # Upload xml contnet to BaseX
          begin # Catch connection error
            session = BaseXClient::Session.new(ENV['BASEX_URL'], 1984, "createOnly", ENV['BASEX_CREATEONLY'])
            session.execute('open xmldb') # Open XML database
            xml_files_content.each do |file_name, file_content|
              begin # Catch document creation error
                session.replace(file_name, file_content)
              rescue Exception => e
                logger.error(e)
              end
            end
            session.close
        rescue Exception => e
          logger.error(e)
        end
         #End of uploading to BaseX

        # Generate new index for Elasticsearch
        Search.reindex()
      end

      if params.has_key?(:page_image)
        image_files = image_upload_params
        # Save all uploaded image files, call method ...
        image_files['image'].each do |file|
          t = PageImage.new
          t.image = file
          t.parse_filename_to_volume_page file.original_filename
          if t.save!
            @succesfully_uploaded[:image].push(file.original_filename)

            #uploadJob
            user = "teamcharlielacr@gmail.com"
            password = "lacrsearch2"
            collId = 13977            
            fname = file.original_filename.split('.')[0...-1].join + '.jpeg'
            fpath = File.join(Rails.root, 'public', 'uploads', 'image','large_'+fname)
            UploadJob.perform_later(user,password,t.volume,t.page,collId,fname,fpath)            
            
            #LAJob
            volume = t.volume
            page = t.page

          
            #add lines if using htr
            #add_lines(t.volume,t.page,sessionId, collId, docId) 

            #end transkribus
          else
            @unsuccesfully_uploaded[:image].push(file.original_filename)
          end
        end
      end
    else
      redirect_to new_user_session_path, :alert => "Not logged in or Insufficient rights!"
    end
  end


  def destroy
    if user_signed_in? and current_user.admin?
      selected = params['selected']
      # If there is at least one selected page
      if selected
        selected.each do |s|
          entry = selected[s]
          if entry.key?("volume") and entry.key?("page")
            vol, page = entry['volume'], entry['page']
            tr_xml = Search.where('volume' => vol).rewhere('page' => page)

            img = PageImage.where('volume' => vol).rewhere('page' => page)
            if img.length > 0
              transkribus_collId = img[0].collId
              transkribus_docId = img[0].docId

              if transkribus_collId && transkribus_docId
                transkribus = TranskribusService.new()
                transkribus.tr_login("teamcharlielacr@gmail.com","lacrsearch2")
                req_code = transkribus.tr_delete_doc(transkribus_collId,transkribus_docId)
                transkribus.destroy_lines(vol,page)
              end
              img[0].destroy
            end   


            if tr_xml # If the db record was found
              tr_xml.each do |tr|
                # Remove content from BaseX
                begin # Catch connection error
                  session = BaseXClient::Session.new(ENV['BASEX_URL'], 1984, "createOnly", ENV['BASEX_CREATEONLY'])
                  session.execute('open xmldb') # Open XML database

                  # XQuery delete node query
                  # Create instance the BaseX Client in Query Mode
                  query = session.query("\
                    declare namespace ns = \"http://www.tei-c.org/ns/1.0\"; \
                    delete node //ns:div[@xml:id=\"#{tr.entry}\"] \
                  ")
                  query.execute
                  query.close
                  session.close
                rescue Exception => e
                  logger.error(e)
                end
                # End of BaseX remove

                tr.tr_paragraph.destroy
                tr.destroy
              end # tr_xml.each
            end # if xml
          end # if entry.key?
        end # selected.each
        respond_to do |format|
          format.json { render json: {'type': 'success', 'msg': "Selected documents have been removed."} }
          format.js   { render :layout => false }
        end
      else
        respond_to do |format|
          format.json { render json: {'type': 'warning', 'msg': "Error: No selected documents!"} }
          format.js   { render :layout => false }
        end
      end # if selected
    else
      redirect_to new_user_session_path, :alert => "Not logged in or Insufficient rights!"
    end # if user_signed_in?

  end

  # Recursive function to convert the XML format to valid HTML5
  def xml_to_html(tag)
    tag.children().each do |c|
      # Rename the attributes
      c.keys.each do |k|
        c["data-#{k}"] = c.delete(k)
      end
      # Rename the tag and replace lb with br
      c['class'] = "xml-tag #{c.name.gsub(':', '-')}"
      # To avoid invalid void tags: Use "br" if "lb", otherwise "span"
      c.name = c.name == 'lb' ?  "br" : "span"
      # Use recursion
      xml_to_html(c)
    end
  end



  private  # all methods that follow will be made private: not accessible for outside objects
    def xml_upload_params
      if user_signed_in? and current_user.admin?
        params.require(:transcription_xml).permit xml: []
      else
        redirect_to new_user_session_path, :alert => "Not logged in or Insufficient rights!"
      end
    end

    def image_upload_params
      if user_signed_in? and current_user.admin?
        params.require(:page_image).permit image: []
      else
        redirect_to new_user_session_path, :alert => "Not logged in or Insufficient rights!"
      end
    end
end
