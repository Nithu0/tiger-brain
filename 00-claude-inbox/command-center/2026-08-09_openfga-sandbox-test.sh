#!/usr/bin/env bash
# OpenFGA sandbox-test: multi-tenant isolasjonsmodell. Ephemeral, in-memory.
set -euo pipefail
API=http://localhost:8080

echo "== create store =="
STORE_ID=$(curl -s -X POST "$API/stores" -H 'content-type: application/json' \
  -d '{"name":"cc-sandbox"}' | python3 -c 'import sys,json;print(json.load(sys.stdin)["id"])')
echo "store: $STORE_ID"

echo "== write authorization model =="
MODEL_ID=$(curl -s -X POST "$API/stores/$STORE_ID/authorization-models" \
  -H 'content-type: application/json' -d @- <<'EOF' | python3 -c 'import sys,json;print(json.load(sys.stdin)["authorization_model_id"])'
{
  "schema_version": "1.1",
  "type_definitions": [
    {"type": "user"},
    {"type": "tenant",
     "relations": {
       "admin": {"this": {}},
       "viewer": {"union": {"child": [{"this": {}}, {"computedUserset": {"relation": "admin"}}]}}
     },
     "metadata": {"relations": {
       "admin": {"directly_related_user_types": [{"type": "user"}]},
       "viewer": {"directly_related_user_types": [{"type": "user"}]}
     }}},
    {"type": "project",
     "relations": {
       "parent": {"this": {}},
       "admin": {"tupleToUserset": {"tupleset": {"relation": "parent"}, "computedUserset": {"relation": "admin"}}},
       "viewer": {"tupleToUserset": {"tupleset": {"relation": "parent"}, "computedUserset": {"relation": "viewer"}}}
     },
     "metadata": {"relations": {
       "parent": {"directly_related_user_types": [{"type": "tenant"}]},
       "admin": {"directly_related_user_types": []},
       "viewer": {"directly_related_user_types": []}
     }}},
    {"type": "resource",
     "relations": {
       "parent": {"this": {}},
       "admin": {"tupleToUserset": {"tupleset": {"relation": "parent"}, "computedUserset": {"relation": "admin"}}},
       "viewer": {"tupleToUserset": {"tupleset": {"relation": "parent"}, "computedUserset": {"relation": "viewer"}}}
     },
     "metadata": {"relations": {
       "parent": {"directly_related_user_types": [{"type": "project"}]},
       "admin": {"directly_related_user_types": []},
       "viewer": {"directly_related_user_types": []}
     }}}
  ]
}
EOF
)
echo "model: $MODEL_ID"

echo "== write tuples (2 tenants: acme + beta) =="
curl -s -X POST "$API/stores/$STORE_ID/write" -H 'content-type: application/json' -d @- <<EOF
{"writes": {"tuple_keys": [
  {"user": "user:alice", "relation": "admin",  "object": "tenant:acme"},
  {"user": "user:bob",   "relation": "admin",  "object": "tenant:beta"},
  {"user": "tenant:acme", "relation": "parent", "object": "project:acme-crm"},
  {"user": "tenant:beta", "relation": "parent", "object": "project:beta-crm"},
  {"user": "project:acme-crm", "relation": "parent", "object": "resource:acme-db"},
  {"user": "project:beta-crm", "relation": "parent", "object": "resource:beta-db"}
]}, "authorization_model_id": "$MODEL_ID"}
EOF
echo

check() {
  local user=$1 rel=$2 obj=$3
  printf '%-12s %-8s %-18s -> ' "$user" "$rel" "$obj"
  curl -s -X POST "$API/stores/$STORE_ID/check" -H 'content-type: application/json' \
    -d "{\"tuple_key\": {\"user\": \"$user\", \"relation\": \"$rel\", \"object\": \"$obj\"}, \"authorization_model_id\": \"$MODEL_ID\"}"
  echo
}

echo "== checks =="
check user:alice viewer resource:acme-db   # egen tenant -> forvent true
check user:alice admin  resource:acme-db   # egen tenant -> forvent true
check user:alice viewer resource:beta-db   # KRYSS-tenant -> forvent false
check user:bob   viewer resource:beta-db   # egen tenant -> forvent true
check user:bob   admin  resource:acme-db   # KRYSS-tenant -> forvent false
check user:bob   viewer project:acme-crm   # KRYSS-tenant prosjektnivaa -> forvent false
