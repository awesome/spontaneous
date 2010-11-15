console.log('Loading Page...')

Spontaneous.Page = (function($, S) {
	var dom = S.Dom, Slot = S.Slot;

	var FunctionBar = function(page) {
		this.page = page;
	};
	FunctionBar.prototype = {
		panel: function() {
			this.panel = $(dom.div, {'id': 'page-info'});
			this.panel.append($('<h1/>').text(this.page.title()))
			var path_wrap = $(dom.div, {'class':'path'})

			path_wrap.append($('<h3/>').text(this.page.path).click(function() {
				if (this.page.path !== '/') {
					this.open_url_editor();
				}
			}.bind(this)));
			path_wrap.append($(dom.div, {'class':'edit'}));
			this.panel.append(path_wrap);
			this.path_wrap = path_wrap
			return this.panel;
		},
		unavailable_loaded: function(response) {
			var u = {};
			for (var i = 0, ii = response.length; i < ii; i++) {
				u[response[i]] = true;
			}
			this.unavailable = u;
		},
		open_url_editor: function() {
			this.unavailable = false;
			Spontaneous.Ajax.get(['/slug', this.page.id(), 'unavailable'].join('/'), this, this.unavailable_loaded);
			this.panel.animate({'height': '+=14'}, 200, function() {
				var view = $('h3', this.panel), edit = $('.edit', this.panel);
				view.hide();
				edit.hide().empty();
				var path = [""], parts = this.page.path.split('/'), slug = parts.pop();
				parts.shift(); // remove empty entry caused by leading '/'
				edit.append($(dom.span).text('/'))
				for (var i = 0, ii = parts.length; i < ii; i++) {
					var p = parts[i];
					path.push(p)
					edit.append($(dom.a, {'class':'path'}).text(p).attr('href', path.join('/')).click(function() {
						S.Location.load_path($(this).attr('href'));
						return false;
					}));
					edit.append($(dom.span).text('/'));
				}
				var input_and_error = $(dom.span, {'class':'input-error'});
				var input = $(dom.input, {'type':'text', 'autofocus':'autofocus'}).val(slug).select();
				var error = $(dom.span).text('Duplicate URL').hide();
				input_and_error.append(input);
				input_and_error.append(error);
				edit.append(input_and_error);
				var submit = function() {
					// TODO: test url for uniqueness
					// if it's safe then save it
					this.save(input.val());
				}.bind(this);
				edit.append($(dom.a, {'class':'button'}).text('Save').click(submit));
				input.keyup(function(event) {
					if (event.keyCode === 13) {
						submit();
					} else {
						var v = this.input.val();
						// do some basic cleanup -- proper cleanup is done on the server-side
						v = v.toLowerCase().replace(/['"]/g, '');
						v = v.replace(/[^\w0-9+]/g, '-').replace(/(\-+|\s+)/g, '-').replace(/(^\-)/, '');
						this.input.val(v);
						if (v === '') {
								this.show_path_error('Invalid URL');
						} else {
							if (this.unavailable[v]) {
								this.show_path_error();
							} else {
								this.hide_path_error();
							}
						}
					}
					// if (event.keyCode === 27) { this.close(); }
				}.bind(this));
				this.input = input;
				this.error = error;
				edit.fadeIn(200);
			}.bind(this));
		},
		show_path_error: function(error_text) {
			error_text = (error_text || "Duplicate URL");
			this.error.text(error_text).fadeIn(100);
			this.input.addClass('error');
		},
		hide_path_error: function(error_text) {
			this.error.fadeOut(100);
			if (this.input.hasClass('error')) { this.input.removeClass('error'); }
		},
		save: function(slug) {
			Spontaneous.Ajax.post('/slug/'+this.page.id(), {'slug':slug}, this, this.save_complete);
		},
		save_complete: function(response, status, xhr) {
			console.warn('FunctionBar.save_complete', response, status, xhr)
			if (status === 'success') {
				this.hide_path_error();
				var view = $('h3', this.panel), edit = $('.edit', this.panel);
				this.page.path = response.path;
				view.text(response.path);
				this.close();
			} else {
				if (xhr.status === 409) { // duplicate path
					console.warn('FunctionBar.save_complete', 'duplicate', status)
					this.show_path_error();
				}
			}
		},
		close: function() {
			var view = $('h3', this.panel), edit = $('.edit', this.panel);
			view.show();
			edit.hide();
			this.panel.animate({'height': '-=14'}, 200)
		}
	};
	var Page = new JS.Class(Spontaneous.Content, {
		initialize: function(content) {
			this.callSuper(content);
			this.path = content.path;
		},
		title: function() {
			return this.fields().title.value();
		},
		panel: function() {
			this.panel = $(dom.div, {'id':'page-content'});
			this.panel.append(new FunctionBar(this).panel());
			this.panel.append(new Spontaneous.FieldPreview(this, 'page-fields').panel());
			this.panel.append(new Spontaneous.SlotContainer(this, 'page-slots').panel());
			return this.panel;
		},
		depth: function() {
			// depth in this case refers to content depth which is always 0 for pages
			return 0;
		}
	});

	return Page;
}(jQuery, Spontaneous));
