module Api::V1::Admin
  class CollectionsController < ApplicationController
    include Api::JsonHelper
    include Api::GeoJsonHelper
    include Concerns::CheckApiDocs

    before_filter :authenticate_api_admin_user!
    skip_before_filter  :verify_authenticity_token

    def index
      collections = []
      query_collection = build_params params
      # query_collection = object_ar.limit(params[:limit]).offset(params[:offset])
      query_collection[:records].each do |c|
        last_activity = c.activities.last
        if last_activity
          last_activity_text = last_activity.created_at.strftime("%A, %B %d, %Y at %l%p")
        else
          last_activity_text = "No activity"
        end
        collections.push({
          :id => c.id,
          :name => c.name,
          :description => c.description,
          :created_at => c.created_at.strftime("%A, %B %d, %Y at %l%p"),
          :updated_at => last_activity_text,
          :total_member => c.memberships.size,
          :total_site => c.sites.size         
        })
      end
      render json: { :collections => collections, :total => query_collection[:total] }
    end

    def show
      c = Collection.find(params[:id]) 
      last_activity = c.activities.last
      if last_activity
        last_activity_text = last_activity.created_at.strftime("%A, %B %d, %Y at %l%p")
      else
        last_activity_text = "No activity"
      end   
      record = {
        :id => c.id,
        :name => c.name,
        :description => c.description,
        :created_at => c.created_at.strftime("%A, %B %d, %Y at %l%p"),
        :updated_at => last_activity_text,
        :list_member => list_member(c),
        :total_site => c.sites.size         
      }
      render json: record
    end

    def build_params params
      object = Collection
      unless (params[:name].nil? || params[:name].empty?)
        object = object.where("name LIKE '%#{params[:name]}%'")
      end

      unless (params[:from].nil? || params[:from].empty?)
        object = object.where("created_at > ?", DateTime.parse(params[:from]))
      end

      unless (params[:to].nil? || params[:to].empty?)
        object = object.where("created_at < ?", DateTime.parse(params[:to]))
      end

      unless (params[:user].nil? || params[:user].empty?)
        users = User.where("email Like '%#{params[:user]}%'").select("id")
        user_ids = []
        users.each do |u|
          user_ids.push(u.id)
        end
        object = object.where("id in (select collection_id from memberships where user_id in ('#{user_ids.join(',')}'))")
      end

      unless (params[:sortColumn].nil? || params[:sortColumn].empty?)
        case  params[:sortColumn]
        when "name"
          object = object.order("name #{params[:sortType]}")
        when "created_at"
          object = object.order("created_at #{params[:sortType]}")
        end
      end

      if((params[:name].nil? || params[:name].empty?) and (params[:from].nil? || params[:from].empty?) and (params[:to].nil? || params[:to].empty?) and (params[:user].nil? || params[:user].empty?))
        total = object.all.size
      else
        total = object.size
      end

      unless (params[:sortColumn].nil? || params[:sortColumn].empty?)
        case  params[:sortColumn]
        when "updated_at"
          conditions = []
          unless (params[:name].nil? || params[:name].empty?)
            conditions.push("c.name LIKE '%#{params[:name]}%'")
          end

          unless (params[:from].nil? || params[:from].empty?)
            conditions.push("c.created_at > '#{DateTime.parse(params[:from]).strftime("%Y-%m-%d %H-%M-%S")}'")
          end

          unless (params[:to].nil? || params[:to].empty?)
            conditions.push("c.created_at < '#{DateTime.parse(params[:to]).strftime("%Y-%m-%d %H-%M-%S")}'")
          end

          unless (params[:user].nil? || params[:user].empty?)
            users = User.where("email Like '%#{params[:user]}%'").select("id")
            user_ids = []
            users.each do |u|
              user_ids.push(u.id)
            end
            conditions.push("id in (select collection_id from memberships where user_id in ('#{user_ids.join(',')}'))")
          end

          unless conditions.empty?
            sql = "select id,(select s.id from activities as s where s.collection_id = c.id order by s.created_at DESC limit 1) as numSite from collections as c where #{conditions.join(' and ')} ORDER BY numSite #{params[:sortType]} LIMIT #{params[:limit]} OFFSET #{params[:offset]} "
          else
            sql = "select id,(select s.id from activities as s where s.collection_id = c.id order by s.created_at DESC limit 1) as numSite from collections as c ORDER BY numSite #{params[:sortType]} LIMIT #{params[:limit]} OFFSET #{params[:offset]}"
          end
          objects = ActiveRecord::Base.connection.execute(sql)
          collections = []
          objects.each do |o|
            c = Collection.find_by_id o[0]
            collections.push c
          end
          object = collections
        when "record"
          conditions = []
          unless (params[:name].nil? || params[:name].empty?)
            conditions.push("c.name LIKE '%#{params[:name]}%'")
          end

          unless (params[:from].nil? || params[:from].empty?)
            conditions.push("c.created_at > '#{DateTime.parse(params[:from]).strftime("%Y-%m-%d %H-%M-%S")}'")
          end

          unless (params[:to].nil? || params[:to].empty?)
            conditions.push("c.created_at < '#{DateTime.parse(params[:to]).strftime("%Y-%m-%d %H-%M-%S")}'")
          end

          unless (params[:user].nil? || params[:user].empty?)
            users = User.where("email Like '%#{params[:user]}%'").select("id")
            user_ids = []
            users.each do |u|
              user_ids.push(u.id)
            end
            conditions.push("id in (select collection_id from memberships where user_id in ('#{user_ids.join(',')}'))")
          end

          unless conditions.empty?
            sql = "select id,(select count(collection_id) from sites as s where s.collection_id = c.id) as numSite from collections as c where #{conditions.join(' and ')} ORDER BY numSite #{params[:sortType]} LIMIT #{params[:limit]} OFFSET #{params[:offset]} "
          else
            sql = "select id,(select count(collection_id) from sites as s where s.collection_id = c.id) as numSite from collections as c ORDER BY numSite #{params[:sortType]} LIMIT #{params[:limit]} OFFSET #{params[:offset]}"
          end
          objects = ActiveRecord::Base.connection.execute(sql)
          collections = []
          objects.each do |o|
            c = Collection.find_by_id o[0]
            collections.push c
          end
          object = collections
        when "member"
          conditions = []
          unless (params[:name].nil? || params[:name].empty?)
            conditions.push("c.name LIKE '%#{params[:name]}%'")
          end

          unless (params[:from].nil? || params[:from].empty?)
            conditions.push("c.created_at > '#{DateTime.parse(params[:from]).strftime("%Y-%m-%d %H-%M-%S")}'")
          end

          unless (params[:to].nil? || params[:to].empty?)
            conditions.push("c.created_at < '#{DateTime.parse(params[:to]).strftime("%Y-%m-%d %H-%M-%S")}'")
          end

          unless (params[:user].nil? || params[:user].empty?)
            users = User.where("email Like '%#{params[:user]}%'").select("id")
            user_ids = []
            users.each do |u|
              user_ids.push(u.id)
            end
            conditions.push("id in (select collection_id from memberships where user_id in ('#{user_ids.join(',')}'))")
          end

          unless conditions.empty?
            sql = "select id,(select count(collection_id) from memberships as s where s.collection_id = c.id) as numSite from collections as c where #{conditions.join(' and ')} ORDER BY numSite #{params[:sortType]} LIMIT #{params[:limit]} OFFSET #{params[:offset]} "
          else
            sql = "select id,(select count(collection_id) from memberships as s where s.collection_id = c.id) as numSite from collections as c ORDER BY numSite #{params[:sortType]} LIMIT #{params[:limit]} OFFSET #{params[:offset]}"
          end
          objects = ActiveRecord::Base.connection.execute(sql)
          collections = []
          objects.each do |o|
            c = Collection.find_by_id o[0]
            collections.push c
          end
          object = collections
        end
      end

      if (params[:sortColumn] != "member" and params[:sortColumn] != "record" and params[:sortColumn] != "updated_at")
        records = object.limit(params[:limit]).offset(params[:offset])
      else
        records = object
      end
      data = {total: total, records: records}
      return data
    end

    def list_member collection
      members = []
      collection.memberships.each do |m|
        can_update_site = m.admin?? (collection.sites.size):(count_site(m.sites_permission[:write]))
        # can_read_site = m.admin?? (collection.sites.size):(count_site(m.sites_permission[:read]))
        can_not_access_site = m.admin?? 0:(count_cannot_access_site(m.sites_permission))
        record = {
          :is_admin => m.admin,
          :email => m.user.email,
          :number_site_can_update => can_update_site,
          :number_site_can_read => (collection.sites.size - can_not_access_site),
          :number_site_cannot_access => can_not_access_site
        }
        members.push record
      end
      return members
    end

    def count_site site_permission
      if site_permission
        if site_permission[:all_sites]
          return site_permission.membership.collection.sites.size
        else
          return site_permission["some_sites"].size
        end
      else
        return 0
      end
    end

    def count_cannot_access_site site_permission
      if site_permission[:read]
        if site_permission[:read][:all_sites]
          return 0
        end
      end
      if site_permission[:write]
        if site_permission[:write][:all_sites]
          return 0
        end
      end
      return count_site(site_permission[:none])
    end
  end
end