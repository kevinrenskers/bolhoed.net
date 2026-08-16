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

# Delete game posters whose id is no longer listed in games.csv
clean-posters:
	#!/usr/bin/env fish
	set -l ids (tail -n +2 Sources/Bolhoed/csv/games.csv | cut -d ';' -f 1 | tr -d '\r')
	set -l removed 0

	for poster in (find content/static/posters/games -name '*.jpg')
		if not contains -- (basename $poster .jpg) $ids
			echo "Removing $poster"
			rm $poster
			set removed (math $removed + 1)
		end
	end

	echo "Removed $removed poster(s), $(count $ids) games in games.csv"
