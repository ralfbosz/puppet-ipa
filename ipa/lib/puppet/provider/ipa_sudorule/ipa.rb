################################################################################
#
# puppet/provider/ipa_sudorule/ipa.rb
#
# Copyright 2013-2015 jonuwz (https://github.com/jonuwz)
#
# See LICENSE.md for Licensing.
#
################################################################################
require 'puppet/util/ipajson'
require 'puppet/provider/ipabase'

Puppet::Type.type(:ipa_sudorule).provide(:ipa, :parent => Puppet::Provider::IPAbase) do

  mk_resource_methods
  @ipa_resource=:sudorule

  class << self
    alias_method :super_get_def, :get_def

    def get_def(instance)
      properties=super_get_def(instance)
      [:anyuser,:anyhost,:anycommand,:anyrunasuser,:anyrunasgroup].each do |cat|
        properties[cat] ||= :false
        properties[cat]   = :true if properties[cat] =='all'
      end
      properties
    end

  end

  def add_instance
    ipa.sudorule.add(@resource[:name],{ :description => @resource[:description] })
    mods = {}
    [:user,:host,:allow_command,:deny_command,:runasuser,:runasgroup].each do |type|

      single = "#{type}s".to_sym
      group  = "#{type}groups".to_sym
      cat    = "any#{type}".to_sym
      cat    = :anycommand if [:allow_command,:deny_command].include?(type)

      modify_members(single,@resource[single],[]) if @resource[single]
      modify_members(group, @resource[group],[])  if @resource[group]
      mods[cat] = 'all' if @resource[cat]==:true

    end
    mods[options] = @resource[options] if @resource[options]
    ipa.sudorule.mod(@resource[:name],mods) if ! mods.empty?

  end

  def del_instance
    ipa.sudorule.del(@resource[:name])
  end

  def modify_members(property,members,current_members)

     method="#{property}".sub(/s$/,'')
     add_members = []
     del_members = []

     Array(members).each do |member|
        add_members << member unless current_members.include?(member)
      end
      current_members.each do |member|
        del_members << member unless members.include?(member)
      end

      ipa.sudorule.send("add_#{method}".to_sym, @resource[:name],add_members) if !add_members.empty?
      ipa.sudorule.send("remove_#{method}".to_sym, @resource[:name],del_members) if !del_members.empty?
      @property_flush.delete(property)

  end
 
  
  def mod_instance

    # arses.
    # when user/service/hostcategory = all, then you have to delete all the relevant user/service/group definitions in IPA
    # sanest thing to do is overwrite the should values for the user/host/group contents with []
    # then the user can just remove the user/host/servicecategory = all from he manifest and get hte old settings back

    [:user,:host,:allow_command,:deny_command,:runasuser,:runasgroup].each do |type|
    
      single = "#{type}s".to_sym
      group  = "#{type}groups".to_sym
      cat    = "any#{type}".to_sym
      cat    = :anycommand if [:allow_command,:deny_command].include?(type)

      # future state is all = true. We need to wipe the single/group properties before applying the 'all setting'
      # the type itself looks after overriding the single/group
      if ( !@property_flush.has_key?(cat) and @property_hash[cat] == :true) or @property_flush[cat]==:true

        modify_members(single,@property_flush[single],@property_hash[single]) if @property_flush.has_key?(single)
        modify_members(group, @property_flush[group],@property_hash[group])  if @property_flush.has_key?(group)
        ipa.sudorule.mod(@resource[:name],{ cat => 'all' }) if @property_flush[cat]==:true
        

      # future state is all = false and requires a change to 'all' setting before applying single/group membership
      elsif @property_flush.has_key?(cat) and @property_hash[cat] == :true

        ipa.sudorule.mod(@resource[:name],{ cat => '' }) if @property_flush[cat]==:false
        modify_members(single,@property_flush[single],@property_hash[single]) if @property_flush.has_key?(single)
        modify_members(group ,@property_flush[group],@property_hash[group])  if @property_flush.has_key?(group)

      # just flush the single/group members
      else
  
        modify_members(single,@property_flush[single],@property_hash[single]) if @property_flush.has_key?(single)
        modify_members(group ,@property_flush[group],@property_hash[group])  if @property_flush.has_key?(group)

      end

    end

    ipa.sudorule.mod(@resource[:name],{ :description => @property_flush[:description]}) if @property_flush.has_key?(:description)
    ipa.sudorule.mod(@resource[:name],{ :options => @property_flush[:options]}) if @property_flush.has_key?(:options)

  end
  
end
