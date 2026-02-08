#!/bin/bash
# Banner and separator functions for fun terminal output
# Includes integration with cowsay, figlet, toilet, boxes, and lolcat

# Check which banner tools are available
_has_cowsay() { command -v cowsay &>/dev/null; }
_has_figlet() { command -v figlet &>/dev/null; }
_has_toilet() { command -v toilet &>/dev/null; }
_has_boxes() { command -v boxes &>/dev/null; }
_has_lolcat() { command -v lolcat &>/dev/null; }

# Basic separators and headers
banner::separator() {
    local char="${1:--}"
    local width="${2:-80}"
    printf '%*s\n' "$width" '' | tr ' ' "$char"
}

banner::header() {
    local text="$1"
    local width="${2:-80}"
    local char="${3:-=}"
    
    banner::separator "$char" "$width"
    printf "%*s\n" $(( (width + ${#text}) / 2 )) "$text"
    banner::separator "$char" "$width"
}

banner::box() {
    local text="$1"
    local style="${2:-}"
    
    if _has_boxes && [[ -n "$style" ]]; then
        echo "$text" | boxes -d "$style"
    elif _has_boxes; then
        echo "$text" | boxes
    else
        # Simple fallback box
        local width=$((${#text} + 4))
        banner::separator "-" "$width"
        echo "| $text |"
        banner::separator "-" "$width"
    fi
}

# Cowsay functions
banner::cowsay() {
    local message="$1"
    local cow="${2:-default}"
    
    if _has_cowsay; then
        cowsay -f "$cow" "$message"
    else
        echo "$message"
    fi
}

banner::cowthink() {
    local message="$1"
    local cow="${2:-default}"
    
    if _has_cowsay; then
        cowthink -f "$cow" "$message"
    else
        echo "($message)"
    fi
}

# Rainbow functions 🌈
banner::rainbow_cow() {
    local message="$1"
    local cow="${2:-default}"
    
    if _has_cowsay && _has_lolcat; then
        cowsay -f "$cow" "$message" | lolcat
    else
        banner::cowsay "$message" "$cow"
    fi
}

banner::rainbow() {
    if _has_lolcat; then
        echo "$@" | lolcat
    else
        echo "$@"
    fi
}

# Figlet functions
banner::figlet() {
    local text="$1"
    local font="${2:-}"
    
    if _has_figlet; then
        if [[ -n "$font" ]]; then
            figlet -f "$font" "$text"
        else
            figlet "$text"
        fi
    else
        banner::header "$text"
    fi
}

banner::rainbow_figlet() {
    local text="$1"
    local font="${2:-}"
    
    if _has_figlet && _has_lolcat; then
        banner::figlet "$text" "$font" | lolcat
    else
        banner::figlet "$text" "$font"
    fi
}

# Toilet functions (fancy ASCII art)
banner::toilet() {
    local text="$1"
    local font="${2:-}"
    local filter="${3:-}"
    
    if _has_toilet; then
        local cmd="toilet"
        [[ -n "$font" ]] && cmd="$cmd -f $font"
        [[ -n "$filter" ]] && cmd="$cmd -F $filter"
        $cmd "$text"
    else
        banner::figlet "$text"
    fi
}

banner::rainbow_toilet() {
    local text="$1"
    local font="${2:-mono12}"
    local filter="${3:-}"
    
    if _has_toilet && _has_lolcat; then
        banner::toilet "$text" "$font" "$filter" | lolcat
    else
        banner::toilet "$text" "$font" "$filter"
    fi
}

# Special celebration banners
banner::celebrate() {
    local message="${1:-Success!}"
    
    if _has_toilet && _has_lolcat; then
        toilet -f mono12 "$message" | lolcat
        echo
        _has_cowsay && cowsay "🎉 $message 🎉" | lolcat
    elif _has_figlet && _has_lolcat; then
        figlet "$message" | lolcat
    else
        banner::header "🎉 $message 🎉"
    fi
}

banner::alert() {
    local message="${1:-Alert!}"
    
    echo
    if _has_figlet; then
        figlet -f slant "$message"
    else
        banner::header "⚠️  $message ⚠️" 60 "!"
    fi
    echo
}

banner::section() {
    local title="$1"
    
    echo
    if _has_toilet && _has_lolcat; then
        toilet -f future "$title" | lolcat
    elif _has_figlet; then
        figlet -f small "$title"
    else
        banner::header "$title"
    fi
    echo
}

# Fun random banner
banner::random_animal() {
    local message="$1"
    
    if _has_cowsay; then
        local animals=(default apt bud-frogs bunny calvin cheese cock dragon 
                      dragon-and-cow duck elephant ghostbusters gnu kitty 
                      koala luke-koala moose ren sheep stegosaurus stimpy 
                      three-eyes turkey turtle tux)
        local random_animal=${animals[$RANDOM % ${#animals[@]}]}
        
        if _has_lolcat; then
            cowsay -f "$random_animal" "$message" | lolcat
        else
            cowsay -f "$random_animal" "$message"
        fi
    else
        echo "$message"
    fi
}

# Matrix-style banner (if toilet is available)
banner::matrix() {
    local text="$1"
    
    if _has_toilet; then
        toilet -f matrix "$text" -F border
    else
        banner::header "$text" 60 "#"
    fi
}

# Fortune/Misfortune integration
banner::fortune_cow() {
    local cow="${1:-default}"
    
    if command -v fortune &>/dev/null && _has_cowsay; then
        if _has_lolcat; then
            fortune | cowsay -f "$cow" | lolcat
        else
            fortune | cowsay -f "$cow"
        fi
    else
        echo "Fortune or cowsay not available"
    fi
}

banner::misfortune_tux() {
    if command -v misfortune &>/dev/null && _has_cowsay; then
        if _has_lolcat; then
            misfortune | cowsay -f tux | lolcat
        else
            misfortune | cowsay -f tux
        fi
    else
        echo "Misfortune or cowsay not available"
    fi
}

banner::daily_wisdom() {
    # Randomly choose between fortune and misfortune
    local use_misfortune=$((RANDOM % 2))
    
    if [[ $use_misfortune -eq 1 ]] && command -v misfortune &>/dev/null; then
        banner::misfortune_tux
    else
        banner::fortune_cow "$(banner::random_animal_name)"
    fi
}

# Helper to get random animal name without displaying
banner::random_animal_name() {
    if _has_cowsay; then
        local animals=(default apt bud-frogs bunny calvin cheese cock dragon 
                      dragon-and-cow duck elephant ghostbusters gnu kitty 
                      koala luke-koala moose ren sheep stegosaurus stimpy 
                      three-eyes turkey turtle tux)
        echo "${animals[$RANDOM % ${#animals[@]}]}"
    else
        echo "default"
    fi
}

# Fortune with specific topic if available
banner::fortune_topic() {
    local topic="$1"
    local cow="${2:-$(banner::random_animal_name)}"
    
    if command -v fortune &>/dev/null && _has_cowsay; then
        # Try to use topic-specific fortune file if it exists
        local fortune_cmd="fortune"
        if [[ -n "$topic" ]] && fortune -f 2>&1 | grep -q "$topic"; then
            fortune_cmd="fortune $topic"
        fi
        
        if _has_lolcat; then
            eval "$fortune_cmd" | cowsay -f "$cow" | lolcat
        else
            eval "$fortune_cmd" | cowsay -f "$cow"
        fi
    else
        echo "Fortune or cowsay not available"
    fi
}

# List available banner styles
banner::list_styles() {
    echo "Available banner functions:"
    echo "  banner::separator [char] [width]"
    echo "  banner::header <text> [width] [char]"
    echo "  banner::box <text> [style]"
    
    _has_cowsay && echo "  banner::cowsay <message> [cow]"
    _has_cowsay && echo "  banner::cowthink <message> [cow]"
    _has_cowsay && _has_lolcat && echo "  banner::rainbow_cow <message> [cow]"
    _has_lolcat && echo "  banner::rainbow <text>"
    
    _has_figlet && echo "  banner::figlet <text> [font]"
    _has_figlet && _has_lolcat && echo "  banner::rainbow_figlet <text> [font]"
    
    _has_toilet && echo "  banner::toilet <text> [font] [filter]"
    _has_toilet && _has_lolcat && echo "  banner::rainbow_toilet <text> [font] [filter]"
    
    echo "  banner::celebrate [message]"
    echo "  banner::alert [message]"
    echo "  banner::section <title>"
    
    _has_cowsay && echo "  banner::random_animal <message>"
    _has_toilet && echo "  banner::matrix <text>"
    
    echo
    echo "Fortune/Wisdom functions:"
    command -v fortune &>/dev/null && _has_cowsay && echo "  banner::fortune_cow [cow]"
    command -v misfortune &>/dev/null && _has_cowsay && echo "  banner::misfortune_tux"
    echo "  banner::daily_wisdom"
    command -v fortune &>/dev/null && echo "  banner::fortune_topic <topic> [cow]"
    
    if _has_boxes; then
        echo
        echo "Available box styles:"
        boxes -l | grep -E "^[a-z]" | awk '{print "  " $1}'
    fi
}