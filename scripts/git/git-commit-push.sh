#!/bin/bash

set -e 

if [ -z "$1" ]; then
    echo "Uso: ./scripts/git-commit-push.sh \"mensagem do commit\""
    exit 1
fi

COMMIT_MESSAGE="$1"

cd "$(git rev-parse --show-toplevel)"

echo "Verificando alterações..."
git status

echo "Adicionando alterações..."
git add -A

echo "Status após git add..."
git status

echo "Criando commit..."
git commit -m "$COMMIT_MESSAGE"

echo "Enviando alterações para o repositório remoto..."
git push

echo "Commit e push concluídos com sucesso!"