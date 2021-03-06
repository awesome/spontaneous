
module Spontaneous::Output::Template
  # Renderers are responsible for creating contexts from objects & passing these
  # onto the right template engine
  # You only have one renderer instance per spontaneous role:
  #
  #   - editing/previewing : PreviewRenderer
  #   - publishing         : PublishRenderer
  #   - the live site      : PublishedRenderer
  #
  # these should be shared between requests/renders so that the
  # caching can be effective

  class Renderer
    def initialize(site, cache = Spontaneous::Output.cache_templates?)
      @site  = site
      @cache = cache
    end

    def render(output, params = {}, parent_context = nil)
      output.model.with_visible do
        engine.render(output.content, context(output, params, parent_context), output.name)
      end
    end

    def render_string(template_string, output, params = {}, parent_context = nil)
      output.model.with_visible do
        engine.render_string(template_string, context(output, params, parent_context), output.name)
      end
    end

    def context(output, params, parent)
      context_class(output).new(Spontaneous::Output::Renderable.new(output.content), params, parent).tap do |context|
        context.site = @site
        context._renderer = renderer_for_context
      end
    end

    def renderer_for_context
      self
    end

    def context_class(output)
      if Spontaneous.development?
        generate_context_class(output)
      else
        context_cache[output.name] ||= generate_context_class(output)
      end
    end

    def context_cache
      @context_cache ||= {}
    end

    def generate_context_class(output)
      site = @site
      context_class = Class.new(Spontaneous::Output.context_class) do
        include Spontaneous::Output::Context::ContextCore
        include output.context(site)
      end
      context_extensions.each do |mod|
        context_class.send :include, mod
      end
      context_class
    end

    def context_extensions
      []
    end

    def write_compiled_scripts=(state)
    end

    def template_exists?(template, format)
      engine.template_exists?(template, format)
    end

    def template_location(template, format)
      engine.template_location(template, format)
    end

    def is_dynamic_template?(template_string)
      second_pass_engine.dynamic_template?(template_string)
    end

    def is_model?(klass)
      klass < @site.model
    end

    def engine
      @engine ||= create_engine(:PublishEngine)
    end

    def second_pass_engine
      @second_pass_engine ||= create_engine(:RequestEngine)
    end

    def create_engine(engine_class, template_roots = @site.paths(:templates))
      Spontaneous::Output::Template.const_get(engine_class).new(template_roots, @cache)
    end
  end

  class PublishRenderer < Renderer
    def initialize(site, cache = Spontaneous::Output.cache_templates?)
      super
      Thread.current[:_render_cache] = {}
    end

    def render_cache
      Thread.current[:_render_cache]
    end

    # Disabled for moment
    def write_compiled_scripts=(state)
      engine.write_compiled_scripts = false # state
    end

    def context_extensions
      [Spontaneous::Output::Context::PublishContext]
    end
  end

  class RequestRenderer < Renderer
    def engine
      @engine ||= create_engine(:RequestEngine)
    end
  end

  class PublishedRenderer < Renderer
    def initialize(site, revision, cache = Spontaneous::Output.cache_templates?)
      super(site, cache)
      @revision = revision
      @template_store = @site.template_store.revision(@revision)
    end

    def render(output, params = {}, parent_context = nil)
      render!(output, params, parent_context)
    rescue Cutaneous::UnknownTemplateError => e
      render_on_demand(output, params, parent_context)
    end

    def render!(output, params, parent_context)
      if (template = @template_store.static_template(output))
        return template
      end
      # Attempt to render a published template
      if (template = @template_store.dynamic_template(output))
        return engine.render_template(template, context(output, params, parent_context), output.name)
      end
      logger.warn("missing template for #{output}")
      render_on_demand(output, params, parent_context)
    end

    def render_on_demand(output, params, parent_context)
      template = publish_renderer.render(output, params)
      render_string(template, output, params)
    end

    def engine
      @engine ||= create_engine(:RequestEngine, revision_root)
    end

    def publish_renderer
      @publish_renderer ||= PublishRenderer.new(@site)
    end

    def revision_root
      [@site.revision_dir(@revision)/ "dynamic"]
    end
  end

  class PreviewRenderer < Renderer
    def render(output, params = {}, parent_context = nil)
      rendered = super(output)
      request_renderer.render_string(rendered, output, params, parent_context)
    end

    def render_string(template_string, output, params = {}, parent_context = nil)
      rendered = super(template_string, output)
      request_renderer.render_string(rendered, output, params, parent_context)
    end

    def renderer_for_context
      @renderer_for_context ||= PublishRenderer.new(@site, @cache)
    end

    def request_renderer
      @request_renderer ||= RequestRenderer.new(@site, @cache)
    end
  end
end
