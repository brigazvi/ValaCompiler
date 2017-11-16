/***
  BEGIN LICENSE
  Copyright (C) 2017 Basem Kheyar<basjam@gmail.com>
  This program is free software: you can redistribute it and/or modify it
  under the terms of the GNU Lesser General Public License version 3, as
  published by the Free Software Foundation.

  This program is distributed in the hope that it will be useful, but
  WITHOUT ANY WARRANTY; without even the implied warranties of
  MERCHANTABILITY, SATISFACTORY QUALITY, or FITNESS FOR A PARTICULAR
  PURPOSE.  See the GNU General Public License for more details.
  You should have received a copy of the GNU General Public License along
  with this program.  If not, see <http://www.gnu.org/licenses>
  END LICENSE
***/

namespace ValaCompiler.Widgets {
    public class ReportPage : Gtk.Box {

        public Gtk.Stack report_stack;
        public Gtk.TextView compile_report;
        public Gtk.TextView test_report;
        public string compile_report_string;
        public string test_report_string;
        public Granite.Widgets.ModeButton view_button;
        public Utils.ValaC valac;
        public Utils.AppTester app_tester;
        public bool test_available;
        public Gtk.Box bottom_box;
        public Gtk.Button clear_button;
        public string clear_target;

        construct {
            this.orientation = Gtk.Orientation.VERTICAL;
            this.spacing = 2;
            this.margin = 6;

            //Granite.Widgets.ModeButton setup
            view_button = new Granite.Widgets.ModeButton ();
            view_button.append_text (_("Compile Report"));
            view_button.append_text (_("Live Test Report"));
            view_button.halign = Gtk.Align.CENTER;

            //Reports View setup
            compile_report_string = "";
            test_report_string = "";

            compile_report = new Gtk.TextView ();
            compile_report.monospace = true;
            compile_report.editable = false;
            compile_report.buffer.text = compile_report_string;

            test_report = new Gtk.TextView ();
            test_report.monospace = true;
            test_report.editable = false;
            test_report.buffer.text = test_report_string;

            var compile_scroll = new Gtk.ScrolledWindow (null, null);
            compile_scroll.add (compile_report);

            var compile_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 2);
            compile_box.pack_start (compile_scroll, true, true, 0);

            var test_scroll = new Gtk.ScrolledWindow (null, null);
            test_scroll.add (test_report);

            report_stack = new Gtk.Stack ();
            report_stack.transition_type = Gtk.StackTransitionType.SLIDE_LEFT_RIGHT;
            report_stack.add_named (compile_box, "compile");
            report_stack.add_named (test_scroll, "test");

            //setup bottom_box
            clear_target = "compile";
            clear_button = new Gtk.Button.from_icon_name ("edit-clear", Gtk.IconSize.LARGE_TOOLBAR);
            clear_button.tooltip_text = _("Clear Compile Report");
            bottom_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6);
            bottom_box.pack_end (clear_button, false, false, 0);

            //add stuff to Report Page
            this.pack_start (view_button,false, false, 0);
            this.pack_start (report_stack, true, true, 0);
            this.pack_end (bottom_box, false, false, 0);
            //Setup event listeners
            view_button.mode_changed.connect (() => {
                switch (view_button.selected) {
                    case 0:
                        report_stack.set_visible_child_full ("compile", Gtk.StackTransitionType.SLIDE_RIGHT);
                        clear_button.tooltip_text = _("Clear Compile Report");
                        clear_target = "compile";
                        break;
                    case 1:
                        report_stack.set_visible_child_full ("test", Gtk.StackTransitionType.SLIDE_LEFT);
                        clear_button.tooltip_text = _("Clear Test Report");
                        clear_target = "test";
                        break;
                };
            });

            test_available = false;
            valac = Utils.ValaC.get_instance ();
            valac.compile_line_out.connect ((line) => {
                if (line.strip ().contains ("Compilation succeeded")) {
                    test_available = true;
                } else if (line.strip ().contains ("Compilation failed")) {
                    test_available = false;
                };
                compile_report_string += line.to_string ();
                refresh ();
            });

            app_tester = Utils.AppTester.get_instance ();
            app_tester.test_line_out.connect ((line) => {
                test_report_string += line.to_string ();
                refresh ();
            });

            clear_button.clicked.connect (() => {
                switch (clear_target) {
                    case "compile":
                        compile_report_string = "";
                        refresh ();
                        break;
                    case "test":
                        test_report_string = "";
                        refresh ();
                        break;
                };
            });
        }

        public void refresh () {
            test_report.buffer.text = test_report_string;
            compile_report.buffer.text = compile_report_string;
        }

        public void clear_compile_report () {
            compile_report_string = "";
            refresh ();
        }

        public void clear_test_report () {
            test_report_string = "";
            refresh ();
        }
    }
}
