function at
    set target "$argv[1]" # örn: 18:10

    while true
        set now (date +%s)
        set end (date -d "$target" +%s)

        if test $end -le $now
            set end (date -d "tomorrow $target" +%s)
        end

        set diff (math $end - $now)

        printf "\r⏳ %02d:%02d:%02d" \
            (math -s0 "$diff/3600") \
            (math -s0 "($diff%3600)/60") \
            (math "$diff%60")

        if test $diff -le 1
            sleep 1
            printf "\r⏳ Time's up!"
            break
        end

        sleep 1
    end

    echo
end