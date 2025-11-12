import datetime
import random
from typing import List, Tuple, Optional
from datetime import timedelta


def generate_round_robin(team_ids: List[int], double: bool = False) -> List[Tuple[int, int]]:
    matches = []
    
    # Generate all unique pairings
    for i, team_a in enumerate(team_ids):
        for team_b in team_ids[i+1:]:
            matches.append((team_a, team_b))
    
    # If double round-robin, add reverse fixtures (home/away swap)
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
    """
    Assign dates to matches ensuring each team plays at most matches_per_week_per_team games per period.
    Uses a greedy algorithm to schedule matches period by period.
    
    Args:
        matches: List of (home_team_id, away_team_id) tuples
        start_date: First match date (typically start of season)
        matches_per_week_per_team: Maximum number of matches each team can play per scheduling period
        weeks_between_matches: Interval between match rounds (1=weekly, 2=fortnightly, 4=monthly)
        allowed_weekdays: List of 7 integers (0 or 1) representing which weekdays matches can occur
                         [Mon, Tue, Wed, Thu, Fri, Sat, Sun]
                         Example: [0, 1, 0, 0, 0, 1, 1] = Tuesday, Saturday, Sunday only
                         If None, defaults to all days allowed
    
    Returns:
        List of dictionaries with scheduled match data
    
    Examples:
        Weekly (weeks_between_matches=1):
            Week 1: (1,2), (3,4) - each team plays once
            Week 2: (1,3), (2,4) - each team plays once
        
        With allowed_weekdays=[0, 0, 0, 0, 0, 1, 1]:
            Only Saturday and Sunday matches
            If period start is Monday, match gets pushed to Saturday (+5 days)
    """
    # Default to all days allowed if not specified
    if allowed_weekdays is None:
        allowed_weekdays = [1, 1, 1, 1, 1, 1, 1]
    
    # Validate allowed_weekdays format
    if len(allowed_weekdays) != 7:
        raise ValueError("allowed_weekdays must have exactly 7 elements (one per day)")
    if not any(allowed_weekdays):
        raise ValueError("At least one weekday must be allowed")
    
    scheduled_matches = []
    remaining_matches = matches.copy()
    current_period = 0
    
    while remaining_matches:
        # Track which teams have played this period
        teams_played_this_period = {}
        matches_to_remove = []
        
        for match in remaining_matches:
            team_a_id, team_b_id = match
            
            # Check if either team has reached their limit for this period
            team_a_count = teams_played_this_period.get(team_a_id, 0)
            team_b_count = teams_played_this_period.get(team_b_id, 0)
            
            if team_a_count < matches_per_week_per_team and team_b_count < matches_per_week_per_team:
                # Calculate base match date for current period
                base_date = start_date + timedelta(weeks=current_period * weeks_between_matches)
                
                # Adjust to next allowed weekday if necessary
                match_date = _get_next_allowed_weekday(base_date, allowed_weekdays)
                
                scheduled_matches.append({
                    'team_a_id': team_a_id,
                    'team_b_id': team_b_id,
                    'match_date': match_date,
                    'status': 'SCHEDULED'
                })
                
                # Update team play counts
                teams_played_this_period[team_a_id] = team_a_count + 1
                teams_played_this_period[team_b_id] = team_b_count + 1
                
                # Mark for removal from remaining matches
                matches_to_remove.append(match)
        
        # Remove scheduled matches from remaining
        for match in matches_to_remove:
            remaining_matches.remove(match)
        
        # Move to next period
        current_period += 1
        
        # Safety check to prevent infinite loop
        if not matches_to_remove and remaining_matches:
            # If no matches could be scheduled this period but there are still matches left,
            # it means matches_per_week_per_team is too restrictive
            # Schedule remaining matches anyway to avoid infinite loop
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
    
    # Check up to 7 days ahead to find next allowed weekday
    for _ in range(7):
        # weekday() returns 0=Monday, 6=Sunday
        if allowed_weekdays[current_date.weekday()]:
            return current_date
        current_date += timedelta(days=1)
    
    # Should never reach here if at least one day is allowed
    return date


def shuffle_fixtures(matches: List[Tuple[int, int]]) -> List[Tuple[int, int]]:
    shuffled = matches.copy()
    random.shuffle(shuffled)
    return shuffled
