module Carddav
  class PrincipalResource < BaseResource

    ALL_PROPERTIES =  {}

    EXPLICIT_PROPERTIES = { 
      'DAV:' => %w(
        alternate-URI-set
        group-membership
        group-membership-set
      ),
      'urn:ietf:params:xml:ns:carddav' => %w(
        addressbook-home-set
        principal-address
      )
    }

    def exist?
      ret = (path == '')
      STDERR.puts "*** Principal::exist?(#{path}) = #{ret}"
      return ret
    end

    def collection?
      return true
    end
    
    def children
      []
    end

    ## Properties follow in alphabetical order
    protected

    # We should muck about in the routes and figure out the proper path
    def addressbook_home_set
      s="<C:addressbook-home-set xmlns:C='urn:ietf:params:xml:ns:carddav'><D:href xmlns:D='DAV:'>/book/</D:href></C:addressbook-home-set>"
      Nokogiri::XML::DocumentFragment.parse(s)
    end

    def alternate_uri_set
      s="<D:alternate-URI-set xmlns:D='DAV:' />"
      Nokogiri::XML::DocumentFragment.parse(s)
    end

    def creation_date
      # TODO: There's probably a more efficient way to grab the oldest ctime
      # Perhaps we should assume that the address book will never be newer than
      # any of its constituent contacts?
      contact_ids = AddressBook.find_all_by_user_id(current_user.id).collect{|ab| ab.contacts.collect{|c| c.id}}.flatten
      Field.first(:order => 'created_at ASC', :conditions => ['contact_id IN (?)', contact_ids]).created_at
    end

    def displayname
      "#{current_user.username}'s Principal Resource"
    end

    def group_membership
      s="<D:group-membership xmlns:D='DAV:' />"
      Nokogiri::XML::DocumentFragment.parse(s)
    end

    def group_membership_set
      s="<D:group-membership-set xmlns:D='DAV:' />"
      Nokogiri::XML::DocumentFragment.parse(s)
    end

    def last_modified
      address_books = AddressBook.find_all_by_user_id(current_user.id)
      contact_ids = address_books.collect{|ab| ab.contacts.collect{|c| c.id}}.flatten
      field = Field.first(:order => 'updated_at DESC', :conditions => ['contact_id IN (?)', contact_ids])
      return field.updated_at unless field.nil?
      return address_books.first.updated_at unless address_books.nil?
      Time.now
    end

    # For legibility let's underscore it and let the supeclass call it
    def resource_type
      s='<resourcetype><D:collection /><D:principal/></resourcetype>'
      return Nokogiri::XML::DocumentFragment.parse(s)
    end

  end
end