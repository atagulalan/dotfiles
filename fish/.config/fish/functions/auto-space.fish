function auto-space --description 'Tap SPACE on the nano-grab target every N seconds (default 10)'
    set -l interval 10
    test (count $argv) -ge 1; and set interval $argv[1]
    while true
        echo (date +%T) ($HOME/Documents/nano-grab/target/debug/nano-grab --json keyboard tap SPACE)
        sleep $interval
    end
end
