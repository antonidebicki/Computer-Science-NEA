#!/usr/bin/env python3
"""
Admin GUI tool for testing team invitations.
Allows administrators to:
1. Login as admin/coach
2. View all players and their invitation codes
3. Create team invitations
4. Manage pending invitations
"""

import tkinter as tk
from tkinter import ttk, messagebox, simpledialog
import requests
import json
from typing import Optional, Dict, List
import threading

BASE_URL = "http://localhost:8000/api"


class AdminInvitationGUI:
    def __init__(self, root):
        self.root = root
        self.root.title("Admin Team Invitation Manager")
        self.root.geometry("900x700")
        self.access_token = None
        self.user_id = None
        self.username = None
        self.teams = []
        self.players = []
        self.pending_invitations = []

        self._setup_login_ui()

    def _setup_login_ui(self):
        """Setup login interface"""
        self.main_frame = ttk.Frame(self.root, padding="10")
        self.main_frame.pack(fill=tk.BOTH, expand=True)

        ttk.Label(self.main_frame, text="Admin Login", font=("Arial", 16, "bold")).pack(
            pady=10
        )

        # Username field
        ttk.Label(self.main_frame, text="Username:").pack(anchor=tk.W)
        self.username_entry = ttk.Entry(self.main_frame, width=30)
        self.username_entry.pack(anchor=tk.W, pady=(0, 10))
        self.username_entry.insert(0, "admin")

        # Password field
        ttk.Label(self.main_frame, text="Password:").pack(anchor=tk.W)
        self.password_entry = ttk.Entry(self.main_frame, width=30, show="*")
        self.password_entry.pack(anchor=tk.W, pady=(0, 20))
        self.password_entry.insert(0, "Admin@123")

        # Login button
        ttk.Button(self.main_frame, text="Login", command=self._handle_login).pack(
            pady=10
        )

    def _handle_login(self):
        """Handle admin login"""
        username = self.username_entry.get()
        password = self.password_entry.get()

        if not username or not password:
            messagebox.showerror("Error", "Please enter username and password")
            return

        # Run login in background thread
        threading.Thread(
            target=self._login_async, args=(username, password), daemon=True
        ).start()

    def _login_async(self, username: str, password: str):
        """Async login"""
        error_msg = None
        try:
            # Test connection first
            try:
                requests.get(f"{BASE_URL}/teams", timeout=2)
            except requests.exceptions.ConnectionError:
                error_msg = "Cannot connect to API server. Make sure it's running on http://localhost:8000"
                raise Exception(error_msg)
            except requests.exceptions.Timeout:
                error_msg = "API server is not responding (timeout)"
                raise Exception(error_msg)
            
            response = requests.post(
                f"{BASE_URL}/login",
                json={"username": username, "password": password},
                timeout=10,
            )
            response.raise_for_status()
            data = response.json()

            self.access_token = data.get("access_token")
            user_info = data.get("user")
            self.user_id = user_info.get("user_id")
            self.username = user_info.get("username")

            if user_info.get("role") not in ["COACH", "ADMIN"]:
                self.root.after(
                    0,
                    lambda: messagebox.showerror(
                        "Error", "Only admins and coaches can use this tool"
                    ),
                )
                return

            self.root.after(0, self._clear_login_ui)
            self.root.after(0, self._setup_main_ui)
        except requests.exceptions.HTTPError as e:
            try:
                error_detail = e.response.json().get("detail", str(e))
            except:
                error_detail = f"HTTP {e.response.status_code}: {e.response.text}"
            error_msg = f"Login failed: {error_detail}"
            self.root.after(
                0, lambda msg=error_msg: messagebox.showerror("Login Error", msg)
            )
        except Exception as e:
            if not error_msg:
                error_msg = str(e)
            self.root.after(
                0, lambda msg=error_msg: messagebox.showerror("Login Error", msg)
            )

    def _clear_login_ui(self):
        """Clear login UI"""
        for widget in self.main_frame.winfo_children():
            widget.destroy()

    def _setup_main_ui(self):
        """Setup main admin interface"""
        self.main_frame.destroy()
        self.main_frame = ttk.Frame(self.root, padding="10")
        self.main_frame.pack(fill=tk.BOTH, expand=True)

        # Header
        header = ttk.Label(
            self.main_frame,
            text=f"Welcome {self.username}! Manage Team Invitations",
            font=("Arial", 14, "bold"),
        )
        header.pack(pady=10)

        # Create notebook (tabs)
        self.notebook = ttk.Notebook(self.main_frame)
        self.notebook.pack(fill=tk.BOTH, expand=True, pady=10)

        # Create invitation tab
        self._setup_create_invitation_tab()

        # Pending invitations tab
        self._setup_pending_invitations_tab()

        # Refresh data
        self._load_data()

    def _setup_create_invitation_tab(self):
        """Setup tab for creating invitations"""
        frame = ttk.Frame(self.notebook, padding="10")
        self.notebook.add(frame, text="Create Invitation")

        ttk.Label(frame, text="Create Team Invitation", font=("Arial", 12, "bold")).pack(
            pady=10
        )

        # Team selection
        ttk.Label(frame, text="Select Team:").pack(anchor=tk.W)
        self.team_var = tk.StringVar()
        self.team_combo = ttk.Combobox(frame, textvariable=self.team_var, state="readonly")
        self.team_combo.pack(anchor=tk.W, pady=(0, 15), fill=tk.X)
        self.team_combo.bind("<<ComboboxSelected>>", lambda e: self._load_players())

        # Player selection / invitation code
        ttk.Label(frame, text="Player's Invitation Code:").pack(anchor=tk.W)
        self.player_code_entry = ttk.Entry(frame, width=40)
        self.player_code_entry.pack(anchor=tk.W, pady=(0, 15), fill=tk.X)

        # Player number
        ttk.Label(frame, text="Player Number (Optional):").pack(anchor=tk.W)
        self.player_number_entry = ttk.Entry(frame, width=10)
        self.player_number_entry.pack(anchor=tk.W, pady=(0, 10))

        # Is libero checkbox
        self.is_libero_var = tk.BooleanVar()
        ttk.Checkbutton(frame, text="Is Libero", variable=self.is_libero_var).pack(
            anchor=tk.W, pady=(0, 20)
        )

        # Create button
        ttk.Button(frame, text="Create Invitation", command=self._create_invitation).pack(
            pady=10
        )

        # Status text
        self.create_status_text = tk.Text(frame, height=8, width=50)
        self.create_status_text.pack(fill=tk.BOTH, expand=True, pady=10)

    def _setup_pending_invitations_tab(self):
        """Setup tab for managing pending invitations"""
        frame = ttk.Frame(self.notebook, padding="10")
        self.notebook.add(frame, text="Pending Invitations")

        ttk.Label(frame, text="Pending Team Invitations", font=("Arial", 12, "bold")).pack(
            pady=10
        )

        # Treeview for invitations
        columns = (
            "ID",
            "Player",
            "Team",
            "Status",
            "Created",
        )
        self.invitations_tree = ttk.Treeview(
            frame, columns=columns, height=15, show="headings"
        )

        for col in columns:
            self.invitations_tree.column(col, width=120)
            self.invitations_tree.heading(col, text=col)

        self.invitations_tree.pack(fill=tk.BOTH, expand=True, pady=10)

        # Buttons frame
        btn_frame = ttk.Frame(frame)
        btn_frame.pack(fill=tk.X, pady=10)

        ttk.Button(btn_frame, text="Accept", command=self._accept_invitation).pack(
            side=tk.LEFT, padx=5
        )
        ttk.Button(btn_frame, text="Reject", command=self._reject_invitation).pack(
            side=tk.LEFT, padx=5
        )
        ttk.Button(btn_frame, text="Delete", command=self._delete_invitation).pack(
            side=tk.LEFT, padx=5
        )
        ttk.Button(btn_frame, text="Refresh", command=self._load_pending_invitations).pack(
            side=tk.LEFT, padx=5
        )

    def _load_data(self):
        """Load teams and players"""
        threading.Thread(target=self._load_teams_async, daemon=True).start()
        threading.Thread(target=self._load_pending_invitations, daemon=True).start()

    def _load_teams_async(self):
        """Load teams asynchronously"""
        try:
            response = requests.get(
                f"{BASE_URL}/teams",
                headers={"Authorization": f"Bearer {self.access_token}"},
                timeout=10,
            )
            response.raise_for_status()
            self.teams = response.json()

            team_names = [f"{t['team_id']}: {t['name']}" for t in self.teams]
            self.root.after(
                0,
                lambda names=team_names: self.team_combo.config(values=names),
            )
        except requests.exceptions.HTTPError as http_err:
            try:
                error_detail = http_err.response.json().get("detail", str(http_err))
            except:
                error_detail = f"HTTP {http_err.response.status_code}"
            self.root.after(
                0, lambda msg=error_detail: messagebox.showerror("Error", f"Failed to load teams: {msg}")
            )
        except Exception as err:
            error_msg = str(err)
            self.root.after(
                0, lambda msg=error_msg: messagebox.showerror("Error", f"Failed to load teams: {msg}")
            )

    def _load_players(self):
        """Load players for selected team"""
        team_selection = self.team_var.get()
        if not team_selection:
            return

        try:
            team_id = int(team_selection.split(":")[0])
            threading.Thread(
                target=self._load_players_async, args=(team_id,), daemon=True
            ).start()
        except Exception as e:
            messagebox.showerror("Error", f"Failed to parse team: {str(e)}")

    def _load_players_async(self, team_id: int):
        """Load players asynchronously"""
        try:
            response = requests.get(
                f"{BASE_URL}/teams/{team_id}/members",
                headers={"Authorization": f"Bearer {self.access_token}"},
                timeout=10,
            )
            response.raise_for_status()
            self.players = response.json()
        except requests.exceptions.HTTPError as http_err:
            try:
                error_detail = http_err.response.json().get("detail", str(http_err))
            except:
                error_detail = f"HTTP {http_err.response.status_code}"
            self.root.after(
                0,
                lambda msg=error_detail: messagebox.showerror("Error", f"Failed to load players: {msg}"),
            )
        except Exception as err:
            error_msg = str(err)
            self.root.after(
                0,
                lambda msg=error_msg: messagebox.showerror("Error", f"Failed to load players: {msg}"),
            )

    def _create_invitation(self):
        """Create a team invitation"""
        team_selection = self.team_var.get()
        invitation_code = self.player_code_entry.get().strip()
        player_number_str = self.player_number_entry.get().strip()

        if not team_selection:
            messagebox.showerror("Error", "Please select a team")
            return

        if not invitation_code or len(invitation_code) != 6 or not invitation_code.isdigit():
            messagebox.showerror("Error", "Invitation code must be 6 digits")
            return

        try:
            team_id = int(team_selection.split(":")[0])
            player_number = int(player_number_str) if player_number_str else None

            threading.Thread(
                target=self._create_invitation_async,
                args=(team_id, invitation_code, player_number),
                daemon=True,
            ).start()
        except Exception as e:
            messagebox.showerror("Error", f"Invalid input: {str(e)}")

    def _create_invitation_async(self, team_id: int, code: str, player_number: Optional[int]):
        """Create invitation asynchronously"""
        try:
            payload = {
                "team_id": team_id,
                "invitation_code": code,
                "player_number": player_number,
                "is_libero": self.is_libero_var.get(),
            }

            response = requests.post(
                f"{BASE_URL}/teams/invitations",
                json=payload,
                headers={"Authorization": f"Bearer {self.access_token}"},
                timeout=10,
            )
            response.raise_for_status()
            data = response.json()

            message = f"✅ Invitation created successfully!\n\nInvitation ID: {data['join_request_id']}\nPlayer: {data['username']}\nTeam: {data['team_name']}\nStatus: {data['status']}"

            self.root.after(0, lambda msg=message: messagebox.showinfo("Success", msg))
            self.root.after(0, self._clear_create_form)
            self.root.after(0, self._load_pending_invitations)
        except requests.exceptions.HTTPError as http_err:
            try:
                error_detail = http_err.response.json().get("detail", str(http_err))
            except:
                error_detail = f"HTTP {http_err.response.status_code}: {http_err.response.text[:200]}"
            self.root.after(
                0, lambda msg=error_detail: messagebox.showerror("Invitation Error", msg)
            )
        except Exception as err:
            error_msg = str(err)
            self.root.after(
                0,
                lambda msg=error_msg: messagebox.showerror("Error", f"Failed to create invitation: {msg}"),
            )

    def _clear_create_form(self):
        """Clear the create invitation form"""
        self.player_code_entry.delete(0, tk.END)
        self.player_number_entry.delete(0, tk.END)
        self.is_libero_var.set(False)

    def _load_pending_invitations(self):
        """Load pending invitations"""
        threading.Thread(target=self._load_pending_invitations_async, daemon=True).start()

    def _load_pending_invitations_async(self):
        """Load pending invitations asynchronously"""
        try:
            response = requests.get(
                f"{BASE_URL}/teams/invitations/sent",
                headers={"Authorization": f"Bearer {self.access_token}"},
                timeout=10,
            )
            response.raise_for_status()
            data = response.json()
            self.pending_invitations = data.get("invitations", [])

            self.root.after(0, self._update_invitations_tree)
        except Exception as e:
            self.root.after(
                0,
                lambda: messagebox.showerror("Error", f"Failed to load invitations: {str(e)}"),
            )

    def _update_invitations_tree(self):
        """Update the treeview with invitations"""
        for item in self.invitations_tree.get_children():
            self.invitations_tree.delete(item)

        for inv in self.pending_invitations:
            self.invitations_tree.insert(
                "",
                tk.END,
                iid=inv["join_request_id"],
                values=(
                    inv["join_request_id"],
                    inv.get("username", "?"),
                    inv.get("team_name", "?"),
                    inv["status"],
                    inv["created_at"][:10],
                ),
            )

    def _accept_invitation(self):
        """Accept a pending invitation"""
        selection = self.invitations_tree.selection()
        if not selection:
            messagebox.showwarning("Warning", "Please select an invitation")
            return

        invite_id = int(selection[0])
        threading.Thread(
            target=self._respond_to_invitation_async,
            args=(invite_id, True),
            daemon=True,
        ).start()

    def _reject_invitation(self):
        """Reject a pending invitation"""
        selection = self.invitations_tree.selection()
        if not selection:
            messagebox.showwarning("Warning", "Please select an invitation")
            return

        invite_id = int(selection[0])
        threading.Thread(
            target=self._respond_to_invitation_async,
            args=(invite_id, False),
            daemon=True,
        ).start()

    def _respond_to_invitation_async(self, invite_id: int, accept: bool):
        """Respond to invitation asynchronously"""
        try:
            payload = {"accept": accept}

            response = requests.post(
                f"{BASE_URL}/teams/invitations/{invite_id}/respond",
                json=payload,
                headers={"Authorization": f"Bearer {self.access_token}"},
                timeout=10,
            )
            response.raise_for_status()

            action = "accepted" if accept else "rejected"
            self.root.after(
                0,
                lambda msg=action: messagebox.showinfo("Success", f"Invitation {msg} successfully!"),
            )
            self.root.after(0, self._load_pending_invitations)
        except requests.exceptions.HTTPError as http_err:
            try:
                error_detail = http_err.response.json().get("detail", str(http_err))
            except:
                error_detail = f"HTTP {http_err.response.status_code}"
            self.root.after(
                0,
                lambda msg=error_detail: messagebox.showerror("Error", f"Failed to respond: {msg}"),
            )
        except Exception as err:
            error_msg = str(err)
            self.root.after(
                0,
                lambda msg=error_msg: messagebox.showerror("Error", f"Failed to respond: {msg}"),
            )

    def _delete_invitation(self):
        """Delete a pending invitation"""
        selection = self.invitations_tree.selection()
        if not selection:
            messagebox.showwarning("Warning", "Please select an invitation")
            return

        if messagebox.askyesno("Confirm", "Delete this invitation?"):
            invite_id = int(selection[0])
            threading.Thread(
                target=self._delete_invitation_async, args=(invite_id,), daemon=True
            ).start()

    def _delete_invitation_async(self, invite_id: int):
        """Delete invitation asynchronously"""
        try:
            response = requests.delete(
                f"{BASE_URL}/teams/invitations/{invite_id}",
                headers={"Authorization": f"Bearer {self.access_token}"},
                timeout=10,
            )
            response.raise_for_status()

            self.root.after(
                0, lambda: messagebox.showinfo("Success", "Invitation deleted!")
            )
            self.root.after(0, self._load_pending_invitations)
        except requests.exceptions.HTTPError as http_err:
            try:
                error_detail = http_err.response.json().get("detail", str(http_err))
            except:
                error_detail = f"HTTP {http_err.response.status_code}"
            self.root.after(
                0, lambda msg=error_detail: messagebox.showerror("Error", f"Failed to delete: {msg}")
            )
        except Exception as err:
            error_msg = str(err)
            self.root.after(
                0, lambda msg=error_msg: messagebox.showerror("Error", f"Failed to delete: {msg}")
            )


if __name__ == "__main__":
    root = tk.Tk()
    app = AdminInvitationGUI(root)
    root.mainloop()
