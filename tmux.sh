#!/bin/bash

# لیست تمامی جلسات tmux
sessions=$(tmux list-sessions -F "#S")

# نمایش لیست جلسات با شماره‌گذاری
echo "لیست جلسات tmux:"
i=1
for session in $sessions; do
    echo "$i) $session"
    i=$((i + 1))
done

# درخواست شماره جلسه برای حذف
read -p "شماره جلسه‌ای که می‌خواهید حذف کنید را وارد کنید: " session_number

# پیدا کردن نام جلسه بر اساس شماره وارد شده
i=1
for session in $sessions; do
    if [ $i -eq $session_number ]; then
        tmux kill-session -t "$session"
        echo "جلسه $session حذف شد."
        break
    fi
    i=$((i + 1))
done
