# This is a sample how you can easily integrate the chatGPT API in your .zshrc
# jq is required https://stedolan.github.io/jq/download/
# OpenAI API key is required
# Complete tutorial: https://de.jberries.com/artikel/chatgpt-als-helfer-in-der-shell-189

export PATH=$PATH:/jq-osx-amd64
export OPENAI_KEY=XXX

function gpt_ask() {
  local prompt="'$(echo "$*" | sed "s/'/\\\\'/g")'"
  local gpt=$(curl https://api.openai.com/v1/chat/completions -s \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $OPENAI_KEY" \
    -d '{
        "model": "gpt-3.5-turbo",
        "messages": [{"role": "user","content": "'"$prompt"'"}],
        "temperature": 0.7,
        "stream": true
        }')

  while read -r text; do
    # check if line is equal to "data: [DONE]"
    if [[ $text == "data: [DONE]" ]]; then
      break
    # check if line matches "role"
    elif [[ $text =~ role ]]; then
      continue
    # check if line matches "content"
    elif [[ $text =~ content ]]; then
      # remove "data: " from the beginning of the line
      text=${text#"data: "}
      # use jq to parse the JSON and extract the "content" field
      #printf "%s" "$text" | jq -r -j '.choices[0].delta.content'
      echo -E "$text" | jq -r -j '.choices[0].delta.content'
    else
      continue
    fi
  done <<< "$gpt"
}

function gpt_data() {
  curl https://api.openai.com/v1/chat/completions -s \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $OPENAI_KEY" \
  -d '{
    "model": "gpt-3.5-turbo",
    "messages": [{"role": "user","content": "'"$1: $(echo -n "$2" | sed 's/$/\\n/g' | tr -d '\n')"'"}],
    "temperature": 0.7
    }' | jq -r '.choices[0].message.content'
}

function gpt_image() {
  local prompt="$1"
  local gpt=$(curl https://api.openai.com/v1/images/generations -s \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $OPENAI_KEY" \
  -d '{
      "n": 1,
      "prompt": "'"$prompt"'",
      "size": "1024x1024"
      }')
  echo $gpt
  local url=$(echo $gpt | jq -r '.data[0].url')

  local filename=$(echo "$prompt" | tr ' ' '_')
  filename=$(echo "$filename" | tr -cd '[:alnum:]_-')

  fname_length=${#filename}
  if [[ $fname_length -gt 150 ]]; then
    filename=${filename:0:150}
  fi

  curl -s $url -o img-"$filename".png
}
