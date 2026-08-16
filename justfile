run:
	#!/usr/bin/env fish
	./server.py &
	set -l server_pid $last_pid
	saga dev &
	set -l saga_pid $last_pid

	# Ctrl-C, or either process exiting, takes the whole group down
	function _cleanup --on-signal INT --on-signal TERM \
			--on-process-exit $server_pid --on-process-exit $saga_pid
		kill 0
	end

	wait
