
[GtkTemplate (ui = "/io/github/daudix/Memo/notebooks_bar.ui")]
public class Memo.NotebooksBar : Gtk.Box {

    public bool paned { get; set; default = false; }

	public bool all_button_enabled {
	    set { all_button_revealer.reveal_child = value; }
	}

	[GtkChild] unowned Gtk.ListView list;
	[GtkChild] unowned Gtk.ToggleButton all_button;
	[GtkChild] unowned Gtk.Revealer all_button_revealer;
	[GtkChild] unowned Gtk.ToggleButton trash_button;
	[GtkChild] unowned Adw.HeaderBar header_bar;
	[GtkChild] unowned Adw.WindowTitle window_title;
	[GtkChild] unowned Gtk.ScrolledWindow scrolled_window;

	private WindowModel window_model;

	private Gtk.ListItemFactory item_factory;

	private Gtk.ListItemFactory item_factory_paned;

	construct {
	    all_button_revealer.notify["child-revealed"].connect (update_scroll);
        scrolled_window.vadjustment.notify["value"].connect (update_scroll);
        update_scroll ();

	    var settings = new Settings (Config.APP_ID);
	    settings.bind ("enable-3-pane", this, "paned", SettingsBindFlags.DEFAULT);

	    window_title.title = Strings.APP_NAME;

	    notify["paned"].connect (() => {
	        if (paned) get_style_context ().add_class ("paned");
	        else get_style_context ().remove_class ("paned");
		    list.factory = paned ? item_factory_paned : item_factory;
	    });
	}

	private void update_scroll () {
        var v = scrolled_window.vadjustment.value;

        if (v == scrolled_window.vadjustment.lower) header_bar.get_style_context ().remove_class ("overlaid");
        else header_bar.get_style_context ().add_class ("overlaid");

        if (v >= scrolled_window.vadjustment.upper - scrolled_window.get_allocated_height ()) trash_button.get_style_context ().remove_class ("overlaid");
        else trash_button.get_style_context ().add_class ("overlaid");
	}

	public void init (Window window) {
	    this.window_model = window.window_model;
        {
            var factory = new Gtk.SignalListItemFactory ();
            factory.setup.connect (list_item => {
                var widget = new NotebookIcon (window);
                list_item.child = widget;
            });
            factory.bind.connect (list_item => {
                var widget = list_item.child as NotebookIcon;
                var item = list_item.item as Notebook;
                widget.notebook = item;
            });
            item_factory = factory;
        }
        {
            var factory = new Gtk.SignalListItemFactory ();
            factory.setup.connect (list_item => {
                var widget = new NotebookSidebarItem (window);
                list_item.child = widget;
            });
            factory.bind.connect (list_item => {
                var widget = list_item.child as NotebookSidebarItem;
                var item = list_item.item as Notebook;
                widget.notebook = item;
            });
            item_factory_paned = factory;
        }
		list.factory = paned ? item_factory_paned : item_factory;

		trash_button.toggled.connect (() => {
            trash_button.sensitive = !trash_button.active;
            if (trash_button.active) {
                window_model.select_notebook (null);
                window_model.set_trash (window_model.notebook_provider.trash);
            }
        });
		all_button.toggled.connect (() => {
            all_button.sensitive = !all_button.active;
            if (all_button.active) {
                window_model.select_notebook (null);
                window_model.set_all ();
            }
        });

		window_model.notify["notebooks-model"].connect (on_notebooks_updated);
		on_notebooks_updated ();
	}

	private void on_notebooks_updated () {
	    window_model.notebooks_model.selection_changed.connect (() => {
	        var i = window_model.notebooks_model.selected;
	        var notebooks = window_model.notebook_provider.notebooks;
	        if (i <= notebooks.size && i != -1) {
	            trash_button.active = false;
	            all_button.active = false;
	        }
	    });
	    list.model = window_model.notebooks_model;

	    if (window_model.notebook_provider.notebooks.size != 0) {
	        window_model.notebooks_model.selection_changed (0, 1);
	    }
	}
}
