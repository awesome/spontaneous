// console.log('Loading BoxView...')

Spontaneous.Views.BoxView = (function($, S) {
	var dom = S.Dom;

	var BoxView = new JS.Class(Spontaneous.Views.View, {
		include: Spontaneous.Properties,

		initialize: function(box, dom_container) {
			this.callSuper(box);
			this.box = box;
			this.dom_container = dom_container;
			this.box.bind('entry_added', this.insert_entry.bind(this));
		},

		name: function() {
			return this.box.name();
		},

		activate: function() {
			$('> .slot-content', this.dom_container).hide();
			this.panel().show();
		},


		mouseover: function() {
			if (this.fields_preview) {
				this.fields_preview.addClass('hover');
			}
		},
		mouseout: function() {
			if (this.fields_preview) {
				this.fields_preview.removeClass('hover');
			}
		},

		panel: function() {
			if (!this._panel) {
				// var panel = $(dom.div, {'class': 'slot-content'});
				var panel = dom.div('.slot-content');
				if (this.box.has_fields()) {
					var w = dom.div('.box-fields');
					var fields = new Spontaneous.FieldPreview(this, '');
					var fields_preview = fields.panel();
					fields_preview.prepend(dom.div('.overlay'))
					var preview_area = this.create_edit_wrapper(fields_preview);

					w.append(preview_area);
					panel.append(w);
					this.fields_preview = fields_preview;
				}

				var allowed = this.box.allowed_types();
				// var allowed_bar = $(dom.div, {'class':'slot-addable'});
				var allowed_bar = dom.div('.slot-addable');
				var dropper = allowed_bar;
				var drop = function(event) {
					dropper.removeClass('drop-active').addClass('uploading');
					// var progress_outer = $(dom.div, {'class':'drop-upload-outer'});
					// var progress_inner = $(dom.div, {'class':'drop-upload-inner'}).css('width', 0);
					// progress_outer.append(progress_inner);
					// dropper.append(progress_outer);
					// this.progress_bar = progress_inner;
					event.stopPropagation();
					event.preventDefault();
					var files = event.dataTransfer.files;
					if (files.length > 0) {
						S.UploadManager.wrap(this, files);
					}
					return false;
				}.bind(this);

				var drag_enter = function(event) {
					// var files = event.originalEvent.dataTransfer.files;
					// console.log(event.originalEvent.dataTransfer, files)
					$(this).addClass('drop-active');
					event.stopPropagation();
					event.preventDefault();
					return false;
				}.bind(dropper);

				var drag_over = function(event) {
					event.stopPropagation();
					event.preventDefault();
					return false;
				}.bind(dropper);

				var drag_leave = function(event) {
					$(this).removeClass('drop-active');
					event.stopPropagation();
					event.preventDefault();
					return false;
				}.bind(dropper);

				dropper.get(0).addEventListener('drop', drop, true);
				dropper.bind('dragenter', drag_enter).bind('dragover', drag_over).bind('dragleave', drag_leave);

				var _box = this;
				$.each(allowed, function(i, type) {
					var a = dom.a().text(type.title), add_allowed;
					if (type.is_alias()) {
						a.addClass('alias')
						add_allowed = function(type) {
							var d = new Spontaneous.AddAliasDialogue(_box, type);
							d.open();
						}.bind(_box, type);
					} else {
						add_allowed = function(type) {
							this.add_content(type, 0);
						}.bind(_box, type);
					}
					a.click(add_allowed);
					allowed_bar.append(a)
				});
				allowed_bar.append(dom.span('.down'));
				panel.append(allowed_bar);
				// var entries = $(dom.div, {'class':'slot-entries'});
				var entries = dom.div('.slot-entries');
				// panel.append();
				for (var i = 0, ee = this.entries(), ii = ee.length;i < ii; i++) {
					var entry = ee[i];
					entries.append(this.claim_entry(entry));
				}
				entries.sortable({
					items:'> .'+this.entry_class(),
					handle: '.title-bar',
					axis:'y',
					distance: 5,
					tolerance: 'pointer',
					scrollSpeed: 40,
					containment: 'parent',
					stop: function(event, ui) {
						this.re_sort(ui.item);
					}.bind(this)
				})
				panel.append(entries);
				panel.hide();
				this.dom_container.append(panel)
				this._panel = panel;
				this._entry_container = entries;
			}
			return this._panel;
		},
		re_sort: function(item) {
			var order = this._entry_container.sortable('toArray'), css_id = item.attr('id'), position = 0;
			for (var i = 0, ii = order.length; i < ii; i++) {
				if (order[i] === css_id) { position = i; break; }
			}
			var id = css_id.split('-')[1], entry;

			for (var i = 0, entries = this.entries(), ii = entries.length; i < ii; i++) {
				if (entries[i].id() == id) { entry = entries[i]; break; }
			}
			entry.reposition(position, function(entry) {
				this.sorted(entry)
			}.bind(this));
		},
		sorted: function(entry) {
		},
		upload_complete: function(values) {
			this.insert_entry(this.wrap_entry(values.entry), values.position);
		},
		upload_progress: function(position, total) {
		},
		entries: function() {
			var entries = [];
			for (var i = 0, ee = this.box.entries(), ii = ee.length;i < ii; i++) {
				var entry = ee[i];
				entries.push(this.view_for_entry(entry));
			}
			return entries;
		}.cache(),

		view_for_entry: function(entry) {
			var view_class = S.Views.PieceView, view, panel;
			if (entry.is_page()) {
				view_class = S.Views.PagePieceView;
			}
			view = new view_class(entry);
			return view;
		},
		claim_entry: function(entry) {
			var div = entry.panel();
			return div.attr('id', this.entry_id(entry)).addClass(this.entry_class());
		},

		entry_id: function(entry) {
			return "entry-" + entry.content.id();
		},

		entry_class: function() {
			return 'container-'+this.box.schema_id();
		},

		save_path: function() {
			return ['/savebox', this.id()].join('/');
		},

		add_content: function(content_type, position) {
			this.box.add_entry(content_type, position);
		},

		add_alias: function(target_id, type) {
			this.box.add_alias(target_id, type);
		},

		insert_entry: function(entry, position) {
			this.trigger('entry_added', entry);
			var entries = this.entries(), w = this.entry_wrappers(), e = this.view_for_entry(entry), h = this.claim_entry(e);
			entries.splice(position, 0, e);
			if (w.length > 0) {
				this.entry_wrappers().slice(position, position+1).before(h);
			} else {
				this._entry_container.append(h);
			}
			h.hide().appear();
		},
		entry_wrappers: function() {
			return this._entry_container.find('> .'+this.entry_class())
		}
	});

	return BoxView;

})(jQuery, Spontaneous);
