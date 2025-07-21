#!/bin/bash
set -e

# Default values
BRANCH_NAME="${GITHUB_REF##*/}"
ACTOR="$GITHUB_ACTOR"
REPO="$GITHUB_REPOSITORY"
REPO_URL="https://github.com/$REPO"
GITHUB_API_URL="https://api.github.com"
EVENT_NAME="$GITHUB_EVENT_NAME"
EVENT_PATH="$GITHUB_EVENT_PATH"

# Telegram
CHAT_ID="$INPUT_CHAT_ID"
BOT_TOKEN="$INPUT_BOT_TOKEN"

function send_message() {
  local message="$1"

  curl -s -X POST "https://api.telegram.org/bot${BOT_TOKEN}/sendMessage" \
    -d chat_id="$CHAT_ID" \
    -d text="$message" \
    -d parse_mode="Markdown"
}

# ========== Merged Pull Request ==========
if [[ "$EVENT_NAME" == "pull_request" ]]; then
  PR_MERGED=$(jq -r .pull_request.merged "$EVENT_PATH")
  PR_ACTION=$(jq -r .action "$EVENT_PATH")

  if [[ "$PR_ACTION" == "closed" && "$PR_MERGED" == "true" ]]; then
    PR_TITLE=$(jq -r .pull_request.title "$EVENT_PATH")
    PR_URL=$(jq -r .pull_request.html_url "$EVENT_PATH")
    PR_NUMBER=$(jq -r .pull_request.number "$EVENT_PATH")
    PR_AUTHOR=$(jq -r .pull_request.user.login "$EVENT_PATH")
    COMMITS_URL=$(jq -r .pull_request.commits_url "$EVENT_PATH")

    # Получаем коммиты через GitHub API
    COMMIT_MESSAGES=$(curl -s -H "Authorization: token $GITHUB_TOKEN" "$COMMITS_URL" | jq -r '.[].commit.message' | head -n 10)

    # Формируем сообщение
    MESSAGE="✅ *Pull Request Merged:* _${PR_TITLE}_ (#${PR_NUMBER})\n"
    MESSAGE+="🔀 *Into:* \`${BRANCH_NAME}\`\n"
    MESSAGE+="👤 *By:* @$PR_AUTHOR\n"
    MESSAGE+="\n*Commits included:*\n"
    while read -r line; do
      [[ -n "$line" ]] && MESSAGE+="  - $line\n"
    done <<< "$COMMIT_MESSAGES"
    MESSAGE+="\n🔗 [View Pull Request]($PR_URL)"

    send_message "$MESSAGE"
    exit 0
  fi
fi

# ========== Regular Push ==========
if [[ "$EVENT_NAME" == "push" ]]; then
  BEFORE=$(jq -r .before "$EVENT_PATH")
  AFTER=$(jq -r .after "$EVENT_PATH")
  COMPARE_URL="$REPO_URL/compare/${BEFORE}...${AFTER}"

  COMMITS=$(jq -r '.commits[] | "- \(.message) [\(.id[0:7])](\(.url)) by \(.author.name)"' "$EVENT_PATH")

  MESSAGE="🔄 *New push to branch:* \`${BRANCH_NAME}\`\n"
  MESSAGE+="👤 *By:* @$ACTOR\n\n"
  MESSAGE+="*Commits:*\n$COMMITS\n"
  MESSAGE+="\n🔗 [Compare Changes]($COMPARE_URL)"

  send_message "$MESSAGE"
  exit 0
fi

# ========== Fallback ==========
send_message "📢 GitHub Action triggered by \`$EVENT_NAME\`, but no specific message handler is defined."
