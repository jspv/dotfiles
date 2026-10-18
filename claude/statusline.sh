#!/bin/sh
# Claude Code status line. Line 1: model | ctx | branch | path. Line 2: session stats and limits.
input=$(cat)
j() { printf '%s' "$input" | jq -r "$1 // empty"; }

cwd=$(j '.workspace.current_dir // .cwd')
model=$(j '.model.display_name')
used=$(j '.context_window.used_percentage')
add=$(j '.cost.total_lines_added')
del=$(j '.cost.total_lines_removed')
h5=$(j '.rate_limits.five_hour.used_percentage')
h5r=$(j '.rate_limits.five_hour.resets_at')
d7=$(j '.rate_limits.seven_day.used_percentage')
d7r=$(j '.rate_limits.seven_day.resets_at')

branch=$(git -C "$cwd" --no-optional-locks symbolic-ref --short HEAD 2>/dev/null || git -C "$cwd" --no-optional-locks rev-parse --short HEAD 2>/dev/null)
top=$(git -C "$cwd" --no-optional-locks rev-parse --show-toplevel 2>/dev/null)
if [ -n "$top" ]; then dir="${top##*/}${cwd#"$top"}"
else dir="$cwd"; case "$dir" in "$HOME"*) dir="~${dir#"$HOME"}";; esac; fi
[ "$(printf '%s' "$dir" | awk -F/ '{print NF}')" -gt 3 ] && dir="…/$(printf '%s' "$dir" | awk -F/ '{print $(NF-1)"/"$NF}')"

C=$(printf '\033[36m'); M=$(printf '\033[35m'); Y=$(printf '\033[33m'); B=$(printf '\033[34m'); G=$(printf '\033[32m'); R=$(printf '\033[31m'); D=$(printf '\033[2m'); Z=$(printf '\033[0m')
sep=" ${D}|${Z} "

# Line 1
out="${C}${model}${Z}"
[ -n "$used" ] && out="$out$sep${M}Ctx: $(printf '%.0f' "$used")%${Z}"
[ -n "$branch" ] && out="$out$sep${Y}⎇ ${branch}${Z}"
out="$out$sep${B}${dir}${Z}"
[ -n "$add$del" ] && out="$out$sep${G}+${add:-0}${Z}/${R}-${del:-0}${Z}"
printf '%s\n' "$out"

# Line 2
l2=""
add_part() { l2="${l2:+$l2$sep}$1"; }
pct_color() { if [ "$1" -ge 80 ]; then printf '%s' "$R"; elif [ "$1" -ge 50 ]; then printf '%s' "$Y"; else printf '%s' "$G"; fi; }
# epoch_date EPOCH FORMAT: GNU date -d, else gdate, else BSD/macOS date -r.
# am/pm is lowercased with sed because BSD date has no %P.
if date -d @0 +%s >/dev/null 2>&1; then dcmd=date
elif command -v gdate >/dev/null 2>&1; then dcmd=gdate
else dcmd=bsd; fi
epoch_date() {
  if [ "$dcmd" = bsd ]; then date -r "$1" "+$2"; else "$dcmd" -d "@$1" "+$2"; fi | sed 's/AM/am/; s/PM/pm/'
}
fmt_reset() { # epoch -> 11am / 3:45pm today, or Tue 11am for a later day
  # %I is zero-padded; strip it with sed since the %-I flag isn't in every libc (musl/busybox)
  tf='%I:%M%p'; [ "$(epoch_date "$1" %M)" = 00 ] && tf='%I%p'
  if [ "$(epoch_date "$1" %F)" = "$(date +%F)" ]; then epoch_date "$1" " ($tf)"
  else epoch_date "$1" " (%a $tf)"; fi | sed 's/(0\([0-9]\)/(\1/; s/ 0\([0-9]\)/ \1/'
}
limit_part() { # label pct resets_at
  [ -n "$2" ] || return
  p=$(printf '%.0f' "$2"); t=""
  [ -n "$3" ] && t=$(fmt_reset "$3")
  add_part "$1: $(pct_color "$p")${p}%${Z}${D}${t}${Z}"
}
limit_part 5h "$h5" "$h5r"
limit_part 7d "$d7" "$d7r"
[ -n "$l2" ] && printf '%s\n' "$l2"
exit 0
