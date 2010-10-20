
module Spontaneous
  class Site <  Sequel::Model(:sites)
    class << self
      def map(root_id=nil)
        if root_id.nil?
          Page.root.map_entry
        else
          Content[root_id].map_children
        end
      end

      def root
        Page.root
      end

      def [](path_or_uid)
        case path_or_uid
        when /^\//
          by_path(path_or_uid)
        when /^#/
          by_uid(path_or_uid[1..-1])
        else
          by_uid(path_or_uid)
        end
      end

      def by_path(path)
        Page.path(path)
      end

      def by_uid(uid)
        Page.uid(uid)
      end
   end
  end
end
