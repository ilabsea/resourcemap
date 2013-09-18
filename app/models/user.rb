class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :token_authenticatable, :encryptable, :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable, :confirmable,
         :token_authenticatable
  before_create :reset_authentication_token
  before_save :ensure_authentication_token
  # Setup accessible (or protected) attributes for your model attr_accessible :email, :password, :password_confirmation, :remember_me, :phone_number
  has_many :memberships
  has_many :channels
  has_many :collections, through: :memberships, order: 'collections.name ASC'
  has_one :user_snapshot
  
  validates_uniqueness_of :phone_number, :allow_blank => true

  attr_accessor :is_guest

  def create_collection(collection)
    return false unless collection.save
    memberships.create! collection_id: collection.id, admin: true
    collection.register_gateways_under_user_owner(self)
    collection
  end

  def admins?(collection)
    memberships.where(:collection_id => collection.id).first.try(:admin?)
  end

  def belongs_to?(collection)
    memberships.where(:collection_id => collection.id).exists?
  end

  def membership_in(collection)
    memberships.where(:collection_id => collection.id).first
  end

  def display_name
    email
  end

  def can_write_field?(field, collection, field_es_code)
    return false unless field

    membership = membership_in(collection)
    return true if membership.admin?

    lm = LayerMembership.where(user_id: self.id, collection_id: collection.id, layer_id: field.layer_id).first
    lm && lm.write
  end

  def activities
    Activity.where(collection_id: memberships.pluck(:collection_id))
  end

  def can_view?(collection, option)
    return collection.public if collection.public
    membership = self.memberships.where(:collection_id => collection.id).first
    return false unless membership
    return membership.admin if membership.admin

    return true if(validate_layer_read_permission(collection, option))
    false
  end

  def can_update?(site, properties)
    membership = self.memberships.where(:collection_id => site.collection_id).first
    return false unless membership
    return membership.admin if membership.admin?
    return true if(validate_layer_write_permission(site, properties))
    false
  end

  def can_add?(collection_id)
    membership = self.memberships.where(:collection_id => collection_id).first
    return false unless membership
    return membership.admin if membership.admin?
  end

  def validate_layer_write_permission(site, properties)
    properties.each do |prop|
      field = Field.where("code=? && collection_id=?", prop.values[0].to_s, site.collection_id).first
      return false if field.nil?
      lm = LayerMembership.where(user_id: self.id, collection_id: site.collection_id, layer_id: field.layer_id).first
      return false if lm.nil?
      return false if(lm.write == false)
    end
    return true
  end

  def validate_layer_read_permission(collection, field_code)
    field = Field.where("code=? && collection_id=?", field_code, collection.id).first
    return false if field.nil?
    lm = LayerMembership.where(user_id: self.id, collection_id: collection.id, layer_id: field.layer_id).first
    return false if lm.nil?
    return false if(!lm && lm.read)
    return true
  end

  def self.encrypt_users_password
    all.each { |user| user.update_attributes password: user.encrypted_password }
  end

  def get_gateway
    channels.first
  end

  def active_gateway
    channels.where("channels.is_enable=?", true)
  end

  def update_successful_outcome_status
    self.success_outcome = layer_count? & collection_count? & site_count? & gateway_count?
  end

  def register_guest_membership(collection_id)
    membership = self.memberships.find_by_collection_id collection_id
    self.memberships.create! collection_id: collection_id, admin: false  if(!membership)
  end

  def self.generate_random_password
    Devise.friendly_token.first(6)
  end

  def self.generate_default_email
    email_order_number_array = []
    emails = User.where("email like ?", "%default-%").select("email")
    if (emails.count > 0)
      emails.each do |el|
        email = el.email
        end_index = email.index("@") - 1
        start_index = email.index("-") + 1
        email_order_number = Integer(email[start_index..end_index])
        email_order_number_array << email_order_number
      end
      max_order = email_order_number_array.max + 1
    else
      max_order = 1
    end
    return "default-#{max_order}@example.com"    
  end

  def self.generate_user_display_name user
    if user.email.index("default-")
      display_name = user.phone_number   
    else
      display_name = user.email
    end
    return display_name
  end
end
