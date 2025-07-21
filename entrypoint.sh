#!/bin/bash
set -e

STATUS_MESSAGE=$1
TELEGRAM_TOKEN=$2
TELEGRAM_CHAT_IDS=$3

COMMIT_MESSAGE="${GITHUB_EVENT_HEAD_COMMIT_MESSAGE}"
COMMITTER="${GITHUB_ACTOR}"
COMMITTER_URL="https://github.com/${COMMITTER}"
BRANCH_NAME="${GITHUB_REF_NAME}"
REPOSITORY="${GITHUB_REPOSITORY}"
REPO_URL="https://github.com/${REPOSITORY}"
BRANCH_URL="${REPO_URL}/tree/${BRANCH_NAME}"
ACTION_URL="https://github.com/${REPOSITORY}/actions/runs/${GITHUB_RUN_ID}"
COMMIT_URL="https://github.com/${REPOSITORY}/commit/${GITHUB_SHA}"

for chat_id in $(echo "${TELEGRAM_CHAT_IDS}" | tr "," "\n"); do
  curl -s -X POST "https://api.telegram.org/bot${TELEGRAM_TOKEN}/sendMessage" \
    -H "Content-Type: application/json" \
    -d "{
          \"chat_id\": \"$chat_id\",
          \"text\": \"${STATUS_MESSAGE}\n\nRepository: <a href='${REPO_URL}'>${REPOSITORY}</a>\nBranch: <a href='${BRANCH_URL}'>${BRANCH_NAME}</a>\nCommit Message: <a href='${COMMIT_URL}'><i>${COMMIT_MESSAGE}</i></a>\nCommitter: <a href='${COMMITTER_URL}'>${COMMITTER}</a>\nAction Logs: <a href='${ACTION_URL}'>View Logs</a>\",
          \"parse_mode\": \"HTML\"
        }"
done
