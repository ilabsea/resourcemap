class MessagesController < ApplicationController

	expose(:collections) { 
    if current_user && !current_user.is_guest
      # public collections are accesible by all users
      # here we only need the ones in which current_user is a member
      current_user.collections.reject{|c| c.id.nil?}
    else
      Collection.accessible_by(current_ability)
    end 
  }

  expose(:users) {
  	if current_user && !current_user.is_guest
  		collections_id = current_user.collections.pluck(:collection_id)
  		users_id = Membership.where(collection_id: collections_id).pluck(:user_id).uniq
  		users = User.where(id: users_id)
		else
			Collection.accessible_by(current_ability)
		end
  }

def index
	# debugger

	respond_to do |format|
		format.html
		format.json do
			collections_id = current_user.memberships.pluck(:collection_id)
			all_messages = []
			size = 25

			users.each do |user|
				tmps = Message.order('id desc').where('`from` like ?', "%#{user.phone_number}%")
				tmps.each do |t|
					all_messages.push(t)
				end
			end


			# msgs = Message.order('id desc').where(collection_id: collections_id)
			# msgs = msgs.limit(5)
			# msgs = msgs.where('id < ?', params[:before_id]) if params[:before_id]


			if params[:user_phone_numbers]
				msgs = []
				phone_messages = []
				params[:user_phone_numbers].each do |phone_number|
					if phone_number != "0"
						tmp_msgs = Message.order('id desc').where('`from` like ?', "%#{phone_number}%")
						tmp_msgs.each do |msg|
							phone_messages.push(msg)
						end
					end
				end
			end


			if params[:collection_ids]
				msgs = []
				msgs_collection = []
				if params[:collection_ids] == ["0"]
					msgs_collection = Message.order('id desc').where(:collection_id => nil)
				else
					msgs_collection = Message.order('id desc').where(collection_id: params[:collection_ids])
				end
			end


			if phone_messages
				if msgs_collection
					msgs = phone_messages & msgs_collection
				else
					msgs = phone_messages
				end
			end

			if msgs_collection
				if phone_messages
					msgs = phone_messages & msgs_collection
				end
			end

			if msgs
				msgs = all_messages & msgs
			else
				msgs = all_messages
			end

			msgs.sort_by &:created_at

			if params[:before_id]
				msgs = msgs[params[:before_id].to_i..size+params[:before_id].to_i] if params[:before_id].to_i > 0
			else
				msgs = msgs[0..size]
			end

			# debugger
			# msgs = msgs.limit(25)
			activities_json = msgs.map do |message|
				collection_name = message.collection_id.nil? ? "" : message.collection.name
				{
					id: message.id,
					collection: collection_name,
					user: message.from.split("//")[1],
					description: message.body,
					created_at: message.created_at
				}
			end
			render json: activities_json
		end
	end
end

end