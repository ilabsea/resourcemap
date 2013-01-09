module ApplicationHelper
  include KnockoutHelper

  def google_maps_javascript_include_tag
    javascript_include_tag(raw("http://maps.googleapis.com/maps/api/js?sensor=false&key=#{GoogleMapsKey}&v=3.9"))
  end

  def collection_admin?
    @collection_admin = current_user.admins?(collection) if @collection_admin.nil?
    @collection_admin
  end

  def render_plugin_hook(plugin, name, args = {})
    result = ''
    plugin.hooks[name].each do |view|
      result << render(view, args)
    end
    result.html_safe
  end

  def render_hook(collection, name, args = {})
    result = ''
    collection.each_plugin do |plugin|
      result << render_plugin_hook(plugin, name, args)
    end
    result.html_safe
  end

  def field_edit_view(kind)
    Field::PluginKinds.has_key?(kind) ? Field::PluginKinds[kind][:edit_view] : "collections/fields/#{kind}_edit_view"
  end

  def all_icons
    [:pin, :airplane, :anchor, :anthenna, :baby, :balance, :barn, :bell, :biohazard, :boat, :bookmark, :box_icon, :bug, :building, :bus, :car, :clark, :cog, :dog, :drop, :envelope, :factory, :family, :faucet, :fire, :flag, :gas_pump, :group, :hand_truck, :helicopter, :hospital, :house, :key, :medical_kit, :mortarboard, :mountain, :notebook, :pine, :police, :pregnant, :recycle, :robot, :shopping_cart, :signpost, :subway, :swing, :syringe, :tag, :tent, :test, :train, :trashbin, :truck, :tunnel, :wheat, :wifi]
  end
end
