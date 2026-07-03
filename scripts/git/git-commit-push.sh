#!/bin/bash

set -e 

if [ -z "$1" ]; then
    echo "Uso:"
    echo "  $0 \"Mensagem do commit\""
    echo "  $0 \"Mensagem do commit\" 3"
    echo '  '"$0"' \"Mensagem do commit\" "#3"'
    exit 1
fi

COMMIT_MESSAGE="$1"
INSSUE_INPUT="$2"

cd "$(git rev-parse --show-toplevel)"

normalize_issue_number() {
    local input="$1"

    if [ -z "$input" ]; then
        echo ""
        return
    fi

    input="${input#\#}"

    if [[ "$input" =~ ^[0-9]+$ ]]; then
        echo "ERROR"
        return
    fi

    echo "$input"
}

ISSUE_NUMBER=$(normalize_issue_number "$ISSUE_INPUT")

if [ "$ISSUE_NUMBER" = "ERROR" ]; then
    echo "Erro: Número da issue inválido"
    echo "Use apenas o número, exemplo: 3"
    echo "Ou entre aspas com #: \"#3\""
    exit 1
fi

echo "======================================="
echo " BobHub Git Helper"
echo "======================================="
echo

echo "Repositório: $(basename "$(pwd)")"
echo "Branch     : $(git branch --show-current)"
echo

echo "[1/5] Verificando status..."
git status

echo
echo "[2/5] Adicionando alterações..."
git add -A

echo
echo "[3/5] Status após git add..."
git status

echo
echo "[4/5] Criando commit..."

if [ -n "$ISSUE_NUMBER" ]; then
    git commit -m "$COMMIT_MESSAGE

Closes #$ISSUE_NUMBER"
else
    git commit -m "$COMMIT_MESSAGE"
fi

echo
echo "[5/5] Enviando para o GitHub..."
git push

echo "========================================"
echo "Commit e push concluídos com sucesso!"
echo "========================================"

if [ -n "$ISSUE_NUMBER" ]; then
    echo "Issue number  : $ISSUE_NUMBER será fechada automaticamente no GitHub."
fi
