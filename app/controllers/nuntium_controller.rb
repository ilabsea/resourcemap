require 'treetop_dependencies'
require 'digest'

class NuntiumController < ApplicationController
  helper_method :save_message
  protect_from_forgery :except => :receive

  USER_NAME, PASSWORD = 'iLab', '1c4989610bce6c4879c01bb65a45ad43'

  # POST /messaging
  # def index
    # raise HttpVerbNotSupported.new unless request.post?
    # message = save_message
    # begin
      # message.process! params
    # rescue => err
      # message.reply = err.message
    # ensure
    # if (message.reply != "Invalid command")
      # message[:collection_id] = get_collection_id(params[:body])
    # end
    # message.save
    # render :text => message.reply, :content_type => "text/plain"
    # end
  # end
  
  # POST /nuntium
  def receive
    begin
      message = save_message
    rescue => err
      render :text => err.message, :status => 400
      return
    end
    
    begin
      message.process! params
    rescue => err
      message.reply = err.message
    ensure
    if (message.reply != "Invalid command")
      collection_id = get_collection_id(params[:body])
      if collection_id and collection_id >0
        message[:collection_id] = collection_id
      end
    end
    message.save
    render :text => message.reply, :content_type => "text/plain"
    end
  end

  def authenticate
    authenticate_or_request_with_http_basic 'Dynamic Resource Map - HTTP' do |username, password|
      USER_NAME == username && PASSWORD == Digest::MD5.hexdigest(password)
    end
  end

  def get_collection_id(bodyMsg)
    if (bodyMsg[5] == "q")
      collectionId = Message.getCollectionId(bodyMsg, 7)
    elsif (bodyMsg[5] == "u")
      siteCode = Message.getCollectionId(bodyMsg, 7)
      site = Site.find_by_id_with_prefix(siteCode)
      if site
        collectionId = site.collection_id
      else
        collectionId = -1
      end
    end
    return collectionId
  end

  def save_message
    Message.create!(:guid => params[:guid], :from => params[:from], :body => params[:body]) do |m|
      m.country = params[:country]
      m.carrier = params[:carrier]
      m.channel = params[:channel]
      m.application = params[:application]
      m.to = params[:to]
    end
  end
end
