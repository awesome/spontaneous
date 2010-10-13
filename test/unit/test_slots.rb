require 'test_helper'


class SlotsTest < Test::Unit::TestCase
  include Spontaneous

  context "Slot containers" do
    setup do
      class ::SlotClass < Content; end
    end

    teardown do
      Object.send(:remove_const, :SlotClass)
    end

    should "start empty" do
      SlotClass.slots.length.should == 0
    end

    should "be definable with a name" do
      SlotClass.slot :images
      SlotClass.slots.length.should == 1
      SlotClass.slots.first.name.should == :images
    end

    should "accept a custom instance class" do
      SlotClass.slot :images, :class => SlotClass
      SlotClass.slots.first.instance_class.should == SlotClass
    end

    should "accept a custom instance class as a string" do
      SlotClass.slot :images, :class => 'SlotClass'
      SlotClass.slots.first.instance_class.should == SlotClass
    end

    should "accept a custom instance class as a symbol" do
      SlotClass.slot :images, :class => :SlotClass
      SlotClass.slots.first.instance_class.should == SlotClass
    end

    should "have 'title' option" do
      SlotClass.slot :images, :title => "Custom Title"
      @instance = SlotClass.new
      @instance.entries.first.slot_name.should == "Custom Title"
    end

    should "allow access to groups of slots" do
      SlotClass.slot :images, :group => :main
      SlotClass.slot :posts, :group => :main
      SlotClass.slot :comments
      SlotClass.slot :last, :group => :main
      @instance = SlotClass.new
      @instance.slots.group(:main).length.should == 3
      @instance.slots.group('main').map {|e| e.label.to_sym }.should == [:images, :posts, :last]
    end

    should "inherit slots from its superclass" do
      SlotClass.slot :images, :group => :main

      @subclass1 = Class.new(SlotClass) do
        slot :monkeys, :group => :main
        slot :apes
      end
      @subclass2 = Class.new(@subclass1) do
        slot :peanuts
      end
      @subclass2.slots.length.should == 4
      @subclass2.slots.map { |s| s.name }.should == [:images, :monkeys, :apes, :peanuts]
    end

    should "default to the name of the slot for the style name" do
      SlotClass.slot :images
      instance = SlotClass.new
      instance.images.style.filename.should == "images.html.erb"
    end
    should "accept a custom template name" do
      SlotClass.slot :images, :style => :anonymous_slot
      instance = SlotClass.new
      instance.images.style.filename.should == "anonymous_slot.html.erb"
    end

    should "take template path from slot's parent for anonymous slots" do
      SlotClass.slot :images, :style => :anonymous_slot
      SlotClass.slot :posts
      instance = SlotClass.new
      instance.images.style.path.should == "#{Spontaneous.template_root}/slot_class/anonymous_slot.html.erb"
      instance.posts.style.path.should == "#{Spontaneous.template_root}/slot_class/posts.html.erb"
    end

    context "" do
      setup do
        SlotClass.slot :images
        @instance = SlotClass.new
      end

      should "provide a test for existance of named slot" do
        @instance.slot?(:images).should be_true
        @instance.slot?(:none).should be_false
      end

      should "instantiate a corresponding facet in new instances" do
        @instance.entries.length.should == 1
        # @instance.entries.first.class.should == Facet
        @instance.entries.first.label.should == "images"
        @instance.entries.first.slot_name.should == "Images"
      end

      should "have a #slots method for accessing slots" do
        @instance.slots.length.should == 1
        @instance.slots.first.label.should == "images"
        @instance.slots.first.slug.should == "images"
        @instance.slots[:images].should == @instance.slots.first
      end

      should "have shortcut methods for accessing slots by name" do
        @instance.slots.images.should == @instance.slots.first
        @instance.images.should == @instance.slots.first
      end

      should "persist slots" do
        @instance.save
        @instance = SlotClass[@instance.id]
        @instance.slots.length.should == 1
        @instance.slots.first.label.should == "images"
        @instance.slots[:images].should == @instance.slots.first
        @instance.slots.images.should == @instance.slots.first
        @instance.images.should == @instance.slots.first
      end

      should "update list of slots on instance if slot added after creation" do
        @instance.save
        SlotClass.slot :posts
        @instance = SlotClass[@instance.id]
        @instance.slots.length.should == 2
        @instance.slots.first.label.should == "images"
        @instance.slots.last.label.should == "posts"
        @instance.slots[:images].should == @instance.slots.first
        @instance.slots[:posts].should == @instance.slots.last
        @instance.slots.images.should == @instance.slots.first
        @instance.slots.posts.should == @instance.slots.last
        @instance.images.should == @instance.slots.first
        @instance.posts.should == @instance.slots.last
      end
      
      ## waiting on entry deletion routines
      should "update list of slots on instance if slot removed after creation"
      # should "update list of slots on instance if slot removed after creation" do
      #   @instance.save
      #   SlotClass.slot :posts
      #   @instance = SlotClass[@instance.id]
      #   @instance.slots.length.should == 2
      #   SlotClass.slots.shift
      #   p SlotClass.slots
      #   @instance = SlotClass[@instance.id]
      #   @instance.slots.length.should == 1
      #   @instance.slots.first.label.should == "posts"
      #   @instance.slots[:posts].should == @instance.slots.first
      #   @instance.slots.posts.should == @instance.slots.first
      #   @instance.posts.should == @instance.slots.first
      # end
    end
  end
end
