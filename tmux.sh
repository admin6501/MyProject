#!/bin/bash

# List all tmux sessions
sessions=$(tmux list-sessions -F "#S")

# Display the list of sessions with numbering
echo "List of tmux sessions:"
i=1
for session in $sessions; do
    echo "$i) $session"
    i=$((i + 1))
done

# Request the session number to delete
read -p "Enter the session number you want to delete: " session_number

# Find the session name based on the entered number
i=1
for session in $sessions; do
    if [ $i -eq $session_number ]; then
        tmux kill-session -t "$session"
        echo "Session $session has been deleted."
        break
    fi
    i=$((i + 1))
done
