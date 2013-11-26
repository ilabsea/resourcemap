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

			collections_id.push(nil)

			if params[:raws] || params[:collection_ids]
				if params[:raws] == ["0"] && !params[:collection_ids]
					collections_id = current_user.memberships.pluck(:collection_id)
				elsif params[:raws] != ["0"] && !params[:collection_ids]
					collections_id = current_user.memberships.pluck(:collection_id).push(nil)
				elsif params[:raws] == ["0"] && params[:collection_ids] != 0
					collections_id = params[:collection_ids]
				elsif params[:raws] != ["0"] && params[:collection_ids] == ["0"]
					collections_id = [nil]
				elsif params[:raws] != ["0"] && params[:collection_ids] != ["0"]
					collections_id = params[:collection_ids].push(nil)
				else
					collections_id = ["0"]
				end
			end
			
			# collections_id = "("+collections_id.join(",")+")"
			before_id = params[:before_id] ? params[:before_id].to_i + 1 : 0 
			if collections_id.include?(nil)
				collections_id.slice!(collections_id.size-1)
				if collections_id.count == 0
					if params[:phone_number]
						phone_number = params[:phone_number]
						msgs = ActiveRecord::Base.connection.execute("Select * from messages where messages.collection_id is null and messages.from like '%#{phone_number}%' order by created_at desc limit #{before_id},#{size}")
					else
						msgs = ActiveRecord::Base.connection.execute("Select * from messages where messages.collection_id is null order by created_at desc limit #{before_id},#{size}")
					end
				else
					collections_id = "("+collections_id.join(",")+")"
					if params[:phone_number]
						phone_number = params[:phone_number]
						msgs = ActiveRecord::Base.connection.execute("Select * from messages where (messages.collection_id in #{collections_id} or messages.collection_id is null) and messages.from like '%#{phone_number}%' order by created_at desc limit #{before_id},#{size}")
					else
						msgs = ActiveRecord::Base.connection.execute("Select * from messages where messages.collection_id in #{collections_id} or messages.collection_id is null order by created_at desc limit #{before_id},#{size}")
					end
				end
			else
				if collections_id.count == 0
					if params[:phone_number]
						phone_number = params[:phone_number]
						msgs = ActiveRecord::Base.connection.execute("Select * from messages where messages.collection_id is null and messages.from like '%#{phone_number}%' order by created_at desc limit #{before_id},#{size}")
					else
						msgs = ActiveRecord::Base.connection.execute("Select * from messages where messages.collection_id is null order by created_at desc limit #{before_id},#{size}")
					end
				else
					collections_id = "("+collections_id.join(",")+")"
					if params[:phone_number]
						phone_number = params[:phone_number]
						msgs = ActiveRecord::Base.connection.execute("Select * from messages where (messages.collection_id in #{collections_id}) and messages.from like '%#{phone_number}%' order by created_at desc limit #{before_id},#{size}")
					else
						msgs = ActiveRecord::Base.connection.execute("Select * from messages where messages.collection_id in #{collections_id} order by created_at desc limit #{before_id},#{size}")
					end
				end
			end	


			# debugger

			# msgs = Message.order('id desc').where(collection_id: collections_id)
			# msgs = msgs.limit(25)
   #    msgs = msgs.where('id < ?', params[:before_id]) if params[:before_id]

			# if params[:phone_number]
			# 	phone_number = "%#{params[:phone_number]}%"
			# 	msgs = msgs.where('`from` like ?', phone_number)
			# end

			activities_json = []
			msgs.each do |message|
				collection_name = message[13].nil? ? "" : Collection.find(message[13]).name
				# debugger
				tmp = {
					id: message[0],
					collection: collection_name,
					user: message[6].split("//")[1],
					description: message[9],
					created_at: message[10]
				}
				activities_json.push(tmp)
			end
			# debugger
			render json: activities_json
		end
	end
end

end