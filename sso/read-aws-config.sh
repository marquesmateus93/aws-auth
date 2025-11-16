#!/usr/bin/env bash

CONFIG_FILE="$HOME/.aws/config"

# Array to store profiles
PROFILES=()

# Read each profile from file and store in array
while IFS= read -r PROFILE; do
    PROFILES+=("$PROFILE")
done < <(grep -E "^\[profile " "$CONFIG_FILE" | sed 's/\[profile //; s/\]//')

# Check if there are profiles
if [ ${#PROFILES[@]} -eq 0 ]; then
    echo "No profiles found in file $CONFIG_FILE"
    exit 1
fi

# Function to display menu
show_menu() {
    clear
    echo "=== Select a Profile ==="
    echo ""
    echo "Use ↑/↓ to Navigate, Enter to Select, 'q' to Quit"
    echo ""
    
    for i in "${!PROFILES[@]}"; do
        if [ $i -eq $SELECTED ]; then
            echo "  > ${PROFILES[$i]}"
        else
            echo "    ${PROFILES[$i]}"
        fi
    done
}

# Function to read a key
read_key() {
    local key
    IFS= read -rsn1 key 2>/dev/null || return 1
    if [[ $key == $'\x1b' ]]; then
        read -rsn2 key
        case "$key" in
            '[A'|'OA') echo "UP" ;;
            '[B'|'OB') echo "DOWN" ;;
            *) echo "OTHER" ;;
        esac
    else
        case "$key" in
            '') echo "ENTER" ;;
            'q'|'Q') echo "QUIT" ;;
            *) echo "OTHER" ;;
        esac
    fi
}

# Initialize selection
SELECTED=0

# Menu loop
function loop_menu() {
while true; do
    show_menu
    key=$(read_key)
    
    case "$key" in
        "UP")
            if [ $SELECTED -gt 0 ]; then
                ((SELECTED--))
            fi
            ;;
        "DOWN")
            if [ $SELECTED -lt $((${#PROFILES[@]} - 1)) ]; then
                ((SELECTED++))
            fi
            ;;
        "ENTER")
            PROFILE="${PROFILES[$SELECTED]}"
            clear
            
            # Extract properties from selected profile
            SSO_SESSION=$(awk -v p="$PROFILE" '
                $0 ~ "\\[profile "p"\\]" { inblock=1; next }
                inblock && /^\[/ { inblock=0 }
                inblock && /^sso_session/ { print $3 }
            ' "$CONFIG_FILE")

            ACCOUNT_ID=$(awk -v p="$PROFILE" '
                $0 ~ "\\[profile "p"\\]" { inblock=1; next }
                inblock && /^\[/ { inblock=0 }
                inblock && /^sso_account_id/ { print $3 }
            ' "$CONFIG_FILE")

            ROLE_NAME=$(awk -v p="$PROFILE" '
                $0 ~ "\\[profile "p"\\]" { inblock=1; next }
                inblock && /^\[/ { inblock=0 }
                inblock && /^sso_role_name/ { print $3 }
            ' "$CONFIG_FILE")

            # Extract region from corresponding sso-session
            SSO_REGION=$(awk -v s="$SSO_SESSION" '
                $0 ~ "\\[sso-session "s"\\]" { inblock=1; next }
                inblock && /^\[/ { inblock=0 }
                inblock && /^sso_region/ { print $3 }
            ' "$CONFIG_FILE")
            
            # Export selected profile as environment variable for later use
            export SELECTED_PROFILE="$PROFILE"
            # Export SSO Session to AWS_PROFILE
            export AWS_PROFILE="$SSO_SESSION"
            
            # Request AWS region
            echo -n "Enter AWS Region (Default: us-east-2): "
            read -r AWS_REGION_INPUT
            
            # Clear screen and show waiting message
            clear
            echo "⏳ Waiting for Confirmation..."
            
            # If empty, use us-east-2 as default
            if [ -z "$AWS_REGION_INPUT" ]; then
                AWS_REGION_INPUT="us-east-2"
            fi
            
            # Export region
            export AWS_REGION="$AWS_REGION_INPUT"
            
            # Store extracted information for later display
            export SELECTED_PROFILE_INFO="$PROFILE"
            export SELECTED_SSO_SESSION="$SSO_SESSION"
            export SELECTED_ACCOUNT_ID="$ACCOUNT_ID"
            export SELECTED_ROLE_NAME="$ROLE_NAME"
            
            break
            ;;
        "QUIT")
            clear
            echo "Exiting Menu..."
            exit 0
            ;;
        "OTHER")
            # Ignore other keys
            ;;
    esac
done
}

# Function to display profile information
function show_profile_info() {
    if [ -n "$SELECTED_PROFILE_INFO" ]; then
        clear
        echo "=== ✅ Successful Profile Login ==="
        echo ""
        
        # Check if there was an SSO login error
        if [ "${SSO_LOGIN_ERROR:-0}" -eq 1 ]; then
            echo "❌ Error Performing SSO Login"
            echo ""
        else
            echo " 🪪 SSO Session: ${SELECTED_SSO_SESSION:-N/A}"
            echo " 🚩 Account ID : ${SELECTED_ACCOUNT_ID:-N/A}"
            echo " 👑 Role Name  : ${SELECTED_ROLE_NAME:-N/A}"
            echo " 🌎 AWS Region : ${AWS_REGION:-N/A}"
            echo ""
            echo "=== 📋 Login Services Status ==="
            echo ""
        fi
    fi
}

# Only execute loop_menu if script is called directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    loop_menu
fi