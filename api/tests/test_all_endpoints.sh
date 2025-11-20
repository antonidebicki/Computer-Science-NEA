#!/bin/bash

#volleyLeague API Endpoint Testing Script
#tests endpoints for "/api/"

BASE_URL="http://localhost:8000/api"

#test credentials from seed data
ADMIN_USER="league_admin"
ADMIN_PASS="AdminPass123"
PLAYER_USER="emma_davies"
PLAYER_PASS="AdminPass123"
COACH_USER="sarah_johnson"
COACH_PASS="AdminPass123"

PASSED=0
FAILED=0

pass() {
    echo "[PASS] $1"
    PASSED=$((PASSED + 1))
}

fail() {
    echo "[FAIL] $1"
    FAILED=$((FAILED + 1))
}

echo "VolleyLeague API Endpoint Tests"
echo ""

echo "Authentication Tests"

ADMIN_TOKEN=$(curl -s -X POST "$BASE_URL/login" \
    -H "Content-Type: application/json" \
    -d "{\"username\":\"$ADMIN_USER\",\"password\":\"$ADMIN_PASS\"}" \
    | grep -o '"access_token":"[^"]*' | cut -d'"' -f4)

if [ -n "$ADMIN_TOKEN" ]; then
    pass "Admin login"
else
    fail "Admin login"
    exit 1
fi
PLAYER_TOKEN=$(curl -s -X POST "$BASE_URL/login" \
    -H "Content-Type: application/json" \
    -d "{\"username\":\"$PLAYER_USER\",\"password\":\"$PLAYER_PASS\"}" \
    | grep -o '"access_token":"[^"]*' | cut -d'"' -f4)

if [ -n "$PLAYER_TOKEN" ]; then
    pass "Player login"
else
    fail "Player login"
fi

COACH_TOKEN=$(curl -s -X POST "$BASE_URL/login" \
    -H "Content-Type: application/json" \
    -d "{\"username\":\"$COACH_USER\",\"password\":\"$COACH_PASS\"}" \
    | grep -o '"access_token":"[^"]*' | cut -d'"' -f4)

if [ -n "$COACH_TOKEN" ]; then
    pass "Coach login"
else
    fail "Coach login"
fi

echo ""

echo "League Endpoints"

LEAGUES=$(curl -s -X GET "$BASE_URL/leagues" \
    -H "Authorization: Bearer $ADMIN_TOKEN")
LEAGUE_COUNT=$(echo "$LEAGUES" | grep -o '"league_id"' | wc -l | tr -d ' ')
if [ "$LEAGUE_COUNT" -ge "2" ]; then
    pass "GET /leagues (found $LEAGUE_COUNT leagues)"
else
    fail "GET /leagues (expected 2+, got $LEAGUE_COUNT)"
fi

LEAGUE=$(curl -s -X GET "$BASE_URL/leagues/1" \
    -H "Authorization: Bearer $ADMIN_TOKEN")
if echo "$LEAGUE" | grep -q "South East Division"; then
    pass "GET /leagues/1"
else
    fail "GET /leagues/1"
fi


SEASONS=$(curl -s -X GET "$BASE_URL/leagues/1/seasons" \
    -H "Authorization: Bearer $ADMIN_TOKEN")
if echo "$SEASONS" | grep -q "2025/26 Season"; then
    pass "GET /leagues/1/seasons"
else
    fail "GET /leagues/1/seasons"
fi

echo ""
echo "Team Endpoints"
TEAMS=$(curl -s -X GET "$BASE_URL/teams" \
    -H "Authorization: Bearer $ADMIN_TOKEN")
TEAM_COUNT=$(echo "$TEAMS" | grep -o '"team_id"' | wc -l | tr -d ' ')
if [ "$TEAM_COUNT" -ge "6" ]; then
    pass "GET /teams (found $TEAM_COUNT teams)"
else
    fail "GET /teams (expected 6+, got $TEAM_COUNT)"
fi

TEAM=$(curl -s -X GET "$BASE_URL/teams/1" \
    -H "Authorization: Bearer $ADMIN_TOKEN")
if echo "$TEAM" | grep -q "South Bucks"; then
    pass "GET /teams/1"
else
    fail "GET /teams/1"
fi

MEMBERS=$(curl -s -X GET "$BASE_URL/teams/1/members" \
    -H "Authorization: Bearer $ADMIN_TOKEN")
MEMBER_COUNT=$(echo "$MEMBERS" | grep -o '"user_id"' | wc -l | tr -d ' ')
if [ "$MEMBER_COUNT" -ge "1" ]; then
    pass "GET /teams/1/members (found $MEMBER_COUNT members)"
else
    fail "GET /teams/1/members (expected 1+, got $MEMBER_COUNT)"
fi

echo ""
echo "Team joins/leaves"

PLAYER_ID=$(curl -s -X GET "$BASE_URL/users/me" \
    -H "Authorization: Bearer $PLAYER_TOKEN" \
    | grep -o '"user_id":[0-9]*' | cut -d':' -f2)

JOIN_CODE=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$BASE_URL/teams/4/join" \
    -H "Authorization: Bearer $PLAYER_TOKEN" \
    -H "Content-Type: application/json" \
    -d '{"player_number": 99}')

if [ "$JOIN_CODE" = "201" ] || [ "$JOIN_CODE" = "409" ]; then
    pass "POST /teams/4/join (code: $JOIN_CODE)"
else
    fail "POST /teams/4/join (code: $JOIN_CODE)"
fi

if [ -n "$PLAYER_ID" ]; then
    LEAVE_CODE=$(curl -s -o /dev/null -w "%{http_code}" -X DELETE "$BASE_URL/teams/4/members/$PLAYER_ID" \
        -H "Authorization: Bearer $PLAYER_TOKEN")
    
    if [ "$LEAVE_CODE" = "204" ] || [ "$LEAVE_CODE" = "404" ]; then
        pass "DELETE /teams/4/members/$PLAYER_ID (code: $LEAVE_CODE)"
    else
        fail "DELETE /teams/4/members/$PLAYER_ID (code: $LEAVE_CODE)"
    fi
fi
echo ""
echo "Season-Team Management"

SEASON_TEAMS=$(curl -s -X GET "$BASE_URL/seasons/1/teams" \
    -H "Authorization: Bearer $ADMIN_TOKEN")
SEASON_TEAM_COUNT=$(echo "$SEASON_TEAMS" | grep -o '"team_id"' | wc -l | tr -d ' ')
if [ "$SEASON_TEAM_COUNT" -ge "1" ]; then
    pass "GET /seasons/1/teams (found $SEASON_TEAM_COUNT teams)"
else
    fail "GET /seasons/1/teams (expected 1+, got $SEASON_TEAM_COUNT)"
fi

#adding a team to season
ADD_CODE=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$BASE_URL/seasons/1/teams/1" \
    -H "Authorization: Bearer $ADMIN_TOKEN")

if [ "$ADD_CODE" = "201" ] || [ "$ADD_CODE" = "409" ]; then
    pass "POST /seasons/1/teams/1 (code: $ADD_CODE)"
else
    fail "POST /seasons/1/teams/1 (code: $ADD_CODE)"
fi

echo ""

echo "Match Endpoints"

MATCHES=$(curl -s -X GET "$BASE_URL/matches" \
    -H "Authorization: Bearer $ADMIN_TOKEN")
MATCH_COUNT=$(echo "$MATCHES" | grep -o '"match_id"' | wc -l | tr -d ' ')
if [ "$MATCH_COUNT" -ge "1" ]; then
    pass "GET /matches (found $MATCH_COUNT matches)"
else
    fail "GET /matches (expected 1+, got $MATCH_COUNT)"
fi

#Test filter by season
SEASON_MATCHES=$(curl -s -X GET "$BASE_URL/matches?season_id=1" \
    -H "Authorization: Bearer $ADMIN_TOKEN")
SEASON_MATCH_COUNT=$(echo "$SEASON_MATCHES" | grep -o '"match_id"' | wc -l | tr -d ' ')
pass "GET /matches?season_id=1 (found $SEASON_MATCH_COUNT matches)"

# test filter by team
TEAM_MATCHES=$(curl -s -X GET "$BASE_URL/matches?team_id=1" \
    -H "Authorization: Bearer $ADMIN_TOKEN")
TEAM_MATCH_COUNT=$(echo "$TEAM_MATCHES" | grep -o '"match_id"' | wc -l | tr -d ' ')
pass "GET /matches?team_id=1 (found $TEAM_MATCH_COUNT matches)"

echo ""
echo "Standings Endpoints"

STANDINGS=$(curl -s -X GET "$BASE_URL/seasons/1/standings" \
    -H "Authorization: Bearer $ADMIN_TOKEN")
STANDINGS_COUNT=$(echo "$STANDINGS" | grep -o '"team_id"' | wc -l | tr -d ' ')
if [ "$STANDINGS_COUNT" -ge "1" ]; then
    pass "GET /seasons/1/standings (found $STANDINGS_COUNT teams)"
else
    fail "GET /seasons/1/standings (expected 1+, got $STANDINGS_COUNT)"
fi

# Test archived parameter
ARCHIVED_STANDINGS=$(curl -s -X GET "$BASE_URL/seasons/1/standings?archived=true" \
    -H "Authorization: Bearer $ADMIN_TOKEN")
pass "GET /seasons/1/standings?archived=true"

echo ""

echo "Authorization Tests"

# player shouldn't be able to create league
UNAUTH_CODE=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$BASE_URL/leagues" \
    -H "Authorization: Bearer $PLAYER_TOKEN" \
    -H "Content-Type: application/json" \
    -d '{"league_name":"Test League"}')

if [ "$UNAUTH_CODE" = "403" ]; then
    pass "Player denied admin action (code: $UNAUTH_CODE)"
else
    fail "Player denied admin action (expected 403, got: $UNAUTH_CODE)"
fi

# unauthenticated request should fail
NO_AUTH_CODE=$(curl -s -o /dev/null -w "%{http_code}" -X GET "$BASE_URL/teams")

if [ "$NO_AUTH_CODE" = "401" ]; then
    pass "Unauthenticated request denied (code: $NO_AUTH_CODE)"
else
    fail "Unauthenticated request denied (expected 401, got: $NO_AUTH_CODE)"
fi

echo ""
echo "Test Summary"
echo "Passed: $PASSED"
echo "Failed: $FAILED"
echo ""

if [ "$FAILED" -eq 0 ]; then
    echo "All tests passed!"
    exit 0
else
    echo "Some tests failed."
    exit 1
fi
