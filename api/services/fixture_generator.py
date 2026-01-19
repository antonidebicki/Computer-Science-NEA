import datetime
import random
from typing import List, Tuple, Optional
from datetime import timedelta


def generate_round_robin(team_ids: List[int], double: bool = False) -> List[Tuple[int, int]]:
    matches = []
    
    for i, team_a in enumerate(team_ids):
        for team_b in team_ids[i+1:]:
            matches.append((team_a, team_b))
    
    if double:
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
        # weekday() returns 0=Monday, 6=Sunday
        if allowed_weekdays[current_date.weekday()]:
            return current_date
        current_date += timedelta(days=1)
    
    # if reaches here then someone screwed up
    return date


def shuffle_fixtures(matches: List[Tuple[int, int]]) -> List[Tuple[int, int]]:
    shuffled = matches.copy()
    random.shuffle(shuffled)
    return shuffled
