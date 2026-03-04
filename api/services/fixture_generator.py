import datetime
import random
from typing import List, Tuple, Optional
from datetime import timedelta


def generate_round_robin(team_ids: List[int], double: bool = False, group_by_rounds: bool = False) -> List[Tuple[int, int]]:
    """
    Generate round-robin fixtures using the Berger method (circle/rotation algorithm).
    
    Args:
        team_ids: List of team IDs to schedule
        double: If True, generate double round-robin (home and away)
        group_by_rounds: If True, return matches grouped by Berger rounds
    
    Returns:
        List of match tuples (team_a_id, team_b_id), or list of rounds if group_by_rounds=True
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
    all_rounds = []
    
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
        
        all_rounds.append(round_matches)
        
        # Rotate all teams except the first one
        teams = [teams[0]] + [teams[-1]] + teams[1:-1]
    
    if double:
        # For double round-robin, add reverse fixtures as additional rounds
        reverse_rounds = []
        for round_matches in all_rounds:
            reverse_round = [(away, home) for home, away in round_matches]
            reverse_rounds.append(reverse_round)
        all_rounds.extend(reverse_rounds)
    
    if group_by_rounds:
        return all_rounds
    
    # Flatten rounds into single list for backward compatibility
    matches = []
    for round_matches in all_rounds:
        matches.extend(round_matches)
    return matches


def assign_match_dates(
    matches: List[Tuple[int, int]], 
    start_date: datetime.date, 
    matches_per_week_per_team: int = 1,
    weeks_between_matches: int = 1,
    allowed_weekdays: Optional[List[int]] = None,
    rounds_per_week: Optional[int] = None
) -> List[dict]:
    """
    Assign dates to matches.
    
    Args:
        matches: List of match tuples or list of rounds (list of lists)
        start_date: Starting date for scheduling
        matches_per_week_per_team: Max matches per team per week (ignored if rounds_per_week is set)
        weeks_between_matches: Weeks between match periods
        allowed_weekdays: List of 7 binary values indicating allowed days [Mon-Sun]
        rounds_per_week: Number of complete Berger rounds to schedule per week (overrides matches_per_week_per_team)
    
    Returns:
        List of scheduled match dictionaries
    """
    if allowed_weekdays is None:
        allowed_weekdays = [1, 1, 1, 1, 1, 1, 1]
    
    if len(allowed_weekdays) != 7:
        raise ValueError("allowed_weekdays must have exactly 7 elements (one per day)")
    if not any(allowed_weekdays):
        raise ValueError("At least one weekday must be allowed")
    
    # Check if matches is grouped by rounds (list of lists)
    is_grouped = matches and isinstance(matches[0], list)
    
    if rounds_per_week is not None and rounds_per_week > 0:
        # Schedule by complete Berger rounds
        grouped_matches: List[List[Tuple[int, int]]]
        if is_grouped:
            grouped_matches = matches  # type: ignore
        else:
            # Wrap flat list in a single-round structure
            grouped_matches = [matches]  # type: ignore
        return _assign_dates_by_rounds(
            grouped_matches,
            start_date,
            rounds_per_week,
            weeks_between_matches,
            allowed_weekdays
        )
    
    # Flatten if grouped (backward compatibility)
    if is_grouped:
        flat_matches = []
        for round_matches in matches:
            flat_matches.extend(round_matches)
        matches = flat_matches
    
    # Original scheduling logic (by matches per team per week)
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


def _assign_dates_by_rounds(
    all_rounds: List[List[Tuple[int, int]]],
    start_date: datetime.date,
    rounds_per_week: int,
    weeks_between_matches: int,
    allowed_weekdays: List[int]
) -> List[dict]:
    """
    Schedule matches by complete Berger rounds.
    
    Args:
        all_rounds: List of rounds, each containing a list of matches
        start_date: Starting date for scheduling
        rounds_per_week: Number of complete rounds to schedule per week
        weeks_between_matches: Weeks between match periods
        allowed_weekdays: List of 7 binary values indicating allowed days
    
    Returns:
        List of scheduled match dictionaries
    """
    scheduled_matches = []
    current_week = 0
    
    # Get list of allowed weekday indices (0=Monday, 6=Sunday)
    allowed_day_indices = [i for i, allowed in enumerate(allowed_weekdays) if allowed]
    
    for round_idx, round_matches in enumerate(all_rounds):
        # Determine which week this round belongs to
        week_offset = (round_idx // rounds_per_week) * weeks_between_matches
        
        # Determine which day within the allowed days to use for this round
        round_in_week = round_idx % rounds_per_week
        day_index = round_in_week % len(allowed_day_indices)
        target_weekday = allowed_day_indices[day_index]
        
        # Calculate base date for this week
        base_date = start_date + timedelta(weeks=week_offset)
        
        # Find the target weekday in this week
        match_date = _get_specific_weekday(base_date, target_weekday, allowed_weekdays)
        
        # Schedule all matches in this round on the same date
        for team_a_id, team_b_id in round_matches:
            scheduled_matches.append({
                'team_a_id': team_a_id,
                'team_b_id': team_b_id,
                'match_date': match_date,
                'status': 'SCHEDULED'
            })
    
    return scheduled_matches


def _get_specific_weekday(
    base_date: datetime.date,
    target_weekday: int,
    allowed_weekdays: List[int]
) -> datetime.date:
    """
    Get a specific weekday starting from base_date.
    
    Args:
        base_date: Starting date
        target_weekday: Target weekday (0=Monday, 6=Sunday)
        allowed_weekdays: List of allowed weekdays for validation
    
    Returns:
        Date of the target weekday
    """
    # Calculate days to add to reach target weekday
    current_weekday = base_date.weekday()
    days_ahead = (target_weekday - current_weekday) % 7
    target_date = base_date + timedelta(days=days_ahead)
    
    # Ensure the target date is allowed
    if allowed_weekdays[target_date.weekday()]:
        return target_date
    
    # Fallback: find next allowed weekday
    return _get_next_allowed_weekday(target_date, allowed_weekdays)


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
