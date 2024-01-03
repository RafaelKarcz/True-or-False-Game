#!/usr/bin/env bash

# Constants
CREDENTIALS_FILE="ID_card.txt"
COOKIE_FILE="cookie.txt"
SCORES_FILE="scores.txt"
API_URL="http://127.0.0.1:8000"
RANDOM_SEED=4096
WORDS=("Perfect!" "Awesome!" "You are a genius!" "Wow!" "Wonderful!")

# Menu Window
show_menu() {
    echo -ne "
0. Exit
1. Play a game
2. Display scores
3. Reset scores
Enter an option:
> "
}

# Fetch credentials and perform API call
fetch_question() {
    curl --silent --output "$CREDENTIALS_FILE" "$API_URL/download/file.txt"

    local username=$(awk -F'"' '/"username":/ {print $4}' "$CREDENTIALS_FILE")
    local password=$(awk -F'"' '/"password":/ {print $4}' "$CREDENTIALS_FILE")

    [[ -z $username || -z $password ]] && { echo "Error: Credentials not found."; exit 1; }

    curl --silent --cookie-jar "$COOKIE_FILE" --user "$username:$password" "$API_URL/login" > /dev/null
    local response=$(curl --silent --cookie "$COOKIE_FILE" "$API_URL/game")

    QUESTION=$(echo "$response" | awk -F'"' '/"question":/ {print $4}')
    ANSWER=$(echo "$response" | awk -F'"' '/"answer":/ {print $4}')
}

# Main logic
echo "Welcome to the True or False Game!"
current_menu="main"
correct_answers=0
score=0
player_name=""

while true; do
    case $current_menu in
        "main")
            show_menu
            read -r choice
            case $choice in
                0)  
                    echo -e "\nSee you later!\n"
                    exit 0
                    ;;
                1)  
                    current_menu="game"
                    score=0
                    correct_answers=0
                    ;;
                2)
                    if [[ -s $SCORES_FILE ]]; then
                        echo -e "\nPlayer scores\n"
                        cat "$SCORES_FILE"
                    else
                        echo "File not found or no scores in it!"
                    fi
                    ;;
                3)
                    if [[ -s $SCORES_FILE ]]; then
                        rm "$SCORES_FILE"
                        echo "File deleted successfully!"
                    else
                        echo "File not found or no scores in it!"
                    fi
                    ;;
                *)
                    echo -e "\nInvalid option!\n"
                    ;;
            esac
            ;;
        "game")
            [[ -z $player_name ]] && { echo -ne "\nWhat is your name?\n> "; read -r player_name; }
            
            RANDOM=$RANDOM_SEED
            while true; do
                fetch_question
                echo -e "\n$QUESTION\nTrue or False?\n> "
                read -r player_response

                if [[ $ANSWER == $player_response ]]; then
                    local index=$((RANDOM % ${#WORDS[@]}))
                    echo -e "${WORDS[index]}\n"
                    score=$((score + 10))
                    correct_answers=$((correct_answers + 1))
                else
                    echo -e "\nWrong answer, sorry!\n$player_name, you have $correct_answers correct answer(s)."
                    echo -e "Your score is $score points.\n"
                    echo "User: $player_name, Score: $score, Date: $(date +%Y-%m-%d)" >> $SCORES_FILE
                    break
                fi
            done
            current_menu="main"
            ;;
    esac
done