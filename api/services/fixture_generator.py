import datetime
import random
from typing import List, Tuple, Optional
from datetime import timedelta


def generate_round_robin(team_ids: List[int], double: bool = False) -> List[Tuple[int, int]]:
    """
    Generate round-robin fixtures using the Berger method (circle/rotation algorithm).
    
    Args:
        team_ids: List of team IDs to schedule
        double: If True, generate double round-robin (home and away)
    
    Returns:
        List of match tuples (team_a_id, team_b_id)
    """
    if len(team_ids) < 2:
        return []
    
    teams: List[Optional[int]] = list(team_ids)
    
    # If odd number of teams, add a dummy (bye)
    has_bye = len(teams) % 2 == 1
    if has_bye:
        teams.append(None)  # None represents a "bye"
    
    n = len(teams)
    num_rounds = n - 1
    matches = []
    
    # Berger algorithm: fix first team, rotate others in circle
    for round_num in range(num_rounds):
        round_matches = []
        
        # Pair teams: first with last, second with second-to-last, etc.
        for i in range(n // 2):
            home_team = teams[i]
            away_team = teams[n - 1 - i]
            
            # Skip matches involving the bye team
            if home_team is not None and away_team is not None:
                # Alternate home/away based on round and position
                if (round_num + i) % 2 == 0:
                    round_matches.append((home_team, away_team))
                else:
                    round_matches.append((away_team, home_team))
        
        matches.extend(round_matches)
        
        # Rotate all teams except the first one
        teams = [teams[0]] + [teams[-1]] + teams[1:-1]
    
    if double:
        # For double round-robin, add reverse fixtures
        reverse_matches = [(away, home) for home, away in matches]
        matches.extend(reverse_matches)
    
    return matches


def assign_match_dates(
    matches: List[Tuple[int, int]], 
    start_date: datetime.date, 
    matches_per_week_per_team: int = 1,
    weeks_between_matches: int = 1,
    allowed_weekdays: Optional[List[int]] = None
) -> List[dict]:
    if allowed_weekdays is None:
        allowed_weekdays = [1, 1, 1, 1, 1, 1, 1]
    
    if len(allowed_weekdays) != 7:
        raise ValueError("allowed_weekdays must have exactly 7 elements (one per day)")
    if not any(allowed_weekdays):
        raise ValueError("At least one weekday must be allowed")
    
    scheduled_matches = []
    remaining_matches = matches.copy()
    current_period = 0
    
    while remaining_matches:
        teams_played_this_period = {}
        matches_to_remove = []
        
        for match in remaining_matches:
            team_a_id, team_b_id = match
            
            team_a_count = teams_played_this_period.get(team_a_id, 0)
            team_b_count = teams_played_this_period.get(team_b_id, 0)
            
            if team_a_count < matches_per_week_per_team and team_b_count < matches_per_week_per_team:
                base_date = start_date + timedelta(weeks=current_period * weeks_between_matches)
                
                match_date = _get_next_allowed_weekday(base_date, allowed_weekdays)
                
                scheduled_matches.append({
                    'team_a_id': team_a_id,
                    'team_b_id': team_b_id,
                    'match_date': match_date,
                    'status': 'SCHEDULED'
                })
                
                teams_played_this_period[team_a_id] = team_a_count + 1
                teams_played_this_period[team_b_id] = team_b_count + 1
                
                matches_to_remove.append(match)
        
        for match in matches_to_remove:
            remaining_matches.remove(match)
        
        current_period += 1
        
        if not matches_to_remove and remaining_matches:
            for match in remaining_matches:
                team_a_id, team_b_id = match
                base_date = start_date + timedelta(weeks=current_period * weeks_between_matches)
                match_date = _get_next_allowed_weekday(base_date, allowed_weekdays)
                
                scheduled_matches.append({
                    'team_a_id': team_a_id,
                    'team_b_id': team_b_id,
                    'match_date': match_date,
                    'status': 'SCHEDULED'
                })
            break
    
    return scheduled_matches


def _get_next_allowed_weekday(date: datetime.date, allowed_weekdays: List[int]) -> datetime.date:
    """
    Gets an allowed date from the weekday

    A list goes as follows:
    [Mon, Tue, Wed, Thu, Fri, Sat, Sun]
    and contains 0s and 1s where 1 means allowed.
    """
    current_date = date
    
    for _ in range(7):
        if allowed_weekdays[current_date.weekday()]:
            return current_date
        current_date += timedelta(days=1)
    
    # if reaches here then something is wrong in the code
    return date


def shuffle_fixtures(matches: List[Tuple[int, int]]) -> List[Tuple[int, int]]:
    shuffled = matches.copy()
    random.shuffle(shuffled)
    return shuffled
