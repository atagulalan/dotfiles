function resume
    printf "\ncontinue\n" | claude --resume (cat ~/.last_claude_session)
end