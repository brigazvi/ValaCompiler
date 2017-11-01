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

namespace ValaCompiler.Utils {

    public class ValaC {

        public signal void compiling_line_out (string line);
        public signal void compiling_done ();


        public static ValaC instance = null;
        public static ValaC get_instance () {
            if (instance == null) {
                instance = new ValaC ();
            };

            return instance;
        }


        public async void compile_files (string location, string[] files) {

            try {
                string[] spawn_args = {"valac", "--pkg=gtk+-3.0", "--pkg=granite", "-X", "-w"};
                foreach (string file in files) {
                    spawn_args += file;
                };
                string[] spawn_env = Environ.get ();
                Pid child_pid;

                int standard_input;
                int standard_output;
                int standard_error;

                Process.spawn_async_with_pipes (
                    location,
                    spawn_args,
                    spawn_env,
                    SpawnFlags.SEARCH_PATH | SpawnFlags.DO_NOT_REAP_CHILD,
                    null,
                    out child_pid,
                    out standard_input,
                    out standard_output,
                    out standard_error);


                    IOChannel output = new IOChannel.unix_new (standard_input);
                    output.add_watch (IOCondition.IN | IOCondition.HUP, (channel, condition) => {
                        return process_line (channel, condition, "stdout");
                    });

                    IOChannel error = new IOChannel.unix_new (standard_error);
                    error.add_watch (IOCondition.IN | IOCondition.HUP, (channel, condition) => {
                        return process_line (channel, condition, "stderr");
                    });

                    ChildWatch.add (child_pid, (pid, status) => {
                        Process.close_pid (pid);
                    });
            } catch (SpawnError e) {
                stdout.printf ("Error:  %s\n", e.message);
            }

            return;
        }

        public bool process_line (IOChannel channel, IOCondition condition, string stream_name) {
            if (condition == IOCondition.HUP) {
                if (stream_name == "stdout"){
                    //compiling done
                    compiling_done();
                };

                return false;
            }

            try {
                string line;
                channel.read_line (out line, null, null);
                //compiling_line_out ();
                print ("ValaC: " + stream_name + ": " + line );
            } catch (IOChannelError e) {
                stdout.printf ("%s: IOChannelError: %s\n", stream_name, e.message);
            } catch (ConvertError e) {
                stdout.printf ("%s: ConvertError: %s\n", stream_name, e.message);
            }
        return true;
        }

    }
}