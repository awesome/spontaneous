require 'test_helper'


class RenderTest < Test::Unit::TestCase
  include Spontaneous

  def template_root
    @style_root ||= File.expand_path(File.join(File.dirname(__FILE__), "../fixtures/templates"))
  end

  context "Content objects" do
    setup do
      Spontaneous.template_root = template_root
      class ::TemplateClass < Content
        field :title do
          def to_epub
            to_html
          end
        end
        field :description do
          def to_pdf
            "{#{value}}"
          end
          def to_epub
            to_html
          end
        end

        inline_style :this_template
        inline_style :another_template
      end
      @content = TemplateClass.new
      @content.style.should == TemplateClass.styles.default
      @content.title = "The Title"
      @content.description = "The Description"
    end

    teardown do
      Object.send(:remove_const, :TemplateClass)
    end


    should "be able to render themselves to HTML" do
      @content.render.should == "<html><title>The Title</title><body>The Description</body></html>\n"
    end

    should "be able to render themselves to PDF" do
      @content.render(:pdf).should == "<PDF><title>The Title</title><body>{The Description}</body></PDF>\n"
    end
    should "be able to render themselves to EPUB" do
      @content.render(:epub).should == "<EPUB><title>The Title</title><body>The Description</body></EPUB>\n"
    end

    context "facet trees" do
      setup do
        TemplateClass.inline_style :complex_template, :default => true
        @content = TemplateClass.new
        @content.title = "The Title"
        @content.description = "The Description"
        @child = TemplateClass.new
        @child.title = "Child Title"
        @child.description = "Child Description"
        @content << @child
        @content.entries.first.style = TemplateClass.styles[:this_template]
      end

      should "be accessible through #content method" do
        @content.render.should == <<-HTML
<complex>
The Title
<facet><html><title>Child Title</title><body>Child Description</body></html>
</facet>
</complex>
        HTML
      end
      should "cascade the chosen format to all subsequent #render calls" do
        @content.render(:pdf).should == <<-PDF
<pdf>
The Title
<facet><PDF><title>Child Title</title><body>{Child Description}</body></PDF>
</facet>
</pdf>
        PDF
      end
    end
  end
end
