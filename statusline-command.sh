#!/bin/bash
# Claude Code statusline
# Line 1: model | version | effort | total tokens | 7d usage   (each field its own color)
# Line 2: ctx bar | usage bar   (two separate progress bars)

input=$(cat)

model=$(echo "$input" | jq -r '.model.display_name // "Claude"')
version=$(echo "$input" | jq -r '.version // empty')
effort=$(echo "$input" | jq -r '.effort.level // empty')

# Total tokens (input + output tokens currently counted in context window)
in_tok=$(echo "$input" | jq -r '.context_window.total_input_tokens // 0')
out_tok=$(echo "$input" | jq -r '.context_window.total_output_tokens // 0')
total_tok=$((in_tok + out_tok))

# 7-day rate limit usage
week_pct=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')
if [ -n "$week_pct" ]; then
  week_str=$(printf "%.0f%%" "$week_pct")
else
  week_str="--"
fi

# Context window usage
used_pct=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
ctx_size=$(echo "$input" | jq -r '.context_window.context_window_size // 0')
used_tok=$in_tok

# 5-hour rate limit usage ("usage" bar)
five_pct=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')

# ---- Formatting helpers ----

# Human readable token counts: 12.3k, 1.0M, or raw integer under 1000
human() {
  local n=$1
  if [ "$n" -ge 1000000 ]; then
    printf "%.1fM" "$(echo "$n / 1000000" | bc -l)"
  elif [ "$n" -ge 1000 ]; then
    printf "%.1fk" "$(echo "$n / 1000" | bc -l)"
  else
    printf "%d" "$n"
  fi
}

# Build an N-block progress bar for a percentage (empty pct -> all empty, "?" caller handles label)
make_bar() {
  local pct=$1 len=$2 filled empty bar i
  if [ -n "$pct" ]; then
    filled=$(printf "%.0f" "$(echo "$pct * $len / 100" | bc -l)")
    [ "$filled" -gt "$len" ] && filled=$len
    [ "$filled" -lt 0 ] && filled=0
  else
    filled=0
  fi
  empty=$((len - filled))
  bar=""
  for ((i = 0; i < filled; i++)); do bar="${bar}█"; done
  for ((i = 0; i < empty; i++)); do bar="${bar}░"; done
  printf "%s" "$bar"
}

# 256-color helper (readable-ish on both light and dark terminal themes: mid-tone, non-white/black)
color() {
  printf "\033[38;5;%sm%s\033[0m" "$1" "$2"
}

DIM="\033[2m"
RESET="\033[0m"

MODEL_C=39     # blue
VERSION_C=16   # true black (256-color 16 / ANSI 0)
EFFORT_C=135   # purple
TOKENS_C=28    # green
WEEK_C=166     # orange
CTX_C=30       # teal
USAGE_C=125    # magenta/pink

used_h=$(human "$used_tok")
total_h=$(human "$ctx_size")
total_tok_h=$(human "$total_tok")

bar_len=16
ctx_bar=$(make_bar "$used_pct" "$bar_len")
usage_bar=$(make_bar "$five_pct" "$bar_len")

if [ -n "$used_pct" ]; then
  ctx_str=$(printf "%.0f%%" "$used_pct")
else
  ctx_str="?%"
fi

if [ -n "$five_pct" ]; then
  usage_str=$(printf "%.0f%%" "$five_pct")
else
  usage_str="?%"
fi

# ---- Build line 1 ----
sep="${DIM} | ${RESET}"

line1=$(color "$MODEL_C" "$model")
if [ -n "$version" ]; then
  line1="${line1}${sep}$(color "$VERSION_C" "v$version")"
fi
if [ -n "$effort" ]; then
  line1="${line1}${sep}$(color "$EFFORT_C" "effort:$effort")"
fi
line1="${line1}${sep}$(color "$TOKENS_C" "total tokens:$total_tok_h")${sep}$(color "$WEEK_C" "7d:$week_str")"

# ---- Build line 2 (two separate bars) ----
ctx_part="$(color "$CTX_C" "ctx:$ctx_str [$ctx_bar] $used_h/$total_h")"
usage_part="$(color "$USAGE_C" "usage:$usage_str [$usage_bar]")"

line2="   ${ctx_part}${sep}${usage_part}"

printf "%b\n%b\n" "$line1" "$line2"
