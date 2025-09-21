from flask import Flask, render_template, request, redirect, url_for, session, flash, jsonify
import pymysql
import pymysql.cursors
from werkzeug.security import generate_password_hash, check_password_hash
from datetime import date
import csv
import io , re
from functools import wraps

app = Flask(__name__)
app.secret_key = 'your-secret-key-change-this-in-production'

# ====== DATABASE CREDENTIALS - EDIT THESE ======
DB_HOST = "localhost"
DB_USER = "activeloop_user"
DB_PASS = "yourpassword"
DB_NAME = "activeloop"
# ================================================

def get_db_connection():
    conn = pymysql.connect(
        host=DB_HOST,
        user=DB_USER,
        password=DB_PASS,
        database=DB_NAME,
        cursorclass=pymysql.cursors.DictCursor,
        charset='utf8mb4'
    )
    conn.autocommit(True)
    return conn

def test_password(password):
    # Check for at least one uppercase letter
    has_upper = re.search(r'[A-Z]', password)
    
    # Check for at least one digit
    has_digit = re.search(r'\d', password)
    
    # Check for at least one special character
    has_special = re.search(r'[!@#$%^&*(),.?":{}|<>]', password)
    
    # If any condition is missing, return True (invalid password)
    if not (has_upper and has_digit and has_special):
        return True
    return False

# -------------------- AUTH DECORATORS --------------------
def login_required(f):
    @wraps(f)
    def decorated_function(*args, **kwargs):
        if 'user_id' not in session:
            flash('Please log in to access this page.', 'warning')
            return redirect(url_for('login'))
        return f(*args, **kwargs)
    return decorated_function

def admin_required(f):
    @wraps(f)
    def decorated_function(*args, **kwargs):
        if 'user_id' not in session or session.get('role') != 'admin':
            flash('Admin access required.', 'danger')
            return redirect(url_for('dashboard'))
        return f(*args, **kwargs)
    return decorated_function

def volunteer_required(f):
    @wraps(f)
    def decorated_function(*args, **kwargs):
        if 'user_id' not in session or session.get('role') not in ['volunteer', 'admin']:
            flash('Volunteer access required.', 'danger')
            return redirect(url_for('dashboard'))
        return f(*args, **kwargs)
    return decorated_function

# -------------------- ROUTES --------------------
@app.route('/')
def home():
    conn = get_db_connection()
    cursor = conn.cursor()
    cursor.execute("""
        SELECT e.*, COUNT(r.participant_id) as registered_count
        FROM events e
        LEFT JOIN registrations r ON e.event_id = r.event_id
        WHERE e.event_date >= CURDATE()
        GROUP BY e.event_id
        ORDER BY e.event_date ASC
        LIMIT 6
    """)
    upcoming_events = cursor.fetchall()
    cursor.close()
    conn.close()
    return render_template('home.html', upcoming_events=upcoming_events)

@app.route('/register', methods=['GET', 'POST'])
def register():
    if request.method == 'POST':
        username = request.form.get('username','').strip()
        email = request.form.get('email','').strip()
        password = request.form.get('password','')
        confirm_password = request.form.get('confirm_password','')
        first_name = request.form.get('first_name','').strip()
        last_name = request.form.get('last_name','').strip()
        location = request.form.get('location','').strip()

        if not username or not email or not password:
            flash('Please fill required fields.', 'danger')
            return render_template('register.html')

        if len(password) < 8:
            flash('Password must be at least 8 characters long.', 'danger')
            return render_template('register.html')

        if password != confirm_password:
            flash('Passwords do not match.', 'danger')
            return render_template('register.html')
        if test_password(password):
            flash('Passwords must have one upper case + one special symbol +one number', 'danger')
            return render_template('register.html')
        conn = get_db_connection()
        cursor = conn.cursor()
        cursor.execute("SELECT user_id FROM users WHERE username = %s OR email = %s", (username, email))
        if cursor.fetchone():
            flash('Username or email already exists.', 'danger')
            cursor.close()
            conn.close()
            return render_template('register.html')

        hashed_password = generate_password_hash(password)
        cursor.execute("""
            INSERT INTO users (username, email, password_hash, first_name, last_name, location, role)
            VALUES (%s, %s, %s, %s, %s, %s, 'participant')
        """, (username, email, hashed_password, first_name, last_name, location))
        cursor.close()
        conn.close()
        flash('Registration successful! Please log in.', 'success')
        return redirect(url_for('login'))

    return render_template('register.html')

@app.route('/login', methods=['GET', 'POST'])
def login():
    username=''
    if request.method == 'POST':
        username = request.form.get('username','').strip()
        password = request.form.get('password','')
        conn = get_db_connection()
        cursor = conn.cursor()
        cursor.execute("""
            SELECT user_id, username, password_hash, role, status, first_name, last_name
            FROM users WHERE username = %s
        """, (username,))
        user = cursor.fetchone()
        cursor.close()
        conn.close()

        if user and user.get('status') == 'active' and check_password_hash(user.get('password_hash',''), password):
            session['user_id'] = user['user_id']
            session['username'] = user['username']
            session['role'] = user['role']
            session['full_name'] = f"{user.get('first_name','')} {user.get('last_name','')}".strip()
            flash(f"Welcome back, {user.get('first_name','')}!", 'success')
            return redirect(url_for('dashboard'))
        else:
            flash('Invalid username or password, or account is banned.', 'danger')
    if not username:
        username=""
    return render_template('login.html',username=username)

@app.route('/logout')
def logout():
    session.clear()
    flash('You have been logged out.', 'info')
    return redirect(url_for('home'))

@app.route('/dashboard')
@login_required
def dashboard():
    role = session.get('role')
    if role == 'admin':
        return redirect(url_for('admin_dashboard'))
    elif role == 'volunteer':
        return redirect(url_for('volunteer_dashboard'))
    else:
        return redirect(url_for('participant_dashboard'))

@app.route('/participant-dashboard')
@login_required
def participant_dashboard():
    conn = get_db_connection()
    cursor = conn.cursor()
    user_id = session['user_id']

    cursor.execute("""
        SELECT e.*, r.registration_date
        FROM events e
        JOIN registrations r ON e.event_id = r.event_id
        WHERE r.participant_id = %s AND e.event_date >= CURDATE()
        ORDER BY e.event_date ASC
    """, (user_id,))
    upcoming_events = cursor.fetchall()

    cursor.execute("""
        SELECT e.*, rt.finish_time, rt.start_time, rt.position
        FROM events e
        LEFT JOIN race_times rt ON e.event_id = rt.event_id AND rt.participant_id = %s
        JOIN registrations r ON e.event_id = r.event_id
        WHERE r.participant_id = %s AND e.event_date < CURDATE()
        ORDER BY e.event_date DESC
    """, (user_id, user_id))
    past_events = cursor.fetchall()

    cursor.close()
    conn.close()
    return render_template('participant_dashboard.html', upcoming_events=upcoming_events, past_events=past_events)

@app.route('/volunteer-dashboard')
@volunteer_required
def volunteer_dashboard():
    conn = get_db_connection()
    cursor = conn.cursor()
    user_id = session['user_id']

    # Upcoming assignments
    cursor.execute("""
        SELECT e.event_id, e.title, e.event_date, e.event_time, e.location,
               va.role_name, va.assignment_date
        FROM volunteer_assignments va
        JOIN events e ON va.event_id = e.event_id
        WHERE va.volunteer_id = %s 
          AND (e.event_date IS NULL OR e.event_date >= CURDATE())
        ORDER BY e.event_date ASC
    """, (user_id,))
    upcoming_assignments = cursor.fetchall()

    # Past assignments / history
    cursor.execute("""
        SELECT e.event_id, e.title, e.event_date, e.event_time, e.location,
               va.role_name, va.assignment_date
        FROM volunteer_assignments va
        JOIN events e ON va.event_id = e.event_id
        WHERE va.volunteer_id = %s 
          AND e.event_date < CURDATE()
        ORDER BY e.event_date DESC
    """, (user_id,))
    volunteer_history = cursor.fetchall()

    cursor.close()
    conn.close()

    return render_template(
        'volunteer_dashboard.html',
        upcoming_assignments=upcoming_assignments,
        volunteer_history=volunteer_history
    )

@app.route('/admin-dashboard')
@admin_required
def admin_dashboard():
    conn = get_db_connection()
    cursor = conn.cursor()

    # User stats (active vs banned)
    cursor.execute("""
        SELECT 
            COUNT(*) AS total_users,
            SUM(status='active') AS active_users,
            SUM(status='banned') AS banned_users
        FROM users
    """)
    user_stats = cursor.fetchone()

    total_users = user_stats['total_users']
    active_users = user_stats['active_users']
    banned_users = user_stats['banned_users']

    # Event stats (total, upcoming, past)
    cursor.execute("""
        SELECT 
            COUNT(*) AS total_events,
            SUM(event_date >= CURDATE()) AS upcoming_events,
            SUM(event_date < CURDATE()) AS past_events
        FROM events
    """)
    event_stats = cursor.fetchone()

    total_events = event_stats['total_events']
    upcoming_events = event_stats['upcoming_events']
    past_events = event_stats['past_events']

    # Total registrations
    cursor.execute("SELECT COUNT(*) AS total_registrations FROM registrations")
    total_registrations = cursor.fetchone()['total_registrations']

    # Events by type
    cursor.execute("""
        SELECT event_type, COUNT(*) AS count
        FROM events
        GROUP BY event_type
    """)
    events_by_type = cursor.fetchall()

    # Top 5 events by registrations
    cursor.execute("""
        SELECT e.title, COUNT(r.participant_id) AS registered_count
        FROM events e
        LEFT JOIN registrations r ON e.event_id = r.event_id
        GROUP BY e.event_id
        ORDER BY registered_count DESC
        LIMIT 5
    """)
    top_events = cursor.fetchall()

    # Recent events (latest created)
    cursor.execute("""
        SELECT e.*, COUNT(r.participant_id) as registered_count
        FROM events e
        LEFT JOIN registrations r ON e.event_id = r.event_id
        GROUP BY e.event_id
        ORDER BY e.created_at DESC
        LIMIT 5
    """)
    recent_events = cursor.fetchall()

    cursor.close()
    conn.close()

    return render_template(
        'admin_dashboard.html',
        total_users=total_users,
        active_users=active_users,
        banned_users=banned_users,
        total_events=total_events,
        upcoming_events=upcoming_events,
        past_events=past_events,
        total_registrations=total_registrations,
        events_by_type=events_by_type,
        top_events=top_events,
        recent_events=recent_events
    )

@app.route('/events')
def events():
    conn = get_db_connection()
    cursor = conn.cursor()
    search_type = request.args.get('type', '')
    search_location = request.args.get('location', '')
    search_date = request.args.get('date', '')
    query = """
        SELECT e.*, COUNT(r.participant_id) as registered_count
        FROM events e
        LEFT JOIN registrations r ON e.event_id = r.event_id
        WHERE e.event_date >= CURDATE()
    """
    params = []
    if search_type:
        query += " AND e.event_type LIKE %s"
        params.append(f"%{search_type}%")
    if search_location:
        query += " AND e.location LIKE %s"
        params.append(f"%{search_location}%")
    if search_date:
        query += " AND DATE(e.event_date) = %s"
        params.append(search_date)
    query += " GROUP BY e.event_id ORDER BY e.event_date ASC"
    cursor.execute(query, params)
    events_list = cursor.fetchall()
    cursor.close()
    conn.close()
    return render_template('events.html', events=events_list, search_type=search_type, search_location=search_location, search_date=search_date)
@app.route('/event/<int:event_id>')
def event_detail(event_id):
    conn = get_db_connection()
    cursor = conn.cursor()

    cursor.execute("SELECT * FROM events WHERE event_id = %s", (event_id,))
    event = cursor.fetchone()
    if not event:
        flash('Event not found.', 'danger')
        cursor.close()
        conn.close()
        return redirect(url_for('events'))

    # ✅ Check if event is in the past
    is_past_event = event['event_date'] < date.today()

    cursor.execute("SELECT COUNT(*) as count FROM registrations WHERE event_id = %s", (event_id,))
    registration_count = cursor.fetchone().get('count', 0)

    is_registered = False
    if 'user_id' in session:
        cursor.execute(
            "SELECT registration_id FROM registrations WHERE event_id = %s AND participant_id = %s",
            (event_id, session['user_id'])
        )
        is_registered = cursor.fetchone() is not None

    cursor.execute("""
        SELECT vr.*, COALESCE(assigned.assigned_count, 0) as assigned_count
        FROM volunteer_roles vr
        LEFT JOIN (
            SELECT role_name, COUNT(*) as assigned_count
            FROM volunteer_assignments
            WHERE event_id = %s
            GROUP BY role_name
        ) assigned ON vr.role_name = assigned.role_name
        WHERE vr.event_id = %s
    """, (event_id, event_id))
    volunteer_roles = cursor.fetchall()

    cursor.close()
    conn.close()
    return render_template(
        'event_detail.html',
        event=event,
        registration_count=registration_count,
        is_registered=is_registered,
        volunteer_roles=volunteer_roles,
        is_past_event=is_past_event  # ✅ pass to template
    )

@app.route('/register-event/<int:event_id>', methods=['POST'])
@login_required
def register_event(event_id):
    conn = get_db_connection()
    cursor = conn.cursor()
    user_id = session['user_id']
    cursor.execute("SELECT * FROM events WHERE event_id = %s", (event_id,))
    event = cursor.fetchone()
    if not event:
        flash('Event not found.', 'danger')
        cursor.close()
        conn.close()
        return redirect(url_for('events'))
    cursor.execute("SELECT registration_id FROM registrations WHERE event_id = %s AND participant_id = %s", (event_id, user_id))
    if cursor.fetchone():
        flash('You are already registered for this event.', 'warning')
        cursor.close()
        conn.close()
        return redirect(url_for('event_detail', event_id=event_id))
    cursor.execute("SELECT COUNT(*) as count FROM registrations WHERE event_id = %s", (event_id,))
    current_registrations = cursor.fetchone().get('count', 0)
    if current_registrations >= event.get('max_participants', 0):
        flash('This event is full.', 'danger')
        cursor.close()
        conn.close()
        return redirect(url_for('event_detail', event_id=event_id))
    cursor.execute("INSERT INTO registrations (event_id, participant_id, registration_date) VALUES (%s, %s, NOW())", (event_id, user_id))
    cursor.close()
    conn.close()
    flash('Successfully registered for the event!', 'success')
    return redirect(url_for('event_detail', event_id=event_id))

@app.route('/volunteer-signup/<int:event_id>/<role_name>', methods=['POST'])
@volunteer_required
def volunteer_signup(event_id, role_name):
    conn = get_db_connection()
    cursor = conn.cursor()
    user_id = session['user_id']
    cursor.execute("""
        SELECT vr.*, COALESCE(assigned.assigned_count, 0) as assigned_count
        FROM volunteer_roles vr
        LEFT JOIN (
            SELECT role_name, COUNT(*) as assigned_count
            FROM volunteer_assignments
            WHERE event_id = %s AND role_name = %s
            GROUP BY role_name
        ) assigned ON vr.role_name = assigned.role_name
        WHERE vr.event_id = %s AND vr.role_name = %s
    """, (event_id, role_name, event_id, role_name))
    role = cursor.fetchone()
    if not role or role.get('assigned_count', 0) >= role.get('volunteers_needed', 0):
        flash('This volunteer role is full.', 'danger')
        cursor.close()
        conn.close()
        return redirect(url_for('event_detail', event_id=event_id))
    cursor.execute("SELECT assignment_id FROM volunteer_assignments WHERE event_id = %s AND volunteer_id = %s AND role_name = %s", (event_id, user_id, role_name))
    if cursor.fetchone():
        flash('You are already assigned to this role.', 'warning')
        cursor.close()
        conn.close()
        return redirect(url_for('event_detail', event_id=event_id))
    cursor.execute("INSERT INTO volunteer_assignments (event_id, volunteer_id, role_name, assignment_date) VALUES (%s, %s, %s, NOW())", (event_id, user_id, role_name))
    cursor.close()
    conn.close()
    flash(f"Successfully signed up for {role_name} role!", 'success')
    return redirect(url_for('event_detail', event_id=event_id))

@app.route('/create-event', methods=['GET', 'POST'])
@admin_required
def create_event():
    if request.method == 'POST':
        title = request.form.get('title','').strip()
        event_date = request.form.get('event_date','')
        event_time = request.form.get('event_time','')
        location = request.form.get('location','').strip()
        event_type = request.form.get('event_type','').strip()
        description = request.form.get('description','').strip()
        max_participants = int(request.form.get('max_participants', 0) or 0)

        conn = get_db_connection()
        cursor = conn.cursor()
        cursor.execute("""
            INSERT INTO events (title, event_date, event_time, location, event_type, description, max_participants, created_by)
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
        """, (title, event_date, event_time, location, event_type, description, max_participants, session['user_id']))
        event_id = cursor.lastrowid

        volunteer_roles_data = [
            ('Event Coordinator', 1), ('Registration Assistant', 2), ('Course Marshal', 3),
            ('Timekeeper', 1), ('Results Recorder', 1), ('Route Setup Crew', 2),
            ('Pack-down Crew', 2), ('Tail Walker/Cyclist', 1), ('Photographer/Social Media Volunteer', 1),
            ('First Timers Host', 1), ('Safety & First Aid Support', 1), ('Volunteer Coordinator', 1)
        ]
        if event_type.lower() == 'cycling':
            volunteer_roles_data.append(('Bike Marshal', 2))

        for role_name, volunteers_needed in volunteer_roles_data:
            cursor.execute("INSERT INTO volunteer_roles (event_id, role_name, volunteers_needed) VALUES (%s, %s, %s)", (event_id, role_name, volunteers_needed))

        cursor.close()
        conn.close()
        flash('Event created successfully!', 'success')
        return redirect(url_for('admin_dashboard'))

    return render_template('create_event.html')

@app.route('/upload-results/<int:event_id>', methods=['GET', 'POST'])
@volunteer_required
def upload_results(event_id):
    if request.method == 'POST':
        if 'csv_file' not in request.files:
            flash('No file selected.', 'danger')
            return redirect(request.url)
        file = request.files['csv_file']
        if file.filename == '':
            flash('No file selected.', 'danger')
            return redirect(request.url)
        if not file.filename.lower().endswith('.csv'):
            flash('Please upload a CSV file.', 'danger')
            return redirect(request.url)
        try:
            stream = io.StringIO(file.stream.read().decode("utf8"), newline=None)
            csv_reader = csv.DictReader(stream)
            conn = get_db_connection()
            cursor = conn.cursor()
            results_processed = 0
            errors = []
            for i, row in enumerate(csv_reader, start=2):  # start=2 assuming header is line 1
                participant_id = row.get('participant_id')
                start_time = row.get('start_time')
                finish_time = row.get('finish_time')
                if not participant_id or not start_time or not finish_time:
                    errors.append((i, 'Missing participant_id/start_time/finish_time'))
                    continue
                # Basic validation could be improved (timestamp parsing)
                try:
                    cursor.execute("""
                        INSERT INTO race_times (event_id, participant_id, start_time, finish_time)
                        VALUES (%s, %s, %s, %s)
                        ON DUPLICATE KEY UPDATE start_time = VALUES(start_time), finish_time = VALUES(finish_time)
                    """, (event_id, participant_id, start_time, finish_time))
                    results_processed += 1
                except Exception as e:
                    errors.append((i, str(e)))
            # Compute positions in Python to avoid multi-statement issues
            cursor.execute("SELECT participant_id, finish_time FROM race_times WHERE event_id = %s AND finish_time IS NOT NULL ORDER BY finish_time ASC", (event_id,))
            rows = cursor.fetchall()
            position = 1
            last_time = None
            same_rank_count = 0
            for r in rows:
                pid = r.get('participant_id')
                ft = r.get('finish_time')
                if last_time is None:
                    cursor.execute("UPDATE race_times SET position = %s WHERE event_id = %s AND participant_id = %s", (position, event_id, pid))
                    last_time = ft
                    same_rank_count = 1
                else:
                    if ft == last_time:
                        # same position
                        cursor.execute("UPDATE race_times SET position = %s WHERE event_id = %s AND participant_id = %s", (position, event_id, pid))
                        same_rank_count += 1
                    else:
                        position = position + same_rank_count
                        same_rank_count = 1
                        last_time = ft
                        cursor.execute("UPDATE race_times SET position = %s WHERE event_id = %s AND participant_id = %s", (position, event_id, pid))
            cursor.close()
            conn.close()
            msg = f'Successfully processed {results_processed} results.'
            if errors:
                msg += f' {len(errors)} rows failed. See server logs for details.'
                # optionally: store errors somewhere or display
            flash(msg, 'success')
        except Exception as e:
            flash(f'Error processing CSV file: {str(e)}', 'danger')
        return redirect(url_for('event_detail', event_id=event_id))
    return render_template('upload_results.html', event_id=event_id)

@app.route('/results/<int:event_id>')
def event_results(event_id):
    conn = get_db_connection()
    cursor = conn.cursor()
    cursor.execute("SELECT * FROM events WHERE event_id = %s", (event_id,))
    event = cursor.fetchone()
    if not event:
        flash('Event not found.', 'danger')
        cursor.close()
        conn.close()
        return redirect(url_for('events'))
    cursor.execute("""
        SELECT rt.*, u.first_name, u.last_name,
               TIME_FORMAT(TIMEDIFF(rt.finish_time, rt.start_time), '%H:%i:%s') as race_time
        FROM race_times rt
        JOIN users u ON rt.participant_id = u.user_id
        WHERE rt.event_id = %s
        ORDER BY rt.position ASC
    """, (event_id,))
    results = cursor.fetchall()
    cursor.close()
    conn.close()
    return render_template('event_results.html', event=event, results=results)

# -------------------- ADMIN USER MANAGEMENT --------------------
@app.route('/admin/users')
@admin_required
def admin_users():
    """View all users for admin management"""
    conn = get_db_connection()
    cursor = conn.cursor()
    
    search = request.args.get('search', '')
    role_filter = request.args.get('role', '')
    status_filter = request.args.get('status', '')
    
    query = "SELECT user_id, username, email, first_name, last_name, role, status, created_at FROM users WHERE 1=1"
    params = []
    
    if search:
        query += " AND (username LIKE %s OR email LIKE %s OR first_name LIKE %s OR last_name LIKE %s)"
        search_param = f"%{search}%"
        params.extend([search_param, search_param, search_param, search_param])
    
    if role_filter:
        query += " AND role = %s"
        params.append(role_filter)
    
    if status_filter:
        query += " AND status = %s"
        params.append(status_filter)
    
    query += " ORDER BY created_at DESC"
    
    cursor.execute(query, params)
    users = cursor.fetchall()
    
    cursor.close()
    conn.close()
    
    return render_template('admin_users.html', users=users, search=search, 
                         role_filter=role_filter, status_filter=status_filter)

@app.route('/admin/user/<int:user_id>')
@admin_required
def admin_user_detail(user_id):
    """View detailed user profile"""
    conn = get_db_connection()
    cursor = conn.cursor()
    
    # Get user details
    cursor.execute("SELECT * FROM users WHERE user_id = %s", (user_id,))
    user = cursor.fetchone()
    
    if not user:
        flash('User not found.', 'danger')
        return redirect(url_for('admin_users'))
    
    # Get user's registrations
    cursor.execute("""
        SELECT e.title, e.event_date, r.registration_date
        FROM registrations r
        JOIN events e ON r.event_id = e.event_id
        WHERE r.participant_id = %s
        ORDER BY r.registration_date DESC
        LIMIT 10
    """, (user_id,))
    registrations = cursor.fetchall()
    
    # Get user's volunteer assignments
    cursor.execute("""
        SELECT e.title, e.event_date, va.role_name, va.assignment_date
        FROM volunteer_assignments va
        JOIN events e ON va.event_id = e.event_id
        WHERE va.volunteer_id = %s
        ORDER BY va.assignment_date DESC
        LIMIT 10
    """, (user_id,))
    volunteer_history = cursor.fetchall()
    
    cursor.close()
    conn.close()
    
    return render_template('admin_user_detail.html', user=user, 
                         registrations=registrations, volunteer_history=volunteer_history)

@app.route('/admin/user/<int:user_id>/toggle-status', methods=['POST'])
@admin_required
def admin_toggle_user_status(user_id):
    """Toggle user status between active and banned"""
    conn = get_db_connection()
    cursor = conn.cursor()
    
    # Don't allow admin to ban themselves
    if user_id == session['user_id']:
        flash('You cannot change your own status.', 'danger')
        return redirect(url_for('admin_user_detail', user_id=user_id))
    
    cursor.execute("SELECT status FROM users WHERE user_id = %s", (user_id,))
    user = cursor.fetchone()
    
    if not user:
        flash('User not found.', 'danger')
        return redirect(url_for('admin_users'))
    
    new_status = 'banned' if user['status'] == 'active' else 'active'
    cursor.execute("UPDATE users SET status = %s WHERE user_id = %s", (new_status, user_id))
    
    cursor.close()
    conn.close()
    
    flash(f'User status changed to {new_status}.', 'success')
    return redirect(url_for('admin_user_detail', user_id=user_id))

@app.route('/admin/user/<int:user_id>/change-role', methods=['POST'])
@admin_required
def admin_change_user_role(user_id):
    """Change user role"""
    conn = get_db_connection()
    cursor = conn.cursor()
    
    new_role = request.form.get('new_role')
    valid_roles = ['participant', 'volunteer', 'admin']
    
    if new_role not in valid_roles:
        flash('Invalid role selected.', 'danger')
        return redirect(url_for('admin_user_detail', user_id=user_id))
    
    # Don't allow admin to change their own role
    if user_id == session['user_id']:
        flash('You cannot change your own role.', 'danger')
        return redirect(url_for('admin_user_detail', user_id=user_id))
    
    cursor.execute("UPDATE users SET role = %s WHERE user_id = %s", (new_role, user_id))
    
    cursor.close()
    conn.close()
    
    flash(f'User role changed to {new_role}.', 'success')
    return redirect(url_for('admin_user_detail', user_id=user_id))

@app.route('/admin/events')
@admin_required
def admin_events():
    """Admin view of all events"""
    conn = get_db_connection()
    cursor = conn.cursor()
    
    cursor.execute("""
        SELECT e.*, 
               COUNT(DISTINCT r.participant_id) as registered_count,
               COUNT(DISTINCT va.volunteer_id) as volunteer_count,
               CONCAT(u.first_name, ' ', u.last_name) as created_by_name
        FROM events e
        LEFT JOIN registrations r ON e.event_id = r.event_id
        LEFT JOIN volunteer_assignments va ON e.event_id = va.event_id
        LEFT JOIN users u ON e.created_by = u.user_id
        GROUP BY e.event_id
        ORDER BY e.event_date DESC
    """)
    events = cursor.fetchall()
    
    cursor.close()
    conn.close()
    
    return render_template('admin_events.html', events=events)

@app.route('/admin/event/<int:event_id>/edit', methods=['GET', 'POST'])
@admin_required
def admin_edit_event(event_id):
    """Edit an existing event"""
    conn = get_db_connection()
    cursor = conn.cursor()
    
    if request.method == 'POST':
        title = request.form.get('title', '').strip()
        event_date = request.form.get('event_date', '')
        event_time = request.form.get('event_time', '')
        location = request.form.get('location', '').strip()
        event_type = request.form.get('event_type', '').strip()
        description = request.form.get('description', '').strip()
        max_participants = int(request.form.get('max_participants', 0) or 0)
        
        cursor.execute("""
            UPDATE events 
            SET title = %s, event_date = %s, event_time = %s, location = %s, 
                event_type = %s, description = %s, max_participants = %s
            WHERE event_id = %s
        """, (title, event_date, event_time, location, event_type, description, max_participants, event_id))
        
        flash('Event updated successfully!', 'success')
        return redirect(url_for('admin_events'))
    
    # GET request - show edit form
    cursor.execute("SELECT * FROM events WHERE event_id = %s", (event_id,))
    event = cursor.fetchone()
    
    if not event:
        flash('Event not found.', 'danger')
        return redirect(url_for('admin_events'))
    
    cursor.close()
    conn.close()
    
    return render_template('admin_edit_event.html', event=event)

@app.route('/admin/event/<int:event_id>/cancel', methods=['POST'])
@admin_required
def admin_cancel_event(event_id):
    """Cancel an event"""
    conn = get_db_connection()
    cursor = conn.cursor()
    
    cursor.execute("UPDATE events SET status = 'cancelled' WHERE event_id = %s", (event_id,))
    
    cursor.close()
    conn.close()
    
    flash('Event cancelled successfully!', 'success')
    return redirect(url_for('admin_events'))

@app.route('/profile', methods=['GET', 'POST'])
@login_required
def profile():
    """User profile management"""
    conn = get_db_connection()
    cursor = conn.cursor()
    user_id = session['user_id']

    if request.method == 'POST':
        action = request.form.get('action')

        if action == 'update_profile':
            first_name = request.form['first_name'].strip()
            last_name = request.form['last_name'].strip()
            email = request.form['email'].strip()
            location = request.form['location'].strip()

            # Email format check
            email_regex = r'^[\w\.-]+@[\w\.-]+\.\w+'
            if not re.match(email_regex, email):
                flash('Invalid email format.', 'danger')
            else:
                try:
                    # Check if another user already has this email
                    cursor.execute(
                        "SELECT user_id FROM users WHERE email = %s AND user_id != %s",
                        (email, user_id)
                    )
                    existing_user = cursor.fetchone()
                    if existing_user:
                        flash('Email already exists. Please use a different email.', 'danger')
                    else:
                        cursor.execute("""
                            UPDATE users 
                            SET first_name = %s, last_name = %s, email = %s, location = %s
                            WHERE user_id = %s
                        """, (first_name, last_name, email, location, user_id))

                        session['full_name'] = f"{first_name} {last_name}"
                        flash('Profile updated successfully!', 'success')

                except Exception:
                    flash('Email already exists. Please use a different email.', 'danger')

        elif action == 'change_password':
            current_password = request.form['current_password']
            new_password = request.form['new_password']
            confirm_password = request.form['confirm_password']
            
            cursor.execute("SELECT password_hash FROM users WHERE user_id = %s", (user_id,))
            user = cursor.fetchone()

            if not check_password_hash(user['password_hash'], current_password):
                flash('Current password is incorrect.', 'danger')
            elif new_password != confirm_password:
                flash('New passwords do not match.', 'danger')
            elif current_password == new_password:
                flash('New password must be different from current password.', 'danger')
            elif len(new_password) < 8:
                flash('New password must be at least 8 characters long.', 'danger')
            elif test_password(new_password):
                flash('Passwords must have one upper case + one special symbol + one number', 'danger')
            else:
                new_password_hash = generate_password_hash(new_password)
                cursor.execute(
                    "UPDATE users SET password_hash = %s WHERE user_id = %s",
                    (new_password_hash, user_id)
                )
                flash('Password changed successfully!', 'success')

    # Get user profile for display
    cursor.execute("SELECT * FROM users WHERE user_id = %s", (user_id,))
    user = cursor.fetchone()

    cursor.close()
    conn.close()
    return render_template('profile.html', user=user)

if __name__ == '__main__':
    app.run(debug=True)